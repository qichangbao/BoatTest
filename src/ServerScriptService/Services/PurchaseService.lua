-- 充值购买服务
-- 专门处理船只购买功能

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local PurchaseConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("PurchaseConfig"))

local PurchaseService = Knit.CreateService({
    Name = 'PurchaseService',
    Client = {
        PurchaseProduct = Knit.CreateSignal(),
        PurchaseCompleted = Knit.CreateSignal(),
        PurchaseFailed = Knit.CreateSignal(),
    },
})

-- 存储待处理的购买请求
local PendingPurchases = {}

-- 处理开发者产品购买回调
-- @param receiptInfo table 购买收据信息
-- @return Enum.ProductPurchaseDecision 购买决定
local function processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    if receiptInfo.ProductId == 3322298452 then
        -- 购买成功
        Knit.GetService("PlayerAttributeService"):PurchaseRevive(player)
        Knit.GetService("SystemService"):SendTip(10094)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    -- 查找对应的船只商品配置
    local productConfig = nil
    for productId, developerProductId in pairs(PurchaseConfig.DeveloperProductIds) do
        if developerProductId == receiptInfo.ProductId then
            productConfig = PurchaseConfig:GetProduct(productId)
            break
        end
    end
    
    if not productConfig then
        warn("未找到船只商品配置，ProductId: " .. receiptInfo.ProductId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    -- 发放船只
    local success = PurchaseService:GrantBoat(player, productConfig)
    
    if success then
        print(player.Name .. " 成功购买船只: " .. productConfig.name)
        PurchaseService.Client.PurchaseCompleted:Fire(player, productConfig)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        warn(player.Name .. " 船只购买失败: " .. productConfig.name)
        PurchaseService.Client.PurchaseFailed:Fire(player, productConfig, "发放船只失败")
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

-- 购买复活
function PurchaseService:BuyRevive(player)
    local developerProductId = 3322298452
    -- 发起购买
    local success, errorMessage = pcall(function()
        game.MarketplaceService:PromptProductPurchase(player, developerProductId)
    end)

    if not success then
        -- 购买失败
        Knit.GetService("PlayerAttributeService"):DeclineRevive(player)
        Knit.GetService("SystemService"):SendTip(10095, errorMessage)
    end
end

-- 发放船只到玩家背包
-- @param player Player 玩家对象
-- @param productConfig table 船只商品配置
-- @return boolean 是否成功
function PurchaseService:GrantBoat(player, productConfig)
    local InventoryService = Knit.GetService('InventoryService')
    
    if productConfig.productType == PurchaseConfig.ProductType.BOAT then
        -- 创建船只物品数据
        local boatItem = {
            id = productConfig.boatModel,
            name = productConfig.name,
            type = "Boat",
            stats = productConfig.stats,
            description = productConfig.description,
            icon = productConfig.icon
        }
        
        -- 添加到玩家背包
        local success = InventoryService:AddItem(player, boatItem)
        if success then
            print("成功将船只 " .. productConfig.name .. " 添加到 " .. player.Name .. " 的背包")
        else
            warn("添加船只到背包失败: " .. productConfig.name)
        end
        return success
    end
    
    return false
end

-- 客户端接口：购买船只
-- @param player Player 玩家对象
-- @param productId string 船只商品ID
-- @return boolean 是否成功发起购买
function PurchaseService.Client:PurchaseBoat(player, productId)
    local productConfig = PurchaseConfig:GetProduct(productId)
    if not productConfig then
        warn("商品不存在: " .. productId)
        PurchaseService.Client.PurchaseFailed:Fire(player, nil, "商品不存在")
        return false
    end
    
    local developerProductId = PurchaseConfig:GetDeveloperProductId(productId)
    if not developerProductId or developerProductId == 0 then
        warn("未配置有效的开发者产品ID: " .. productId .. ", 当前ID: " .. tostring(developerProductId))
        PurchaseService.Client.PurchaseFailed:Fire(player, productConfig, "商品配置错误：请先在Roblox开发者控制台创建开发者产品")
        return false
    end
    
    -- 存储待处理的购买请求
    PendingPurchases[player.UserId] = {
        productId = productId,
        productConfig = productConfig,
        timestamp = tick()
    }
    
    -- 发起购买
    local success, errorMessage = pcall(function()
        MarketplaceService:PromptProductPurchase(player, developerProductId)
    end)
    
    if not success then
        warn("发起船只购买失败: " .. errorMessage)
        PendingPurchases[player.UserId] = nil
        PurchaseService.Client.PurchaseFailed:Fire(player, productConfig, "发起购买失败")
        return false
    end
    
    print(player.Name .. " 发起船只购买: " .. productConfig.name)
    return true
end

-- 清理过期的待处理购买请求
-- @param maxAge number 最大存活时间（秒）
function PurchaseService:CleanupPendingPurchases(maxAge)
    maxAge = maxAge or 300 -- 默认5分钟
    local currentTime = tick()
    
    for userId, purchaseData in pairs(PendingPurchases) do
        if currentTime - purchaseData.timestamp > maxAge then
            PendingPurchases[userId] = nil
        end
    end
end

-- 验证开发者产品ID配置
-- @return boolean 是否所有产品ID都已正确配置
function PurchaseService:ValidateDeveloperProductIds()
    local hasInvalidIds = false
    local invalidProducts = {}
    
    for productId, developerProductId in pairs(PurchaseConfig.DeveloperProductIds) do
        if not developerProductId or developerProductId == 0 then
            hasInvalidIds = true
            table.insert(invalidProducts, productId)
        end
    end
    
    if hasInvalidIds then
        warn("⚠️  检测到未配置的开发者产品ID:")
        for _, productId in ipairs(invalidProducts) do
            local productConfig = PurchaseConfig:GetProduct(productId)
            if productConfig then
                warn("   - " .. productId .. " (" .. productConfig.name .. ")")
            end
        end
        warn("📝 请按以下步骤创建开发者产品:")
        warn("   1. 访问 https://create.roblox.com/dashboard/creations")
        warn("   2. 选择您的游戏 -> 货币化 -> 开发者产品")
        warn("   3. 创建新的开发者产品，设置名称、描述和价格")
        warn("   4. 复制产品ID并替换PurchaseConfig.lua中的对应ID")
        warn("❌ 在配置正确的开发者产品ID之前，购买功能将无法正常工作")
        return false
    else
        print("✅ 所有开发者产品ID配置正确")
        return true
    end
end

function PurchaseService:KnitInit()
    -- 设置购买处理回调
    MarketplaceService.ProcessReceipt = processReceipt
    
    -- 验证开发者产品ID配置
    self:ValidateDeveloperProductIds()
    
    -- 定期清理过期的待处理购买请求
    task.spawn(function()
        while true do
            wait(60) -- 每分钟清理一次
            self:CleanupPendingPurchases()
        end
    end)
end

function PurchaseService:KnitStart()
    print("PurchaseService 已启动 - 船只购买功能")
end

return PurchaseService