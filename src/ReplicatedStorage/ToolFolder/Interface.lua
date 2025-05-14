local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('GameConfig'))

local Interface = {}

-- 初始化玩家位置
function Interface.InitPlayerPos(player)
    local spawnLocation = player.RespawnLocation
    if spawnLocation and player.Character then
        local humanoid = player.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = false
        end
        task.wait(0.1)
        player.Character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 6, 0))
    end
end

-- 初始化船的位置
function Interface.InitBoatWaterPos(player, boat)
    local spawnLocation = player.RespawnLocation
    if spawnLocation and player.Character then
        local boatInitPos = spawnLocation.Parent:WaitForChild('BoatInitPos')
        local position = boatInitPos.Value
    
        local currentCFrame = boat:GetPivot()
        local newPosition = Vector3.new(position.X, position.Y + boat.PrimaryPart.size.y, position.Z)
        local newCFrame = CFrame.new(newPosition) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
        boat:PivotTo(newCFrame)
    
        -- 玩家自动入座
        local driverSeat = boat:FindFirstChild('DriverSeat')
        player.character:PivotTo(driverSeat.CFrame)
    end
end

-- 通过玩家ID获取船
function Interface.GetBoatByPlayerUserId(userId)
    return workspace:FindFirstChild('PlayerBoat_' .. userId)
end

-- 判断是否在陆地上
function Interface.IsInLand(boat)
    local landConfig = GameConfig.TerrainType.Land
    local pos = boat.PrimaryPart.Position
    for _, landName in pairs(landConfig) do
        local land = workspace:WaitForChild(landName):WaitForChild("Floor")
        local min = land.Position - land.Size / 2
        local max = land.Position + land.Size / 2
        if pos.X >= min.X and pos.X <= max.X and pos.Z >= min.Z and pos.Z <= max.Z then
            return true
        end
    end

    return false
end

return Interface