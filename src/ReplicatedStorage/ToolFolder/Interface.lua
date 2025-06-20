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
        local land = spawnLocation.Parent
        local landData = IslandConfig.FindIsLand(land.Name)
        local newCFrame = CFrame.new()
        if landData then
            -- 获取原始CFrame的旋转部分
            local rotation = landData.WharfOutOffsetPos - landData.WharfOutOffsetPos.Position
            newCFrame = CFrame.new(
                landData.Position.X + landData.WharfOutOffsetPos.Position.X,
                landData.WharfOutOffsetPos.Position.Y,
                landData.Position.Z + landData.WharfOutOffsetPos.Position.Z
            ) * rotation
        else
            local WharfOutOffsetPos = area:FindFirstChild("WharfOutOffsetPos").Value
            local rotation = WharfOutOffsetPos - landData.WharfOutOffsetPos.Position
            newCFrame = CFrame.new(
                landData.Position.X + landData.WharfOutOffsetPos.Position.X,
                landData.WharfOutOffsetPos.Position.Y,
                landData.Position.Z + landData.WharfOutOffsetPos.Position.Z
            ) * rotation
        end

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