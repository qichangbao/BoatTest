--[[
地形管理模块
功能：负责地形生成、岛屿检测和区块资源管理
作者：TRAE
创建日期：2024-03-20
版本历史：
v1.0.0 - 初始版本（2024-03-20）
v1.1.0 - 新增岛屿生成算法（2024-03-25）
]]

local TerrainGeneratorFolder = script.Parent:WaitForChild("TerrainGeneratorFolder")
local LandGenerator = require(TerrainGeneratorFolder:WaitForChild("LandGenerator"))
local WaterGenerator = require(TerrainGeneratorFolder:WaitForChild("WaterGenerator"))

local TerrainManager = {}
TerrainManager.__index = TerrainManager

--[[
构造函数
@param config 地形配置表
- TerrainType: 地形类型配置（Land/Water）
- Islands: 岛屿配置数组
- LandHeight: 基础陆地高度
]]
function TerrainManager.new(config)
    local self = setmetatable({}, TerrainManager)

    -- 移除默认场景
    local Baseplate = game.Workspace:FindFirstChild("Baseplate")
    if Baseplate then
        Baseplate:Destroy()
    end
    
    self.config = config or {}
    self.landPosition = self.config.TerrainType.Land.Position or Vector3.new(0, 0, 0)
    self.landSize = self.config.TerrainType.Land.Size or Vector3.new(100, 5, 100)

    self.islandConfigs = {}
    for _, island in ipairs(config.Islands) do
        table.insert(self.islandConfigs, {
            position = island.Position,
            radius = island.Size.Magnitude / 2,
            spawnChance = island.SpawnChance
        })
    end
    
    return self
end

function TerrainManager:Init()
    local spawnLocation = game.Workspace:WaitForChild("LandSpawnLocation")
    local position = Vector3.new(spawnLocation.Position.X, -self.config.TerrainType.Land.Size.Y / 2 - spawnLocation.Position.Y, spawnLocation.Position.Z)
    -- 直接初始化陆地生成器
    -- self.landGenerator = LandGenerator.new(self.config.TerrainType.Land)
    -- self.landGenerator:Init(position)
    self.waterGenerator = WaterGenerator.new(self.config.TerrainType.Water)
    self.waterGenerator:Init(position.Y)
    
    -- 初始化岛屿生成器
    self.IslandGenerator = LandGenerator.new({
        ChunkSize = self.config.TerrainType.Land.Size,
        LoadDistance = self.config.TerrainType.Land.LoadDistance,
        MaterialType = Enum.Material.Grass
    })
    
    self:GenerateChunk(position)
end

function TerrainManager:Destroy()
end

local function IsInViewRange(playerPos, targetPos, viewDistance)
    return (playerPos - targetPos).Magnitude <= viewDistance
end

function TerrainManager:GetNearestLand(position)
    local nearestLand = nil
    local minDistance = math.huge
    
    -- 三维空间欧氏距离计算：√(Δx² + Δy² + Δz²)
    local distance = (position - self.landPosition).Magnitude
    if distance < minDistance then
        minDistance = distance
        nearestLand = self.landGenerator
    end
    return nearestLand
end

function TerrainManager:GetNearestIsland(position)
    local nearestIsland = nil
    local minDistance = math.huge
    
    for _, island in ipairs(self.islandConfigs) do
        -- 三维空间欧氏距离计算：√(Δx² + Δy² + Δz²)
        local distance = (position - island.position).Magnitude
        if distance < island.radius and distance < minDistance then
            minDistance = distance
            nearestIsland = island
        end
    end
    return nearestIsland
end

function TerrainManager:GetGenerator(position)
    return self:IsInLandArea(position) and self.landGenerator or self.waterGenerator
end

function TerrainManager:IsInLandArea(position)
    local centerX = self.landPosition.X
    local centerZ = self.landPosition.Z
    local halfSize = Vector3.new(self.landSize.X / 2, 0, self.landSize.Z / 2)
    
    local isInside = position.X >= (centerX - halfSize.X) and position.X <= (centerX + halfSize.X)
        and position.Z >= (centerZ - halfSize.Z) and position.Z <= (centerZ + halfSize.Z)
    return isInside
end

--[[
生成地形区块
流程：
1. 检测最近岛屿
2. 判断地形类型（陆地/水域）
3. 优先使用区块池复用
4. 动态生成新地形区块
@param position 生成中心坐标（Vector3）
@return 生成的区块实例
]]
function TerrainManager:GenerateChunk(position)
    local nearestIsland = self:GetNearestIsland(position)
    local generator = self:GetGenerator(position)
    local loadDistance = generator.config.LoadDistance or 1
    local size = generator.config.ChunkSize or generator.config.Size or Vector3.new(100, 5, 100)
    local viewDistance = loadDistance * size
    
    -- 优先检测视野范围内的岛屿
    if nearestIsland and IsInViewRange(position, nearestIsland.position, viewDistance) then
        if math.random() < nearestIsland.spawnChance then
            local islandGenerator = self.IslandGenerator
            local chunk = islandGenerator:GenerateTerrainChunk(position)
            chunk.Size = Vector3.new(nearestIsland.radius * 2, self.config.LandHeight, nearestIsland.radius * 2)
            chunk.Material = Enum.Material.Grass
            chunk.Parent = game.Workspace
        end
    end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local m = TerrainManager.new(require(ConfigFolder:WaitForChild("GameConfig")))
m:Init()