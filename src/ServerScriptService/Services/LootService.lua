print('LootService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local BoatConfig = require(ServerScriptService:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))

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
    local rewardCount = 1
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

function LootService.Client:Loot(player)
    -- 获取玩家数据组件
    if _playerCoolDown[player.UserId] > 0 then
        return 10015
    end
    _playerCoolDown[player.UserId] = LOOT_COOLDOWN
    
    -- 获取随机配件
    local parts = getRandomParts(player)
    local InventoryService = Knit.GetService("InventoryService")
    for _, name in ipairs(parts) do
        -- 调用背包管理器添加物品
        InventoryService:Inventory(player, 'AddItem', name, BOAT_PARTS_FOLDER_NAME)
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