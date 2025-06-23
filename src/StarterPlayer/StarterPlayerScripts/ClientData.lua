local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local BuffConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BuffConfig"))

local ClientData = {}
ClientData.Gold = 0  -- 玩家金币
ClientData.InventoryItems = {}   -- 玩家背包物品
ClientData.IsAdmin = false  -- 是否为管理员
ClientData.IsLandOwners = {}  -- 所有土地的拥有者
ClientData.ActiveBuffs = {}  -- 当前激活的BUFF
ClientData.IsBoatAssembling = false -- 是否正在组装船

-- 更新buff剩余时间函数
local function updateRemainingTimes()
    local currentTime = tick()
    
    for buffKey, buffData in pairs(ClientData.ActiveBuffs) do
        local elapsed = currentTime - buffData.startTime
        local newRemainingTime = math.max(0, buffData.remainingTime - elapsed)
        
        if newRemainingTime <= 0 then
            -- BUFF过期，移除
            ClientData.ActiveBuffs[buffKey] = nil
        else
            -- 重置开始时间以避免累积误差
            buffData.startTime = currentTime
            buffData.remainingTime = newRemainingTime
        end
    end
end

Knit:OnStart():andThen(function()
    Players.LocalPlayer:GetAttributeChangedSignal('Gold'):Connect(function()
        ClientData.Gold = tonumber(Players.LocalPlayer:GetAttribute('Gold'))
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end)
    ClientData.Gold = tonumber(Players.LocalPlayer:GetAttribute('Gold')) or 0
    if ClientData.Gold ~= 0 then
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end

    local PlayerAttributeService = Knit.GetService('PlayerAttributeService')
    PlayerAttributeService:GetLoginData():andThen(function(data)
        ClientData.Gold = data.Gold
        Knit.GetController('UIController').UpdateGoldUI:Fire()
        
        ClientData.InventoryItems = {}
        for _, itemData in pairs(data.PlayerInventory) do
            table.insert(ClientData.InventoryItems, itemData)
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()

        ClientData.IsAdmin = data.isAdmin
        if ClientData.IsAdmin then
            Knit.GetController('UIController').IsAdmin:Fire()
        end

        ClientData.IsLandOwners = data.IsLandOwners
        Knit.GetController('UIController').IsLandOwner:Fire()
    end)

    local SystemService = Knit.GetService('SystemService')
    SystemService.IsLandOwnerChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = {userId = data.userId, playerName = data.playerName}
        Knit.GetController('UIController').IsLandOwnerChanged:Fire(data.landName, data.playerName)
    end)
    SystemService.IsLandInfoChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = data.isLandData
    end)

    local InventoryService = Knit.GetService('InventoryService')
    InventoryService.AddItem:Connect(function(itemData)
        local isExist = false
        for _, item in ipairs(ClientData.InventoryItems) do
            if item.itemName == itemData.itemName and item.modelName == itemData.modelName then
                item.num = itemData.num
                isExist = true
                break
            end
        end
    
        if not isExist then
            table.insert(ClientData.InventoryItems, itemData)
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10011), itemData.itemName))
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
    InventoryService.RemoveItem:Connect(function(modelName, itemName)
        local isExist = false
        for _, item in ipairs(ClientData.InventoryItems) do
            if item.itemName == itemName and item.modelName == modelName then
                if item.num > 1 then
                    item.num = item.num - 1
                else
                    table.remove(ClientData.InventoryItems, item)
                end
                isExist = true
                break
            end
        end
    
        if isExist then
            Knit.GetController('UIController').UpdateInventoryUI:Fire()
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10012), itemName))
    end)
    InventoryService.InitInventory:Connect(function(inventoryData)
        ClientData.InventoryItems = {}
        for _, itemData in pairs(inventoryData) do
            table.insert(ClientData.InventoryItems, itemData)
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)

    Knit.GetService('BoatAssemblingService').UpdateInventory:Connect(function(modelName)
        for _, item in pairs(ClientData.InventoryItems) do
            if item.modelName == modelName then
                item.isUsed = 1
            end
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)

    -- BUFF系统事件监听
    local BuffService = Knit.GetService('BuffService')
    BuffService.BuffAdded:Connect(function(buffId, duration)
        local config = BuffConfig.GetBuffConfig(buffId)
        ClientData.ActiveBuffs[buffId] = {
            buffId = buffId,
            remainingTime = duration,
            startTime = tick(),
            config = config
        }

        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10011), config.displayName))
        Knit.GetController('UIController').BuffChanged:Fire()
    end)
    BuffService.BuffRemoved:Connect(function(buffId)
        ClientData.ActiveBuffs[buffId] = nil
        Knit.GetController('UIController').BuffChanged:Fire()
    end)
    -- 获取初始BUFF状态
    BuffService:GetPlayerBuffs(Players.LocalPlayer):andThen(function(initialBuffs)
        if initialBuffs and type(initialBuffs) == "table" then
            for buffType, buffs in pairs(initialBuffs) do
                if type(buffs) == "table" then
                    for buffId, buffData in pairs(buffs) do
                        if buffData and buffData.remainingTime then
                            local config = BuffConfig.GetBuffConfig(buffId)
                            ClientData.ActiveBuffs[buffId] = {
                                buffId = buffId,
                                remainingTime = buffData.remainingTime,
                                startTime = tick(),
                                config = config
                            }
                        end
                    end
                end
            end
        end
    end):catch(warn)

    -- 监听宝箱奖励事件
    local chestService = Knit.GetService('ChestService')
    local RewardFlyEffect = require(game:GetService('StarterGui'):WaitForChild('RewardFlyEffect'))
    
    chestService.RewardReceived:Connect(function(rewardType, rewardData)
        -- 播放飞行特效
        if rewardData and rewardData.chestPosition then
            RewardFlyEffect.PlayEffect(rewardType, rewardData.chestPosition)
        end
        
        if rewardType == "Gold" then
            Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10011), rewardData.amount) .. LanguageConfig.Get(10007))
            return
        elseif rewardType == "" then
            Knit.GetController('UIController').ShowTip:Fire(10051)
        end
    end)
    
    -- 启动时间更新循环
    game:GetService("RunService").Heartbeat:Connect(function()
        updateRemainingTimes()
    end)
end):catch(warn)

return ClientData