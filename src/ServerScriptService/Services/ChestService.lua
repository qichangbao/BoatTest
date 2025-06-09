--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local BuffConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BuffConfig"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("ItemConfig"))

local ChestService = Knit.CreateService({
    Name = 'ChestService',
    Client = {
        RewardReceived = Knit.CreateSignal(),
    },
})

-- 宝箱奖励配置
local CHEST_REWARDS = {
    -- 金币奖励配置
    gold = {
        chance = 0.6, -- 60%概率获得金币
        minAmount = 10,
        maxAmount = 50,
    },
    
    -- Buff奖励配置
    buff = {
        chance = 0.3, -- 30%概率获得Buff
    },
    
    -- 物品奖励配置
    item = {
        chance = 0.4, -- 40%概率获得物品
    }
}

-- 生成随机金币数量
local function generateRandomGold()
    return math.random(CHEST_REWARDS.gold.minAmount, CHEST_REWARDS.gold.maxAmount)
end

-- 生成随机Buff
local function generateRandomBuff()
    return BuffConfig.GetRandomBuff()
end

-- 生成随机物品
local function generateRandomItem()
    return ItemConfig.GetRandomItem()
end

-- 给玩家添加金币
local function addGoldToPlayer(player, amount)
    local currentGold = player:GetAttribute("Gold") or 0
    player:SetAttribute("Gold", currentGold + amount)
    
    return true
end

-- 给玩家添加Buff
local function addBuffToPlayer(player, buffData)
    local BuffService = Knit.GetService('BuffService')
    return BuffService:AddBuff(player, buffData)
end

-- 给玩家添加物品
local function addItemToPlayer(player, itemData)
    local InventoryService = Knit.GetService('InventoryService')
    return InventoryService:Inventory(player, "AddItem", itemData.itemName, itemData.modelName)
end

-- 发送奖励通知给客户端
local function sendRewardNotification(player, rewardType, rewardData)
    ChestService.Client.RewardReceived:Fire(player, rewardType, rewardData)
end

-- 处理宝箱奖励
function ChestService:ProcessChestRewards(player, chestPosition)
    if not player or not player.Parent then
        return false
    end
    
    -- 如果没有提供宝箱位置，使用默认位置
    if not chestPosition then
        chestPosition = Vector3.new(0, 10, 0)
    end
    
    local isReward = false
    -- 检查金币奖励
    if math.random() < CHEST_REWARDS.gold.chance then
        local goldAmount = generateRandomGold()
        if addGoldToPlayer(player, goldAmount) then
            sendRewardNotification(player, "Gold", {amount = goldAmount, chestPosition = chestPosition})
            isReward = true
            print("ChestService: 玩家 " .. player.Name .. " 获得金币: " .. goldAmount)
        end
    end
    
    -- 检查Buff奖励
    if math.random() < CHEST_REWARDS.buff.chance then
        local buffData = generateRandomBuff()
        if addBuffToPlayer(player, buffData) then
            sendRewardNotification(player, "Buff", {displayName = buffData.displayName, chestPosition = chestPosition})
            isReward = true
            print("ChestService: 玩家 " .. player.Name .. " 获得Buff: " .. buffData.displayName)
        end
    end
    
    -- 检查物品奖励
    if math.random() < CHEST_REWARDS.item.chance then
        local itemData = generateRandomItem()
        if itemData and addItemToPlayer(player, itemData) then
            sendRewardNotification(player, "Item", {itemName = itemData.itemName, chestPosition = chestPosition})
            isReward = true
            print("ChestService: 玩家 " .. player.Name .. " 获得物品: " .. itemData.itemName)
        end
    end
    
    if not isReward then
        sendRewardNotification(player, "")
        print("ChestService: 玩家捡到了空箱子:", player.Name)
    end
    return true
end

function ChestService:KnitInit()
    print('ChestService initialized')
end

return ChestService