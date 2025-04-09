print('TerrainGenerationService loaded')
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

local TerrainGenerationService = Knit.CreateService({
    Name = 'TerrainGenerationService',
    Client = {
        RequestChunks = Knit.CreateSignal(),
    },
    ChunkSize = GameConfig.TerrainType.Water.ChunkSize,
    Depth = GameConfig.TerrainType.Water.Depth,
    LoadDistance = GameConfig.TerrainType.Water.LoadDistance,
    ActiveChunks = {},
    PlayerChunks = {},
})

function TerrainGenerationService:FillBlock(position)
    game.Workspace.Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(self.ChunkSize, self.Depth, self.ChunkSize),
        Enum.Material.Water
    )
end

function TerrainGenerationService:RemoveBlock(position)
    game.Workspace.Terrain:FillBlock(
        CFrame.new(position),
        Vector3.new(self.ChunkSize, self.Depth, self.ChunkSize),
        Enum.Material.Air
    )
end

function TerrainGenerationService:UpdateChunk(player, currentChunk)
    local playerChunk = self.PlayerChunks[player]
    for coordStr, value in pairs(playerChunk) do
        playerChunk[coordStr] = false
    end

    for x = -self.LoadDistance, self.LoadDistance do
        for z = -self.LoadDistance, self.LoadDistance do
            local coordStr = tostring(currentChunk.X + x)..":"..tostring(currentChunk.Z + z)
            playerChunk[coordStr] = true
            if not self.ActiveChunks[coordStr] then
                local curChunkPlayers = {}
                curChunkPlayers[player] = true
                self.ActiveChunks[coordStr] = {curChunkPlayers = curChunkPlayers}
            else
                if not self.ActiveChunks[coordStr].curChunkPlayers[player] then
                    self.ActiveChunks[coordStr].curChunkPlayers[player] = true
                end
            end

            if not self.ActiveChunks[coordStr].isFillBlock then
                local chunkPos = Vector3.new(
                    currentChunk.X * self.ChunkSize + x * self.ChunkSize,
                    -self.Depth / 2,
                    currentChunk.Z * self.ChunkSize + z * self.ChunkSize
                )
                self:FillBlock(chunkPos)
                self.ActiveChunks[coordStr].isFillBlock = true
            end
        end
    end

    for coordStr, value in pairs(playerChunk) do
        if value == false then
            self.ActiveChunks[coordStr].curChunkPlayers[player] = nil
            if next(self.ActiveChunks[coordStr].curChunkPlayers) == nil then
                local x, z = coordStr:match("([%-%d]+):([%-%d]+)")
                local chunkPos = Vector3.new(x * self.ChunkSize, -self.Depth / 2, z * self.ChunkSize)
                self:RemoveBlock(chunkPos)
                self.ActiveChunks[coordStr] = nil
            end
            playerChunk[coordStr] = nil
        end
    end
    self.PlayerChunks[player] = playerChunk
end

function TerrainGenerationService.Client:ChangeChunk(player, currentChunk)
    if not player.Character then
        return
    end

    self.Server:UpdateChunk(player, currentChunk)
end

function TerrainGenerationService:KnitInit()
    Players.PlayerAdded:Connect(function(player)
        self.PlayerChunks[player] = {}
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        for coordStr, value in pairs(self.PlayerChunks[player]) do
            if self.ActiveChunks[coordStr] and self.ActiveChunks[coordStr].curChunkPlayers then
                if next(self.ActiveChunks[coordStr].curChunkPlayers) == nil then
                    local x, z = coordStr:match("([%-%d]+):([%-%d]+)")
                    local chunkPos = Vector3.new(x * self.ChunkSize, -self.Depth / 2, z * self.ChunkSize)
                    self:RemoveBlock(chunkPos)
                    self.ActiveChunks[coordStr] = nil
                end
            end
        end
        self.PlayerChunks[player] = nil
    end)
end

function TerrainGenerationService:KnitStart()
end

return TerrainGenerationService