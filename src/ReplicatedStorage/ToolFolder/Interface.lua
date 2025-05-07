local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interface = {}

-- 初始化玩家位置
function Interface.InitPlayerPos(player)
    local spawnLocation = player.RespawnLocation
    if spawnLocation and player.Character then
        player.Character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 6, 0))
        local humanoid = player.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = false
        end
    end
end

-- 初始化船的位置
function Interface.InitBoatWaterPos(character, boat)
    local boatInitPos = workspace:WaitForChild('BoatInitPos')
    local position = boatInitPos.Value

    local currentCFrame = boat:GetPivot()
    local newPosition = Vector3.new(position.X, position.Y + boat.PrimaryPart.size.y, position.Z)
    local newCFrame = CFrame.new(newPosition) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
    boat:PivotTo(newCFrame)

    -- 玩家自动入座
    if character then
        local driverSeat = boat:FindFirstChild('DriverSeat')
        character:PivotTo(driverSeat.CFrame)
    end
end

-- 通过玩家ID获取船
function Interface.GetBoatByPlayerUserId(userId)
    return workspace:FindFirstChild('PlayerBoat_' .. userId)
end

local _params = OverlapParams.new()
_params.FilterType = Enum.RaycastFilterType.Include
for _, land in pairs(workspace:GetChildren()) do
    if land:IsA("BasePart") and land.Name:match("Land") then
        _params:AddToFilter(land)
    end
end
-- 判断是否在陆地上
function Interface.IsInLand(pos, size)
    local parts = workspace:GetPartBoundsInBox(CFrame.new(pos - size / 2), size, _params)
    return #parts > 0
end

return Interface