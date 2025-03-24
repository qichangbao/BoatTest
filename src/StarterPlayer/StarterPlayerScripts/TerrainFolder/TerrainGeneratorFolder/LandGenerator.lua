--- 陆地地形生成器模块
-- 负责处理中心陆地地形的生成与配置
-- @module LandGenerator
-- @author 作者名
-- @created 2024-05-20
-- @last_modified 2024-05-20

local BaseTerrainGenerator = require(script.Parent:WaitForChild("BaseTerrainGenerator"))

local LandGenerator = {}
setmetatable(LandGenerator, {__index = BaseTerrainGenerator})
LandGenerator.__index = LandGenerator
LandGenerator.isTerrainGenerator = true

--- 创建新的陆地生成器实例
-- @function new
-- @param config table 配置参数表
-- @return table 新生成的陆地生成器实例
function LandGenerator.new(config)
    local self = setmetatable(BaseTerrainGenerator.new(config), LandGenerator)
    return self
end

--- 初始化陆地生成器配置
-- @function Init
-- @remark 设置地形材质、区块尺寸和加载范围等核心参数
function LandGenerator:Init()
    BaseTerrainGenerator.Init(self)

    -- 地形材质类型（默认：草地）
    self.materialType = self.config.Material or Enum.Material.Grass
    
    -- 区块基础尺寸（单位：stud）
    self.size = self.config.Size or Vector3.new(10, 10, 10)
    
    -- 区块加载距离（单位：区块数量）
    self.loadDistance = self.config.LoadDistance or 1
end

-- 生成指定位置的地形区块
-- @param position Vector3 区块生成的世界坐标
-- @return Instance 新创建的地形区块实例
function LandGenerator:GenerateTerrainChunk(position)
    local chunk = Instance.new("MeshPart")
    chunk.Name = "Land"
    chunk.Position = position
    chunk.Anchored = true
    chunk.Material = self.materialType
    chunk.Size = self.size
    
    return chunk
end

function LandGenerator:FillBlock(position)
    game:GetService("Workspace").Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(self.size),
        self.materialType
    )
end

return LandGenerator