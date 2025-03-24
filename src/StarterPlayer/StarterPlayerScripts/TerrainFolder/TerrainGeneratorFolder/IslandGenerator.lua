--[[
模块名称：岛屿地形生成器
版本：1.0.0
功能：负责生成基于岛屿结构的地形区块
作者：Trea开发团队
最后更新时间：2024-05-20
]]

local BaseTerrainGenerator = require(script.Parent:WaitForChild("BaseTerrainGenerator"))

local IslandGenerator = {}
setmetatable(IslandGenerator, {__index = BaseTerrainGenerator})
IslandGenerator.__index = IslandGenerator

-- 构造函数
-- @param config table 地形配置表
-- @return IslandGenerator实例
function IslandGenerator.new(config)
    local self = setmetatable(BaseTerrainGenerator.new(config), IslandGenerator)
    return self
end

-- 初始化地形生成器参数
-- 从配置表获取陆地材质类型、区块尺寸等参数
function IslandGenerator:Init()
    BaseTerrainGenerator.Init(self)
    -- 设置材质类型（来自配置表）
    self.materialType = self.config.TerrainType.Land.Material
    -- 设置区块尺寸（来自配置表）
    self.chunkSize = self.config.TerrainType.Land.ChunkSize
    -- 设置加载距离（来自配置表）
    self.loadDistance = self.config.TerrainType.Land.LoadDistance
    -- 设置地形高度（来自配置表）
    self.terrainHeight = self.config.TerrainType.Land.Height
end

-- 生成指定位置的地形区块
-- @param position Vector3 区块生成的世界坐标
-- @return Instance 新创建的地形区块实例
function IslandGenerator:GenerateTerrainChunk(position)
    local chunk = Instance.new("MeshPart")
    -- 应用配置的区块尺寸
    chunk.Size = self.chunkSize
    -- 设置区块生成位置
    chunk.Position = position
    -- 应用配置的材质类型
    chunk.Material = self.materialType
    -- 固定区块位置防止物理模拟
    chunk.Anchored = true
    return chunk
end

function IslandGenerator:UpdateChunks(playerPosition)
    
end

return IslandGenerator