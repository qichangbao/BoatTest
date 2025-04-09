print('TerrainGenerationService loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local GameConfig = require(ConfigFolder:WaitForChild("GameConfig"))

local TerrainGenerationService = Knit.CreateService({
    Name = 'TerrainGenerationService',
    Client = {
        RequestChunks = Knit.CreateSignal(),
    },
    ChunkSize = GameConfig.TerrainType.Water.ChunkSize,
    Depth = GameConfig.TerrainType.Water.Depth,
    Height = GameConfig.TerrainType.Water.Height,
})

function TerrainGenerationService:GenerateChunk(chunkX, chunkZ)
    local position = Vector3.new(chunkX * self.ChunkSize, -self.Height, chunkZ * self.ChunkSize)
    
    game.Workspace.Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(self.ChunkSize, self.Depth, self.ChunkSize),
        Enum.Material.Water
    )
end

function TerrainGenerationService:RemoveChunk(chunkX, chunkZ)
    local position = Vector3.new(chunkX * self.ChunkSize, -self.Height, chunkZ * self.ChunkSize)
    
    game.Workspace.Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(self.ChunkSize, self.Depth, self.ChunkSize),
        Enum.Material.Air
    )
end

local activeChunks = {}

function TerrainGenerationService:UpdateGlobalChunks()
    for cood, data in pairs(activeChunks) do
        data.curLoad = false
    end

    -- 计算所有玩家影响区域
    for _, player in pairs(Players:GetChildren()) do
        if not player.Character then
            continue
        end

        local pos = player.Character:GetPivot().Position
        local currentChunkX = math.floor((pos.X + self.ChunkSize / 2) / self.ChunkSize)
        local currentChunkZ = math.floor((pos.Z + self.ChunkSize / 2) / self.ChunkSize)
        local coordStr = tostring(currentChunkX)..":"..tostring(currentChunkZ)
        if not activeChunks[coordStr] then
            activeChunks[coordStr] = {curLoad = true, loaded = false}
        else
            activeChunks[coordStr].curLoad = true
        end
    end
    
    for coordStr, data in pairs(activeChunks) do
        if not data.curLoad then
            local x, z = coordStr:match("([%-%d]+):([%-%d]+)")
            --self:RemoveChunk(tonumber(x), tonumber(z))
            activeChunks[coordStr] = nil
        else
            if not data.loaded then
                local x, z = coordStr:match("([%-%d]+):([%-%d]+)")
                self:GenerateChunk(tonumber(x), tonumber(z))
                data.loaded = true
            end
        end
    end
end

function TerrainGenerationService:KnitStart()
    game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateGlobalChunks()
    end)
end

return TerrainGenerationService