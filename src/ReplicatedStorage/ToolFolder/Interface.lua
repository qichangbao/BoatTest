local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('GameConfig'))

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
        local landData = GameConfig.FindIsLand(land.Name)
        if not landData then
            landData = GameConfig.FindIsLand("奥林匹斯")
        end

        -- 获取原始CFrame的旋转部分
        local rotation = landData.WharfOutOffsetPos - landData.WharfOutOffsetPos.Position
        local newCFrame = CFrame.new(
            landData.Position.X + landData.WharfOutOffsetPos.Position.X,
            landData.WharfOutOffsetPos.Position.Y,
            landData.Position.Z + landData.WharfOutOffsetPos.Position.Z
        ) * rotation
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
    local landConfig = GameConfig.IsLand
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

return Interface