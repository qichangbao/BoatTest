local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local PhysicsService = game:GetService('PhysicsService')
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local BOAT_PARTS_FOLDER_NAME = '船'
local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]

local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
local MOVEMENT_FORCE = 1500
local TURN_TORQUE = 80000

local controlEvent = ReplicatedStorage:WaitForChild(BOAT_CONTROL_RE_NAME)
local activeBoats = {}

local function createPhysicsObjects(boatModel)
    local boatBase = boatModel
    
    local velocity = Instance.new('LinearVelocity')
    velocity.LineVelocity = 0
    velocity.MaxForce = 4000
    velocity.Parent = boatBase
    
    local angularVelocity = Instance.new('AngularVelocity')
    angularVelocity.AngularVelocity = Vector3.new()
    angularVelocity.MaxTorque = 80000
    angularVelocity.Parent = boatBase
    
    return velocity, angularVelocity
end

controlEvent.OnServerEvent:Connect(function(player, direction, state)
    local boat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not boat then return end
    
    local controlData = activeBoats[boat] or {
        velocity = nil,
        angular = nil,
        connections = {}
    }
    
    if not controlData.velocity then
        controlData.velocity, controlData.angular = createPhysicsObjects(boat)
        activeBoats[boat] = controlData
    end
    
    local forceMultiplier = state and 10000 or 0
    local baseForce = MOVEMENT_FORCE * forceMultiplier
    local baseTorque = TURN_TORQUE * forceMultiplier
    
    if direction == 'Forward' then
        controlData.velocity.LineVelocity = -baseForce
    elseif direction == 'Backward' then
        controlData.velocity.LineVelocity = baseForce
    elseif direction == 'Left' then
        controlData.angular.AngularVelocity = Vector3.new(0, baseTorque, 0)
    elseif direction == 'Right' then
        controlData.angular.AngularVelocity = Vector3.new(0, -baseTorque, 0)
    end
    
    -- 持续运动更新循环
    if not controlData.connections.updateLoop then
        controlData.connections.updateLoop = RunService.Heartbeat:Connect(function()
            if not boat.Parent then
                controlData.velocity:Destroy()
                controlData.angular:Destroy()
                activeBoats[boat] = nil
                return
            end
            
            -- 应用水面阻力模拟
            controlData.velocity.LineVelocity *= 1.0  -- 临时移除线性阻力
            controlData.angular.AngularVelocity *= 0.98
        end)
    end
end)

-- 清理物理组件当驾驶座释放时
game:GetService('Players').PlayerRemoving:Connect(function(player)
    local boat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if boat and activeBoats[boat] then
        activeBoats[boat].velocity:Destroy()
        activeBoats[boat].angular:Destroy()
        if activeBoats[boat].connections.updateLoop then
            activeBoats[boat].connections.updateLoop:Disconnect()
        end
        activeBoats[boat] = nil
    end
end)