--[[
模块功能：抽奖系统服务端逻辑
版本：1.0.0
作者：Trea
修改记录：
2024-05-20 创建基础逻辑框架
--]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
require(game.ServerScriptService:WaitForChild('Start'))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))

local LOOT_RE_NAME = 'LootEvent'
local lootEvent = ReplicatedStorage:FindFirstChild(LOOT_RE_NAME)

local GOLD_UPDATE_RE_NAME = 'GoldUpdateEvent'
local goldEvent = ReplicatedStorage:WaitForChild(GOLD_UPDATE_RE_NAME)

local INVENTORY_BF_NAME = 'InventoryBindableFunction'
local inventoryBF = ReplicatedStorage:WaitForChild(INVENTORY_BF_NAME)

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
    local isFirstLoot = inventoryBF:Invoke(player, 'CheckExists', curBoatConfig[1].Name)
    if not isFirstLoot then
        local part = boatFolder:FindFirstChild(curBoatConfig[1].Name)
        table.insert(availableParts, part:Clone())
        rewardCount = rewardCount - 1
        index = 2
    else
        local inventory = inventoryBF:Invoke(player, 'GetInventory')
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

lootEvent.OnServerEvent:Connect(function(player, price)
    -- 获取玩家数据组件
    local gold = player.character:GetAttribute('Gold')
    if not gold or gold < price then
        return
    end
    
    -- 扣除黄金
    gold -= price
    player.character:SetAttribute('Gold', gold)
    goldEvent:FireClient(player, gold)
    
    -- 获取随机配件
    local parts = getRandomParts(player, price)
    for _, part in ipairs(parts) do
        -- 调用背包管理器添加物品
        inventoryBF:Invoke(player, 'AddItem', part.Name)
    end
end)