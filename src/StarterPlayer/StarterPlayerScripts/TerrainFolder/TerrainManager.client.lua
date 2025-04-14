--[[
地形管理模块
功能：负责地形生成、岛屿检测和区块资源管理
作者：TRAE
创建日期：2024-03-20
版本历史：
v1.0.0 - 初始版本（2024-03-20）
v1.1.0 - 新增岛屿生成算法（2024-03-25）
]]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

local _lastPlayerChunk = nil
local _chunkSize = GameConfig.TerrainType.Water.ChunkSize

local function UpdateChunks(position)
    local currentChunk = Vector3.new(
        math.floor((position.X + _chunkSize / 2)/ _chunkSize),
        0,
        math.floor((position.Z + _chunkSize / 2) / _chunkSize)
    )
    if _lastPlayerChunk and currentChunk == _lastPlayerChunk then
        return
    end

    _lastPlayerChunk = currentChunk
    local TerrainGenerationService = Knit.GetService('TerrainGenerationService')
    TerrainGenerationService:ChangeChunk(currentChunk):andThen(function()
    end)
end

game:GetService("RunService").RenderStepped:Connect(function()
    if Players.LocalPlayer.Character then
        UpdateChunks(Players.LocalPlayer.Character:GetPivot().Position)
    end
end)