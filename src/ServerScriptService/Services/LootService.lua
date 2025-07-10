local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local ItemConfig = require(ReplicatedStorage:WaitForChild('ConfigFolder'):WaitForChild('ItemConfig'))

local LootService = Knit.CreateService({
    Name = 'LootService',
    Client = {
    },
})

-- 配件生成配置
local LOOT_COOLDOWN = 3.6
local _playerCoolDown = {}

local function getRandomParts(player)
    local playerSailingTime = Knit.GetService("RankService"):GetPersonalData(player).totalSailingTime
    local playerDay = string.format("%.2f", playerSailingTime / (24 * 3600))
    local itemData = ItemConfig.GetRandomItem(tonumber(playerDay))
    if not itemData then
        return
    end
    if itemData.itemType == ItemConfig.BoatTag then
        local curBoatConfig = BoatConfig.GetBoatConfig(itemData.modelName)
        
        -- 添加主要部件（如果首次获取）
        local primaryPartName = ''
        for name, data in pairs(curBoatConfig) do
            if data.PartType == 'PrimaryPart' then
                primaryPartName = name
                break
            end
        end
        
        local isFirstLoot = Knit.GetService("InventoryService"):Inventory(player, 'CheckExists', primaryPartName)
        if not isFirstLoot and primaryPartName ~= '' then
            return itemData.itemType,primaryPartName, itemData.modelName
        end

        local randomItem = ItemConfig.GetRandomItem(tonumber(playerDay))
        for name, data in pairs(curBoatConfig) do
            if name == randomItem.itemName then
                return itemData.itemType, name, itemData.modelName
            end
        end
    else
        return itemData.itemType, itemData.itemName, itemData.modelName
    end
end

function LootService.Client:Loot(player)
    -- 获取玩家数据组件
    if _playerCoolDown[player.UserId] and _playerCoolDown[player.UserId] > 0 then
        return 10015
    end
    _playerCoolDown[player.UserId] = LOOT_COOLDOWN
    
    -- 获取随机配件
    local itemType, partName, modelName = getRandomParts(player)
    if not itemType then
        return 10105
    end
    local InventoryService = Knit.GetService("InventoryService")
    if InventoryService:Inventory(player, 'CheckExists', partName) then
        local itemConfig = ItemConfig.GetItemConfig(partName)
        if itemConfig then
            player:SetAttribute('Gold', tonumber(player:GetAttribute('Gold')) + itemConfig.sellPrice)
        end
        return 10016, partName
    else
        -- 调用背包管理器添加物品
        InventoryService:Inventory(player, 'AddItem', itemType, partName, modelName)
    end

    return
end

function LootService:KnitInit()
    RunService.Heartbeat:Connect(function(dt)
        for userId, cooldown in pairs(_playerCoolDown) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                if cooldown > 0 then
                    _playerCoolDown[userId] = cooldown - dt
                else
                    _playerCoolDown[userId] = 0
                end
            else
                _playerCoolDown[userId] = nil
            end
        end
    end)
    Players.PlayerAdded:Connect(function(player)
        _playerCoolDown[player.UserId] = LOOT_COOLDOWN
    end)
    Players.PlayerRemoving:Connect(function(player)
        _playerCoolDown[player.UserId] = nil
    end)
end

function LootService:KnitStart()
end

return LootService