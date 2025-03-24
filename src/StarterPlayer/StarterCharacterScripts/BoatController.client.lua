-- 船只控制系统模块
-- 模块功能：实现船只物理模拟、玩家乘船控制逻辑
-- 作者：Trea
-- 版本：1.0 (2024-02-20)
-- 修改历史：
--   [+] 初始版本 实现基础浮力与移动控制

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
local remoteEvent = ReplicatedStorage:WaitForChild(BOAT_CONTROL_RE_NAME)

local BOAT_BUOYANCY_FORCE = 1500
local BOAT_WATER_DRAG = 0.5
local BOAT_MOVE_SPEED = 10

local function createFloatingPart(part)
    part.Anchored = false  -- 确保物理模拟生效
    
    -- 添加动态浮力（根据水面高度）
    local waterLevel = 10  -- 待替换为实际水面检测
    local submergeDepth = math.max(0, waterLevel - part.Position.Y)
    
    local buoyancy = Instance.new('BodyForce')
    buoyancy.Force = Vector3.new(0, submergeDepth * BOAT_BUOYANCY_FORCE, 0)
    buoyancy.Parent = part
    
    -- 添加二次水阻力
    local drag = Instance.new('BodyForce')
    RunService.Heartbeat:Connect(function()
        local velocity = part.AssemblyLinearVelocity
        drag.Force = -velocity * velocity.Magnitude * BOAT_WATER_DRAG
    end)
    drag.Parent = part
end

-- 绑定玩家到船只
-- @param boatModel: Model 船只模型
-- @param humanoid: Humanoid 玩家角色
-- @return void
local function attachToBoat(boatModel, humanoid)
    humanoid.Sit = true
    humanoid.SeatPart = boatModel:FindFirstChild('DriverSeat')
    
    if boatModel:FindFirstChild('BoatController') then
        return
    end

    local controller = Instance.new('Script')
    controller.Name = 'BoatController'

    local moveVector = Vector3.new()

    script.Changed:Connect(function()
        for _, part in ipairs(boatModel:GetChildren()) do
            if part:IsA('BasePart') then
                createFloatingPart(part)
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        remoteEvent:FireServer(boatModel, moveVector)
        for _, part in ipairs(boatModel:GetChildren()) do
            if part:IsA('BasePart') then
                part:ApplyImpulse(Vector3.new(moveVector.X, 0, moveVector.Z) * BOAT_MOVE_SPEED * dt)
            end
        end
    end)
    
    controller.Parent = boatModel

    controller.ChildAdded:Connect(function(part)
        if part:IsA('BasePart') then
            createFloatingPart(part)
        end
    end)
end

return {
    attachToBoat = attachToBoat
}