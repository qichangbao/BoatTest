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
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))

local IslandManageService = Knit.CreateService {
    Name = "IslandManageService",
    Client = {
        -- 获取玩家拥有的岛屿
        GetPlayerIslands = Knit.CreateSignal(),
        -- 获取单个岛屿数据
        GetIslandData = Knit.CreateSignal(),
        -- 购买箭塔
        BuyTower = Knit.CreateSignal(),
        -- 购买箭矢
        BuyArrows = Knit.CreateSignal(),
    },
}

-- 获取玩家数据服务
local DBService

function IslandManageService:KnitStart()
    DBService = Knit.GetService("DBService")
end

function IslandManageService:KnitInit()
end

-- 获取玩家拥有的岛屿
function IslandManageService.Client:GetPlayerIslands(player)
    return self.Server:GetPlayerIslands(player)
end

function IslandManageService:GetPlayerIslands(player)
    local islands = {}
    
    -- 从SystemService获取所有岛屿的拥有者信息
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner(player)
    
    -- 遍历所有被占领的岛屿，找出属于当前玩家的岛屿
    for landName, ownerData in pairs(islandOwners) do
        if ownerData.userId == player.UserId then
            -- 获取岛屿配置
            local islandConfig = nil
            for _, config in pairs(GameConfig.IsLand) do
                if config.Name == landName then
                    islandConfig = config
                    break
                end
            end
            
            if islandConfig then
                table.insert(islands, {
                    id = landName, -- 使用岛屿名称作为ID
                    name = landName,
                    islandDefenseData = ownerData.islandDefenseData,
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
    local islandOwners = SystemService:GetIsLandOwner(player)
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local ownerData = islandOwners[islandId]
    if not ownerData or ownerData.userId ~= player.UserId then
        return nil
    end
    
    -- 获取岛屿配置
    local islandConfig = nil
    for _, config in pairs(GameConfig.IsLand) do
        if config.Name == islandId then
            islandConfig = config
            break
        end
    end
    
    if not islandConfig then
        return nil
    end
    
    local isLandData = islandOwners[islandId]
    local islandDefenseData = isLandData.towerData
    
    return {
        id = islandId,
        name = islandId,
        islandDefenseData = islandDefenseData,
        position = islandConfig.TowerOffsetPos,
        maxTowers = islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
    }
end

-- 购买箭塔
function IslandManageService.Client:BuyTower(player, islandId, towerType)
    return self.Server:BuyTower(player, islandId, towerType)
end

function IslandManageService:BuyTower(player, islandId, towerType)
    -- 从SystemService验证玩家是否拥有该岛屿
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner(player)
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local ownerData = islandOwners[islandId]
    if not ownerData or ownerData.userId ~= player.UserId then
        return false
    end
    
    -- 获取岛屿配置
    local islandConfig = nil
    for _, config in pairs(GameConfig.IsLand) do
        if config.Name == islandId then
            islandConfig = config
            break
        end
    end
    
    if not islandConfig then
        return false
    end
    
    local isLandData = islandOwners[islandId]
    if not isLandData.towerData then
        isLandData.towerData = {}
    end
    
    local maxTowers = islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
    local currentTowers = #isLandData.towerData
    
    -- 检查是否已达到最大箭塔数量
    if currentTowers >= maxTowers then
        return false
    end
    
    -- 验证箭塔类型
    towerType = towerType or "Tower1" -- 默认箭塔类型
    if not TowerConfig[towerType] then
        return false
    end
    
    -- 检查金币是否足够
    local towerCost = 100
    local playerGold = player:GetAttribute("Gold")
    if tonumber(playerGold) < towerCost then
        return false
    end
    
    -- 扣除金币
    player:SetAttribute("Gold", tonumber(playerGold) - towerCost)
    
    -- 存储箭塔类型信息
    table.insert(isLandData.towerData, {
        towerType = towerType,
        arrowCount = 0,
    })
    
    return true
end

-- 购买箭矢
function IslandManageService.Client:BuyArrows(player, islandId, towerIndex, amount)
    return self.Server:BuyArrows(player, islandId, towerIndex, amount)
end

function IslandManageService:BuyArrows(player, islandId, towerIndex, count)
    -- 从SystemService验证玩家是否拥有该岛屿
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner(player)
    
    -- 检查玩家是否拥有该岛屿（islandId现在是岛屿名称）
    local ownerData = islandOwners[islandId]
    if not ownerData or ownerData.userId ~= player.UserId then
        return false
    end

    local isLandData = islandOwners[islandId]
    local islandDefenseData = isLandData.towerData
    if not islandDefenseData then
        islandDefenseData = {towerData = {}}
    end

    -- 验证箭塔索引
    if islandDefenseData.towers[towerIndex] then
        return false
    end
    
    local towerData = islandDefenseData.towerData[towerIndex]
    local towerType = towerData.towerType
    
    -- 验证箭塔类型
    if not TowerConfig[towerType] then
        return false
    end
    
    local maxArrows = TowerConfig[towerType].MaxArrow
    local currentArrows = towerData.arrowCount or 0
    
    -- 检查购买数量是否有效
    if count <= 0 or currentArrows + count > maxArrows then
        return false
    end
    
    -- 检查金币是否足够
    local arrowCost = 1
    local totalCost = count * arrowCost
    local playerGold = player:GetAttribute("Gold")
    if tonumber(playerGold) < totalCost then
        return false
    end
    
    -- 扣除金币
    player:SetAttribute("Gold", tonumber(playerGold) - totalCost)
    
    -- 增加特定箭塔的箭矢数量
    towerData.arrowCount = currentArrows + count
    
    return true
end

-- 初始化玩家岛屿数据（当玩家占领新岛屿时调用）
function IslandManageService:InitializeIsland(player, islandName)
    local profile = DBService:GetProfile(player.UserId)
    if not profile then
        return false
    end
    
    local playerData = profile.Data
    
    -- 初始化Islands表
    if not playerData.Islands then
        playerData.Islands = {}
    end
    
    -- 生成唯一的岛屿ID
    local islandId = tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
    
    -- 创建岛屿数据
    playerData.Islands[islandId] = {
        name = islandName,
        towerCount = 0,
        arrowCount = 0,
        captureTime = os.time()
    }
    
    return islandId
end

-- 移除岛屿（当玩家失去岛屿时调用）
function IslandManageService:RemoveIsland(player, islandId)
    local profile = DBService:GetProfile(player.UserId)
    if not profile then
        return false
    end
    
    local playerData = profile.Data
    
    if playerData.Islands and playerData.Islands[islandId] then
        playerData.Islands[islandId] = nil
        return true
    end
    
    return false
end

-- 获取岛屿维护费用
function IslandManageService:GetMaintenanceCost(player)
    local profile = DBService:GetProfile(player.UserId)
    if not profile then
        return 0
    end
    
    local playerData = profile.Data
    local totalCost = 0
    
    if playerData.Islands then
        for _, islandData in pairs(playerData.Islands) do
            local towerCost = (islandData.towerCount or 0) * 5
            local arrowCost = math.floor((islandData.arrowCount or 0) / 100) * 2
            totalCost = totalCost + towerCost + arrowCost
        end
    end
    
    return totalCost
end

-- 计算岛屿收益
function IslandManageService:GetIslandIncome(player)
    local profile = DBService:GetProfile(player.UserId)
    if not profile then
        return 0
    end
    
    local playerData = profile.Data
    local totalIncome = 0
    
    if playerData.Islands then
        for _, islandData in pairs(playerData.Islands) do
            -- 获取岛屿配置
            local islandConfig = nil
            for _, config in pairs(GameConfig.IsLand) do
                if config.Name == islandData.name then
                    islandConfig = config
                    break
                end
            end
            
            if islandConfig then
                local maxTowers = islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
                local defenseLevel = math.min(math.floor((islandData.towerCount or 0) / maxTowers * 5) + 1, 5)
                local income = (islandData.towerCount or 0) * 20 + defenseLevel * 10
                totalIncome = totalIncome + income
            end
        end
    end
    
    return totalIncome
end

return IslandManageService