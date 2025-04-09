local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit.Knit)
local PhysicsService = game:GetService('PhysicsService')

local BoatMovementService = Knit.CreateService({
    Name = 'BoatMovementService',
    Client = {
        isOnBoat = Knit.CreateSignal(),
    },
    VelocityForce = 15,
    AngularVelocity = 2,
    MaxSpeed = 25,
})

function BoatMovementService:ApplyMovement(player, direction)
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    local playerBoat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not playerBoat then
        return "船不存在，不能移动"
    end
    
    local rootPart = character.PrimaryPart
    if not rootPart then return end

    local boatBodyVelocity = rootPart:FindFirstChild("BoatBodyVelocity")
    local bodyAngularVelocity = rootPart:FindFirstChild("BodyAngularVelocity")
    -- 处理停止移动的情况
    if direction == Vector3.new(0,0,0) then
        -- 通过船只实例移除约束
        if boatBodyVelocity then
            boatBodyVelocity:Destroy()
        end
        if bodyAngularVelocity then
            bodyAngularVelocity:Destroy()
        end
        return
    end
    
    -- 附加物理约束到船体
    if not boatBodyVelocity then
        boatBodyVelocity = Instance.new("BodyVelocity")
        boatBodyVelocity.Name = "BoatBodyVelocity"
        boatBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        boatBodyVelocity.P = 1250
        boatBodyVelocity.Parent = rootPart
    end
    
    if not bodyAngularVelocity then
        bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.Name = "BoatBodyAngularVelocity"
        bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
        bodyAngularVelocity.P = 2500
        bodyAngularVelocity.Parent = rootPart
    end

    -- 前後移動
    local forwardVector = rootPart.CFrame.LookVector
    boatBodyVelocity.Velocity = forwardVector * direction.X * self.VelocityForce
    
    -- 左右轉向（僅在Y軸施加扭矩）
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, direction.Z * self.AngularVelocity, 0)
    
    -- 獨立限制各軸速度
    local limitedVelocity = Vector3.new(
        math.clamp(boatBodyVelocity.Velocity.X, -self.MaxSpeed, self.MaxSpeed),
        0,
        math.clamp(boatBodyVelocity.Velocity.Z, -self.MaxSpeed, self.MaxSpeed)
    )
    
    boatBodyVelocity.Velocity = limitedVelocity
    print('boatBodyVelocity.Velocity', boatBodyVelocity.Velocity)
    print('bodyAngularVelocity.AngularVelocity', bodyAngularVelocity.AngularVelocity)
end

function BoatMovementService.Client:UpdateMovement(player, direction)
    self.Server:ApplyMovement(player, direction)
end

function BoatMovementService:KnitInit()
    print('BoatMovementService Initialized')
end

function BoatMovementService:KnitStart()
    print('BoatMovementService Started')
    
    -- 移除服务级别的约束初始化
    
    -- PhysicsService:CreateCollisionGroup("Boat")
    -- PhysicsService:CollisionGroupSetCollidable("Boat", "Boat", false)
end

return BoatMovementService