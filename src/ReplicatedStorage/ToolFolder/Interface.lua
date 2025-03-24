local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interface = {}

-- 初始化玩家位置
function Interface:InitPlayerPos(player)
    local function initCharacterPos(character)
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local landSpawn = workspace:WaitForChild("LandSpawnLocation")
        local height = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('GameConfig')).TerrainType.Land.Height
        local position = landSpawn.Position
        humanoidRootPart.CFrame = CFrame.new(Vector3.new(position.X, height + 6, position.Z))
    end

    -- 初始化已存在的角色
    if player.Character then
        initCharacterPos(player.Character)
    else
        player.CharacterAdded:Connect(initCharacterPos)
        player.CharacterRemoving:Connect(initCharacterPos)
    end
end

-- 初始化船的位置
function Interface:InitBoatWaterPos(character, boat, driverSeat)
    local waterSpawn = workspace:WaitForChild('WaterSpawnLocation')
    local height = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('GameConfig')).TerrainType.Water.Height
    local position = waterSpawn.Position

    local currentCFrame = boat:GetPivot()
    local newPosition = Vector3.new(position.X, height + boat:GetExtentsSize().Y / 2, position.Z)
    local newCFrame = CFrame.new(newPosition) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
    boat:PivotTo(newCFrame)

    -- 玩家自动入座
    if character then
        local humanoid = character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = true
            character:WaitForChild('HumanoidRootPart').CFrame = driverSeat.CFrame * CFrame.new(0, 2, 0)
        end
    end
end

return Interface