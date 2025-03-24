-- 船只物理模拟模块
-- 实现浮力系统、水流模拟、玩家船只控制及流体阻力模型
-- 采用二次阻力公式实现速度相关阻尼效果

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local BOAT_BUOYANCY_FORCE = 1500
local BOAT_WATER_DRAG = 0.5
local BOAT_MOVE_SPEED = 10
local WATER_CURRENT_FORCE = Vector3.new(0, 0, -2)

local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
local boatControlEvent = ReplicatedStorage:FindFirstChild(BOAT_CONTROL_RE_NAME)
if not boatControlEvent then
    boatControlEvent = Instance.new('RemoteEvent')
    boatControlEvent.Name = BOAT_CONTROL_RE_NAME
    boatControlEvent.Parent = ReplicatedStorage
end

-- 水位检测函数
-- 原理：向下发射射线检测水面位置
-- 返回水面Y轴坐标，未检测到水面时返回0
local function getWaterLevel(position)
    local ray = Ray.new(position, Vector3.new(0, -1000, 0))
    local hit = workspace:FindPartOnRay(ray)
    return hit and hit.Position.Y or 0
end

-- 船只物理状态更新
-- 计算四大力学效果：
-- 1. 浮力：F_buoyancy = submergeDepth * BOAT_BUOYANCY_FORCE
-- 2. 水流力：F_current = WATER_CURRENT_FORCE * mass
-- 3. 控制力：F_control = moveVector * BOAT_MOVE_SPEED * mass
-- 4. 二次阻力：F_drag = -velocity * |velocity| * BOAT_WATER_DRAG
local function updateBoatPhysics(boatModel, moveVector)
    for _, part in ipairs(boatModel:GetChildren()) do
        if part:IsA('BasePart') then
            local waterLevel = getWaterLevel(part.Position)
            local submergeDepth = math.max(0, waterLevel - part.Position.Y)
            
            -- 应用浮力
            part:ApplyForce(Vector3.new(0, submergeDepth * BOAT_BUOYANCY_FORCE, 0))  -- 浮力公式：F = ρ * g * V (ρg=1500)
            
            -- 应用水流方向力
            part:ApplyForce(WATER_CURRENT_FORCE * part.Mass)
            
            -- 应用玩家控制力
            local velocity = part.AssemblyLinearVelocity
            part:ApplyForce(Vector3.new(moveVector.X, 0, moveVector.Z) * BOAT_MOVE_SPEED * part.Mass)
            
            -- 二次水阻力
            part:ApplyForce(-velocity * velocity.Magnitude * BOAT_WATER_DRAG)  -- 二次阻力模型：F = -k * v * |v|
        end
    end
end

-- 远程事件处理
-- 接收客户端发送的船只控制指令
-- 参数说明：
-- boatModel: 玩家控制的船只模型
-- moveVector: 三维移动向量（XZ平面控制）
boatControlEvent.OnServerEvent:Connect(function(player, boatModel, moveVector)
    updateBoatPhysics(boatModel, moveVector)
end)