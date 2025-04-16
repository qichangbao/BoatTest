print('LootService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))

local LootService = Knit.CreateService({
    Name = 'LootService',
    Client = {
    },
})

-- 配件生成配置
local BOAT_PARTS_FOLDER_NAME = '船'
local REWARD_COUNT = {
    [5] = 1,
    [15] = 2,
    [50] = 3,
    [100] = 4
}

local function getRandomParts(player, price)
    local boatTemplate = ServerStorage:FindFirstChild(BOAT_PARTS_FOLDER_NAME)
    if not boatTemplate then return {} end

    local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]
    local rewardCount = REWARD_COUNT[price] or 1
    local availableParts = {}
    local InventoryService = Knit.GetService("InventoryService")
    
    -- 收集所有非主要部件配置
    local partKeys = {}
    for name, data in pairs(curBoatConfig) do
        if not data.isPrimaryPart then
            table.insert(partKeys, name)
        end
    end
    
    -- 添加主要部件（如果首次获取）
    local primaryPartName = ''
    for name, data in pairs(curBoatConfig) do
        if data.isPrimaryPart then
            primaryPartName = name
            break
        end
    end
    
    local isFirstLoot = InventoryService:Inventory(player, 'CheckExists', primaryPartName)
    if not isFirstLoot and primaryPartName ~= '' then
        table.insert(availableParts, primaryPartName)
        rewardCount = math.max(rewardCount - 1, 0)
    end
    
    -- 随机选择其他部件
    for _ = 1, rewardCount do
        if not curBoatConfig or #partKeys == 0 then break end
        
        local randomIndex = math.random(1, #partKeys)
        local partName = partKeys[randomIndex]
        table.insert(availableParts, partName)
        table.remove(partKeys, randomIndex)
    end

    return availableParts
end

function LootService.Client:Loot(player, price)
    -- 获取玩家数据组件
    local gold = player.character:GetAttribute('Gold')
    if not gold or gold < price then
        return "黄金不够"
    end
    
    -- 扣除黄金
    gold -= price
    player.character:SetAttribute('Gold', gold)
    Knit.GetService("PlayerDataService").Client.GoodChanged:Fire(player, gold)
    
    -- 获取随机配件
    local parts = getRandomParts(player, price)
    local InventoryService = Knit.GetService("InventoryService")
    for _, name in ipairs(parts) do
        -- 调用背包管理器添加物品
        InventoryService:Inventory(player, 'AddItem', name, BOAT_PARTS_FOLDER_NAME)
    end

    return "黄金扣除成功"
end

function LootService:KnitInit()
    print('LootService initialized')
end

function LootService:KnitStart()
    print('LootService started')
end

return LootService