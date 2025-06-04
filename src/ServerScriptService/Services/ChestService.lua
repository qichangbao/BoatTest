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
        chance = 0, -- 60%概率获得金币
        minAmount = 10,
        maxAmount = 50,
    },
    
    -- Buff奖励配置
    buff = {
        chance = 0, -- 30%概率获得Buff
        availableBuffs = {
            "speed_boost",
            "health_boost",
            "attack_boost",
            "fishing_bonus"
        },
        minDuration = 30,
        maxDuration = 120,
    },
    
    -- 物品奖励配置
    item = {
        chance = 1, -- 40%概率获得物品
        -- 使用ItemConfig中的随机物品系统
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
function ChestService:ProcessChestRewards(player)
    if not player or not player.Parent then
        return false
    end
    
    -- 检查金币奖励
    if math.random(0, 1) < CHEST_REWARDS.gold.chance then
        local goldAmount = generateRandomGold()
        if addGoldToPlayer(player, goldAmount) then
            sendRewardNotification(player, "Gold", {amount = goldAmount})
            print("ChestService: 玩家 " .. player.Name .. " 获得金币: " .. goldAmount)
        end
    end
    
    -- 检查Buff奖励
    if math.random(0, 1) < CHEST_REWARDS.buff.chance then
        local buffData = generateRandomBuff()
        if addBuffToPlayer(player, buffData) then
            print("ChestService: 玩家 " .. player.Name .. " 获得Buff: " .. buffData.displayName)
        end
    end
    
    -- 检查物品奖励
    if math.random(0, 1) < CHEST_REWARDS.item.chance then
        local itemData = generateRandomItem()
        if itemData and addItemToPlayer(player, itemData) then
            print("ChestService: 玩家 " .. player.Name .. " 获得物品: " .. itemData.itemName)
        end
    end
    
    return true
end

function ChestService:KnitInit()
    print('ChestService initialized')
end

return ChestService