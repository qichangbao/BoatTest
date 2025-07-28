local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local IslandConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("IslandConfig"))

-- -- 初始化岛屿
-- for _, landData in pairs(IslandConfig.IsLand) do
--     if landData.Name == "奥林匹斯" then
--         continue
--     end
--     local isLand = ServerStorage:WaitForChild(landData.ModelName):Clone()
--     isLand.Name = landData.Name
--     isLand:PivotTo(CFrame.new(landData.Position))
--     isLand.Parent = workspace
-- end

local TerrainGenerationService = Knit.CreateService({
    Name = 'TerrainGenerationService',
    Client = {
        RequestChunks = Knit.CreateSignal(),
    },
    ChunkSize = GameConfig.Water.ChunkSize,
    Depth = GameConfig.Water.Depth,
    LoadDistance = GameConfig.Water.LoadDistance,
    ActiveChunks = {},
    PlayerChunks = {},
})

function TerrainGenerationService:FillBlock(position)
    task.spawn(function()
        if game.Workspace.Terrain then
            game.Workspace.Terrain:FillBlock(
                CFrame.new(position),
                Vector3.new(self.ChunkSize, self.Depth, self.ChunkSize),
                Enum.Material.Water
            )
        end
    end)
end

function TerrainGenerationService:RemoveBlock(position)
    task.spawn(function()
        if game.Workspace.Terrain then
            game.Workspace.Terrain:FillBlock(
                CFrame.new(position),
                Vector3.new(self.ChunkSize, self.Depth, self.ChunkSize),
                Enum.Material.Air
            )
        end
    end)
end

function TerrainGenerationService:UpdateChunk(player, currentChunk)
    local playerChunk = self.PlayerChunks[player] or {}
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