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
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

local _lastPlayerChunk = nil
local _chunkSize = GameConfig.Water.ChunkSize
local _depth = GameConfig.Water.Depth
local _loadDistance = GameConfig.Water.LoadDistance
local _floors = {}
local _activeChunks = {}
local Floors = workspace:FindFirstChild("Floors")
if not Floors then
    Floors = Instance.new("Folder")
    Floors.Name = "Floors"
    Floors.Parent = workspace
end

local function GetFloor()
    local part
    if #_floors == 0 then
        part = Instance.new("Part")
        part.Size = Vector3.new(_chunkSize, 1, _chunkSize)
        part.Anchored = true
        part.CanCollide = true
        part.CanQuery = true
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Transparency = 0
        part.Color = Color3.fromRGB(51, 40, 40)
    else
        part = _floors[#_floors]
        table.remove(_floors)
    end
    return part
end

local function FillFloor(currentChunk, coordStr)
    local part = GetFloor()
    part.Name = coordStr
    part.Position = Vector3.new(
        currentChunk.X * _chunkSize,
        -_depth,
        currentChunk.Z * _chunkSize
    )
    part.Parent = Floors
end

local function RemoveFloor(coordStr)
    local part = Floors:FindFirstChild(coordStr)
    if part then
        part.Parent = nil
        table.insert(_floors, part)
    end
end

local function UpdateFloors(currentChunk)
    local newChunks = {}
    for x = -_loadDistance, _loadDistance do
        for z = -_loadDistance, _loadDistance do
            local coord = Vector3.new(currentChunk.X + x, 0, currentChunk.Z + z)
            local coordStr = tostring(currentChunk.X + x)..":"..tostring(currentChunk.Z + z)
            newChunks[coordStr] = true
            
            if not _activeChunks[coordStr] then
                FillFloor(coord, coordStr)
                _activeChunks[coordStr] = true
            end
        end
    end

    for coordStr in pairs(_activeChunks) do
        if not newChunks[coordStr] then
            RemoveFloor(coordStr)
            _activeChunks[coordStr] = nil
        end
    end
end

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
    UpdateFloors(currentChunk)

    local TerrainGenerationService = Knit.GetService('TerrainGenerationService')
    TerrainGenerationService:ChangeChunk(currentChunk):andThen(function()
    end)
end

game:GetService("RunService").RenderStepped:Connect(function()
    if Players.LocalPlayer.Character then
        UpdateChunks(Players.LocalPlayer.Character:GetPivot().Position)
    end
end)