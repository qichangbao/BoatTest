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

local _params = OverlapParams.new()
_params.FilterType = Enum.RaycastFilterType.Include
for _, land in pairs(workspace:GetChildren()) do
    if land:IsA("BasePart") and land.Name:match("Land") then
        _params:AddToFilter(land)
    end
end
-- 判断是否在陆地上
function Interface.IsInLand(boat)
    -- local boatPivot = boat.PrimaryPart:GetPivot()
    -- local size = boat.PrimaryPart.Size
    -- -- 调试绘图
    -- local debugPart = Instance.new('Part')
    -- debugPart.Size = size

    -- -- 根据船体旋转计算实际检测位置
    -- local rotatedPos = boatPivot:PointToWorldSpace()
    
    -- -- 使用定向包围盒检测
    -- local orientation = boatPivot.Rotation
    -- local params = OverlapParams.new()
    -- params.FilterType = Enum.RaycastFilterType.Include
    -- params.CollisionGroup = "Water"
    
    -- local parts = workspace:GetPartBoundsInBox(
    --     CFrame.new(rotatedPos) * orientation,
    --     size,
    --     params
    -- )
    -- debugPart.CFrame = CFrame.new(rotatedPos)-- * orientation
    -- debugPart.Transparency = 0.7
    -- debugPart.Color = Color3.new(1, 0, 0)
    -- debugPart.Anchored = true
    -- debugPart.CanCollide = false
    -- debugPart.Parent = workspace

    local pos = boat.PrimaryPart.Position
    local size = boat.PrimaryPart.Size
    local parts = workspace:GetPartBoundsInBox(CFrame.new(pos - size / 2), size, _params)
    -- local parts = workspace:GetPartBoundsInBox(CFrame.new(pos), size, _params)
    -- debugPart.Color = #parts > 0 and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    
    return #parts > 0
end

return Interface