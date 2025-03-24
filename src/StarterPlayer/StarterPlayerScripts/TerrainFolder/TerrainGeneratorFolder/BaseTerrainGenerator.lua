--- 地形生成器基类模块
-- 提供地形生成器的公共接口与基础实现
-- @module BaseTerrainGenerator
-- @author 作者名
-- @created 2024-05-20
-- @last_modified 2024-05-20

local BaseTerrainGenerator = {}
BaseTerrainGenerator.isTerrainGenerator = true

--- 创建基础地形生成器实例
-- @function new
-- @param config table 配置参数表
-- @return table 新生成的地形生成器实例
function BaseTerrainGenerator.new(config)
    local self = setmetatable({}, BaseTerrainGenerator)
    self.config = config
    return self
end

--- 初始化基础配置
-- @function Init
-- @remark 设置默认材质类型
function BaseTerrainGenerator:Init()
    self.materialType = Enum.Material.Plastic
end

function BaseTerrainGenerator:Destroy()
end

function BaseTerrainGenerator:UpdateChunks(playerPosition)
end

function BaseTerrainGenerator:FillBlock(position)
    -- 地形填充 (未实现)
end

return BaseTerrainGenerator