local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interface = {}

-- 初始化玩家位置
function Interface:InitPlayerPos(player)
    local spawnLocation = player.RespawnLocation
    if spawnLocation and player.Character then
        local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = spawnLocation.CFrame
        end
        local humanoid = player.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = false
        end
    end
end

-- 初始化船的位置
function Interface:InitBoatWaterPos(character, boat, driverSeat)
    local waterSpawn = workspace:WaitForChild('WaterSpawnLocation')
    local position = waterSpawn.Position

    local currentCFrame = boat:GetPivot()
    local newPosition = Vector3.new(position.X, position.Y + boat.PrimaryPart.size.y, position.Z)
    local newCFrame = CFrame.new(newPosition) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
    --local newCFrame = CFrame.new(Vector3.new(0, newPosition.Y, 0))
    boat:PivotTo(newCFrame)

    -- 玩家自动入座
    if character then
        local humanoid = character:FindFirstChild('Humanoid')
        if humanoid then
            --humanoid.Sit = true
            character:WaitForChild('HumanoidRootPart').CFrame = boat.PrimaryPart.CFrame * CFrame.new(0, 2, 0)
        end
    end
end

return Interface