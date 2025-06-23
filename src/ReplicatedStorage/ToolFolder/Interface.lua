local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('GameConfig'))
local IslandConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("IslandConfig"))

local Interface = {}

-- 初始化玩家位置
function Interface.InitPlayerPos(player)
    local curAreaTemplate = player:GetAttribute("CurAreaTemplate")
    local area = nil
    if curAreaTemplate then
        area = workspace:FindFirstChild(curAreaTemplate)
    end

    local spawnLocation = nil
    if area then
        spawnLocation = area:WaitForChild("SpawnLocation")
    end

    if not spawnLocation then
        spawnLocation = player.RespawnLocation
    end

    if spawnLocation and player.Character then
        local humanoid = player.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = false
        end
        task.wait(0.2)
        player.Character:PivotTo(spawnLocation.CFrame + Vector3.new(math.random(5, 10), 6, math.random(5, 10)))
        return spawnLocation.Parent.Name
    end
    return nil
end

-- 初始化船的位置
-- 初始化船只在水中的位置，让船头朝向海的方向
function Interface.InitBoatWaterPos(player, boat)
    local curAreaTemplate = player:GetAttribute("CurAreaTemplate")
    local area = nil
    if curAreaTemplate then
        area = workspace:FindFirstChild(curAreaTemplate)
    end

    local spawnLocation = nil
    if area then
        spawnLocation = area:WaitForChild("SpawnLocation")
    end

    if not spawnLocation then
        spawnLocation = player.RespawnLocation
    end
    player:SetAttribute("CurAreaTemplate", nil)
    if spawnLocation and player.Character then
        local oldCFrame = boat:GetPivot()
        print("oldCFrame    ", oldCFrame)
        local land = spawnLocation.Parent
        local floor = land:FindFirstChild("Floor")
        if not floor then
            return
        end
        local minPosX = floor.Position.X - floor.Size.X / 2
        local maxPosX = floor.Position.X + floor.Size.X / 2
        local minPosZ = floor.Position.Z - floor.Size.Z / 2
        local maxPosZ = floor.Position.Z + floor.Size.Z / 2
        local randomPosX = math.random(-GameConfig.LandWharfDis, GameConfig.LandWharfDis)
        local randomPosZ = math.random(-GameConfig.LandWharfDis, GameConfig.LandWharfDis)
        local x = 0
        local z = 0
        if randomPosX < 0 then
            x = minPosX + randomPosX - 30
        else
            x = maxPosX + randomPosX + 30
        end
        if randomPosZ < 0 then
            z = minPosZ + randomPosZ - 30
        else
            z = maxPosZ + randomPosZ + 30
        end
        -- 使用适当的水面高度，而不是0
        local waterLevel = 20 -- 根据oldCFrame的Y坐标设置合适的水面高度
        local newPos = Vector3.new(x, waterLevel, z)
        print("newPos    ", newPos)

        -- 计算从码头指向远离岛屿的方向向量（确保是水平方向）
        local floorPosAtWaterLevel = Vector3.new(floor.Position.X, waterLevel, floor.Position.Z)
        local directionToSea = (newPos - floorPosAtWaterLevel).Unit
        print("directionToSea    ", directionToSea)
        
        -- 计算船只应该面向的角度（Y轴旋转）
        local angle = math.atan2(directionToSea.X, directionToSea.Z)
        print("angle    ", angle)
        
        -- 根据船只默认朝向重新计算旋转
        -- 船只默认(0,0,0)时：船底朝向Z轴前方向，船头朝向Y轴下方向
        -- 使用X轴旋转90度让船头从Y轴下转向Z轴前方，然后Y轴旋转调整朝向
        local newCFrame = CFrame.new(newPos) * CFrame.Angles(math.rad(90), angle + math.rad(-90), 0)
        print("newCFrame    ", newCFrame)
        boat:PivotTo(newCFrame)
    
        -- 玩家登船
        Interface.PlayerToBoat(player, boat)
    end
end

-- 玩家登船
function Interface.PlayerToBoat(player, boat)
    if not player or not player.Character or not boat then
        return
    end

    -- 玩家入座
    local driverSeat = boat:FindFirstChild('DriverSeat')
    if driverSeat then
        player.Character:PivotTo(driverSeat.CFrame)
    end
end

-- 通过玩家ID获取船
function Interface.GetBoatByPlayerUserId(userId)
    return workspace:FindFirstChild('PlayerBoat_' .. userId)
end

-- 判断是否在陆地上
function Interface.IsInLand(boat)
    local landConfig = IslandConfig.IsLand
    local pos = boat.PrimaryPart.Position
    for _, landData in ipairs(landConfig) do
        local land = workspace:WaitForChild(landData.Name):WaitForChild("Floor")
        local min = land.Position - land.Size / 2
        local max = land.Position + land.Size / 2
        if pos.X >= min.X and pos.X <= max.X and pos.Z >= min.Z and pos.Z <= max.Z then
            return true
        end
    end

    return false
end

function Interface.CreateIsLandOwnerModel(userId)
    local success, model = pcall(function()
        if userId <= 0 then
            return Players:CreateHumanoidModelFromUserId(7689724124)
        end
        return Players:CreateHumanoidModelFromUserId(userId)
    end)
    
    if success then
        return model
    else
        warn('无法创建玩家模型: ' .. tostring(model))
        return nil
    end
end

-- 获取模型底部位置
function Interface.GetPartBottomPos(model, targetPosition)
    -- 获取模型的包围盒
    local cf, size
    if model:IsA("Model") then
        cf, size = model:GetBoundingBox()
    elseif model:IsA("BasePart") then
        size = model.Size
    end
    
    if not size then
        return
    end
    -- 计算模型底部到中心的距离
    local bottomOffset = size.Y / 2
    
    -- 设置模型位置，Y坐标为地面高度加上底部偏移
    local groundY = targetPosition.Y -- 岛屿地面的Y坐标
    local newPosition = Vector3.new(
        targetPosition.X,
        groundY + bottomOffset,
        targetPosition.Z
    )
    
    return newPosition
end

return Interface