--- 水域地形生成器模块
-- 负责处理水域地形生成与波浪效果配置
-- @module WaterGenerator
-- @author 作者名
-- @created 2024-05-20
-- @last_modified 2024-05-20

local Workspace = game:GetService("Workspace")
local BaseTerrainGenerator = require(script.Parent:WaitForChild("BaseTerrainGenerator"))

local WaterGenerator = {}
setmetatable(WaterGenerator, {__index = BaseTerrainGenerator})
WaterGenerator.__index = WaterGenerator
WaterGenerator.isTerrainGenerator = true

--- 创建新的水域生成器实例
-- @function new
-- @param config table 水域配置参数表
-- @return table 新生成的水域生成器实例
function WaterGenerator.new(config)
    local self = setmetatable(BaseTerrainGenerator.new(config), WaterGenerator)
    return self
end

--- 初始化水域生成器配置
-- @function Init
-- @remark 配置水域材质、区块尺寸和波浪效果参数
function WaterGenerator:Init(y)
    BaseTerrainGenerator.Init(self)
    
    self.y = y
    -- 水域材质类型（默认：水体）
    self.materialType = self.config.Material or Enum.Material.Water
    
    -- 水域区块尺寸（单位：stud）
    self.chunkSize = self.config.ChunkSize or 200
    
    -- 区块加载距离（空值表示持续加载）
    self.loadDistance = self.config.LoadDistance or 2
    
    -- 水域基准深度（单位：stud）
    self.waterDepth = self.config.Depth or 30
    
    -- 波浪运动速度（单位：m/s）
    self.waveSpeed = self.config.WaveSpeed or 0.5

    -- 通用容器设置
    self.terrainFolder = workspace:FindFirstChild("TerrainPart") or Instance.new("Folder")
    self.terrainFolder.Name = "TerrainPart"
    self.terrainFolder.Parent = workspace

    self.noise = Random.new()
    self.activeChunks = {}
    self.poolChunks = {}
    self.lastPlayerChunk = nil

    -- local landPosition = Workspace:WaitForChild("LandSpawnLocation").Position
    -- self:UpdateChunks(landPosition)
    -- self:SetupChunkLoader()
end

-- 生成指定位置的地形区块
-- @param position Vector3 区块生成的世界坐标
-- @return Instance 新创建的地形区块实例
function WaterGenerator:GenerateTerrainChunk(position)
    local chunk = Instance.new("MeshPart")
    -- 根据陆地块尺寸计算偏移量
    chunk.Position = position
    chunk.Size = Vector3.new(self.chunkSize, self.waterDepth, self.chunkSize)
    chunk.CanCollide = false
    chunk.Anchored = true
    chunk.Material = self.materialType
    chunk.Reflectance = 0.3
    chunk.Transparency = 0  -- 确保不透明度
    chunk.Color = Color3.new(0.007843, 0.007843, 0.007843)
    chunk.CastShadow = false
    chunk.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Water)

    return chunk
end

function WaterGenerator:FillBlock(position)
    -- 校验尺寸有效性
    assert(self.chunkSize > 0, "区块尺寸必须大于0")
    assert(self.waterDepth > 0, "水域深度必须大于0")
    
    -- 水域地形填充
    Workspace.Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(self.chunkSize, self.waterDepth, self.chunkSize),
        self.materialType
    )

    -- -- 波浪动画协程
    -- coroutine.wrap(function()
    --     while true do
    --         local time = tick() * self.waveSpeed
    --         local waveHeight = math.sin(time) * 1.5 + 5
    --         Workspace.Terrain:FillBlock(
    --             CFrame.new(position),
    --             Vector3.new(self.chunkSize * 1.1, waveHeight, self.chunkSize * 1.1),
    --             self.materialType
    --         )
    --         wait(0.3)
    --     end
    -- end)()
end

function WaterGenerator:SetupChunkLoader()
    -- 基础区块加载器实现
    self.chunkLoaderConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if game.Players.LocalPlayer.Character then
            local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                self:UpdateChunks(humanoidRootPart.Position)
            end
        end
    end)
end

function WaterGenerator:UpdateChunks(playerPosition)
    local currentChunk = Vector3.new(
        math.floor((playerPosition.X + self.chunkSize / 2)/ self.chunkSize),
        0,
        math.floor((playerPosition.Z + self.chunkSize / 2) / self.chunkSize)
    )
    if self.lastPlayerChunk and currentChunk == self.lastPlayerChunk then
        return
    end
    self.lastPlayerChunk = currentChunk

    for x = -self.loadDistance, self.loadDistance do
        for z = -self.loadDistance, self.loadDistance do
            local chunkPos = Vector3.new(
                currentChunk.X * self.chunkSize + x * self.chunkSize,
                self.y,
                currentChunk.Z * self.chunkSize + z * self.chunkSize
            )
            if not self.activeChunks[chunkPos] then
                local newChunk = self.poolChunks[1] or self:GenerateTerrainChunk(chunkPos)
                newChunk:ClearAllChildren()  -- 清除残留子部件
                newChunk.Position = Vector3.new(chunkPos.X, self.y, chunkPos.Z)
                newChunk.Transparency = 1  -- 确保不透明度
                self:FillBlock(chunkPos)
                table.remove(self.poolChunks, 1)
                newChunk.Parent = self.terrainFolder
                self.activeChunks[chunkPos] = newChunk
                print("加载", chunkPos)
            end
        end
    end

    for chunkPos, chunk in pairs(self.activeChunks) do
        if math.abs(chunkPos.X - currentChunk.X) > self.loadDistance * self.chunkSize
        or math.abs(chunkPos.Z - currentChunk.Z) > self.loadDistance * self.chunkSize then
            -- 水域地形填充
            -- Workspace.Terrain:FillBlock(
            --     CFrame.new(chunkPos),
            --     Vector3.new(self.chunkSize, self.waterDepth, self.chunkSize),
            --     Enum.Material.Air
            -- )
            print("移除", chunkPos)
            table.insert(self.poolChunks, chunk)
            self.activeChunks[chunkPos] = nil
        end
    end
end

function WaterGenerator:Destroy()
    if self.chunkLoaderConnection then
        self.chunkLoaderConnection:Disconnect()
        self.chunkLoaderConnection = nil
    end
end

return WaterGenerator
