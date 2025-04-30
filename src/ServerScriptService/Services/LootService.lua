print('LootService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local BoatConfig = require(ServerScriptService:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local ItemConfig = require(ServerScriptService:WaitForChild('ConfigFolder'):WaitForChild('ItemConfig'))

local LootService = Knit.CreateService({
    Name = 'LootService',
    Client = {
    },
})

-- 配件生成配置
local BOAT_PARTS_FOLDER_NAME = '船'
local LOOT_COOLDOWN = 3.6
local _playerCoolDown = {}

local function getRandomParts(player)
    local boatTemplate = ServerStorage:FindFirstChild(BOAT_PARTS_FOLDER_NAME)
    if not boatTemplate then return {} end

    local curBoatConfig = BoatConfig.GetBoatConfig(BOAT_PARTS_FOLDER_NAME)
    local InventoryService = Knit.GetService("InventoryService")
    
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
        return primaryPartName
    end

    local randomItem = ItemConfig.GetRandomItem()
    for name, data in pairs(curBoatConfig) do
        if name == randomItem.itemName then
            return name
        end
    end
end

function LootService.Client:Loot(player)
    -- 获取玩家数据组件
    if _playerCoolDown[player.UserId] > 0 then
        return 10015
    end
    _playerCoolDown[player.UserId] = LOOT_COOLDOWN
    
    -- 获取随机配件
    local partName = getRandomParts(player)
    local InventoryService = Knit.GetService("InventoryService")
    if InventoryService:Inventory(player, 'CheckExists', partName) then
        local itemConfig = ItemConfig.GetItemConfig(partName)
        if itemConfig then
            player:SetAttribute('Gold', player:GetAttribute('Gold') + itemConfig.sellPrice)
        end
        return 10016, partName
    else
        -- 调用背包管理器添加物品
        InventoryService:Inventory(player, 'AddItem', partName, BOAT_PARTS_FOLDER_NAME)
    end

    return
end

function LootService:KnitInit()
    print('LootService initialized')
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
    print('LootService started')
end

return LootService