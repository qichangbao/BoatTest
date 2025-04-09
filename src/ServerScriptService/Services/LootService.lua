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
    local boatFolder = ServerStorage:FindFirstChild(BOAT_PARTS_FOLDER_NAME)
    if not boatFolder then return {} end

    local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]
    local rewardCount = REWARD_COUNT[price] or 1
    local index = 1
    local availableParts = {}
    local InventoryService = Knit.GetService("InventoryService")
    local isFirstLoot = InventoryService:Inventory(player, 'CheckExists', curBoatConfig[1].Name)
    if not isFirstLoot then
        local part = boatFolder:FindFirstChild(curBoatConfig[1].Name)
        table.insert(availableParts, part:Clone())
        rewardCount = rewardCount - 1
        index = 2
    else
        local inventory = InventoryService:Inventory(player, 'GetInventory')
        for _, item in pairs(inventory) do
            index += 1
        end
    end
    
    for _ = 1, rewardCount do
        local part = boatFolder:FindFirstChild(curBoatConfig[index].Name)
        table.insert(availableParts, part:Clone())
        index += 1
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
    for _, part in ipairs(parts) do
        -- 调用背包管理器添加物品
        InventoryService:Inventory(player, 'AddItem', part.Name)
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