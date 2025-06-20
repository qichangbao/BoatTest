--[[
模块功能：岛屿管理服务
版本：1.0.0
作者：Trea
修改记录：
2024-02-26 创建岛屿管理服务
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local IslandConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("IslandConfig"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local IslandManageService = Knit.CreateService {
    Name = "IslandManageService",
    Client = {
        -- 获取玩家拥有的岛屿
        GetPlayerIslands = Knit.CreateSignal(),
        -- 获取单个岛屿数据
        GetIslandData = Knit.CreateSignal(),
    },
}

-- 获取玩家拥有的岛屿
function IslandManageService.Client:GetPlayerIslands(player)
    return self.Server:GetPlayerIslands(player)
end

function IslandManageService:GetPlayerIslands(player)
    local islands = {}
    
    -- 从SystemService获取所有岛屿的拥有者信息
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    
    -- 遍历所有被占领的岛屿，找出属于当前玩家的岛屿
    for landName, ownerData in pairs(islandOwners) do
        if ownerData.userId == player.UserId then
            -- 获取岛屿配置
            local islandConfig = nil
            for _, config in pairs(IslandConfig.IsLand) do
                if config.Name == landName then
                    islandConfig = config
                    break
                end
            end
            
            if islandConfig then
                table.insert(islands, {
                    id = landName, -- 使用岛屿名称作为ID
                    name = landName,
                    towerData = ownerData.towerData or {},
                    position = islandConfig.Pos,
                    maxTowers = islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
                })
            end
        end
    end
    
    return islands
end

-- 获取单个岛屿数据
function IslandManageService.Client:GetIslandData(player, islandId)
    return self.Server:GetIslandData(player, islandId)
end

function IslandManageService:GetIslandData(player, islandId)
    -- 从SystemService验证玩家是否拥有该岛屿
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local ownerData = islandOwners[islandId]
    if not ownerData or ownerData.userId ~= player.UserId then
        return nil
    end
    
    -- 获取岛屿配置
    local islandConfig = nil
    for _, config in pairs(IslandConfig.IsLand) do
        if config.Name == islandId then
            islandConfig = config
            break
        end
    end
    
    if not islandConfig then
        return nil
    end
    
    local isLandData = islandOwners[islandId]
    
    return {
        id = islandId,
        name = islandId,
        towerData = isLandData.towerData or {},
        position = islandConfig.TowerOffsetPos,
        maxTowers = islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
    }
end

-- 购买箭塔
function IslandManageService.Client:BuyTower(player, islandId, towerType, index)
    return self.Server:BuyTower(player, islandId, towerType, index)
end

function IslandManageService:BuyTower(player, islandId, towerType, index)
    -- 从SystemService验证玩家是否拥有该岛屿
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local isLandData = islandOwners[islandId]
    if not isLandData or isLandData.userId ~= player.UserId then
        return false, 10058
    end
    
    -- 获取岛屿配置
    local islandConfig = nil
    for _, config in pairs(IslandConfig.IsLand) do
        if config.Name == islandId then
            islandConfig = config
            break
        end
    end
    
    if not islandConfig then
        return false, 10057
    end
    
    if not isLandData.towerData then
        isLandData.towerData = {}
    end
    
    local maxTowers = islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
    local currentTowers = #isLandData.towerData
    
    -- 检查是否已达到最大箭塔数量
    if currentTowers >= maxTowers then
        return false, 10059
    end
    
    -- 验证箭塔类型
    towerType = towerType or "Tower1" -- 默认箭塔类型
    local towerConfig = TowerConfig[towerType]
    if not towerConfig then
        return false, 10057
    end
    
    -- 检查金币是否足够
    local towerCost = 100
    local playerGold = player:GetAttribute("Gold")
    if tonumber(playerGold) < towerCost then
        return false, 10056
    end
    
    -- 扣除金币
    player:SetAttribute("Gold", tonumber(playerGold) - towerCost)

    local TowerService = Knit.GetService("TowerService")
    local towerDataTemp = {towerType = towerType, index = index, health = towerConfig.Health}
    local towerModel = TowerService:CreateTower(islandId, towerDataTemp)
    towerDataTemp.towerName = towerModel.Name
    
    -- 存储箭塔类型信息
    table.insert(isLandData.towerData, towerDataTemp)
    
    SystemService:ChangeIsLandOwnerData(islandOwners, {islandId = islandId, isLandData = isLandData})
    
    return true, 10055
end

-- 移除箭塔
function IslandManageService.Client:RemoveTower(player, islandId, index)
    return self.Server:RemoveTower(player, islandId, index)
end

function IslandManageService:RemoveTower(player, islandId, index)
    -- 从SystemService验证玩家是否拥有该岛屿
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local isLandData = islandOwners[islandId]
    if not isLandData or isLandData.userId ~= player.UserId then
        return false, 10061
    end
    
    if not isLandData.towerData then
        return false, 10057
    end

    local towerDataTemp = nil
    local towerArrayIndex = nil
    -- 移除箭塔
    for i, data in ipairs(isLandData.towerData) do
        if data.index == index then
            towerDataTemp = data
            towerArrayIndex = i
            table.remove(isLandData.towerData, i)
            break
        end
    end
    
    local TowerService = Knit.GetService("TowerService")
    TowerService:RemoveTower(islandId, towerDataTemp.towerName)
    
    SystemService:ChangeIsLandOwnerData(islandOwners, {islandId = islandId, isLandData = isLandData})
    return true, 10060
end

-- 获取箭塔信息
function IslandManageService.Client:GetTowerInfo(player, islandId, index)
    return self.Server:GetTowerInfo(player, islandId, index)
end

function IslandManageService:GetTowerInfo(player, islandId, index)
    -- 从SystemService验证玩家是否拥有该岛屿
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local isLandData = islandOwners[islandId]
    if not isLandData or isLandData.userId ~= player.UserId then
        return false, 10061
    end
    
    -- 获取箭塔信息
    local TowerService = Knit.GetService("TowerService")
    local towerInfo = TowerService:GetTowerInfo(islandId, index)
    
    if towerInfo then
        return true, towerInfo
    else
        return false, 10062 -- 箭塔不存在
    end
end

function IslandManageService:KnitInit()
end

function IslandManageService:KnitStart()
end

return IslandManageService