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

function BoatMovementService:ApplyVelocity(player, direction)
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    local playerBoat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not playerBoat then
        return "船不存在，不能移动"
    end
    
    local rootPart = character.PrimaryPart
    if not rootPart then return end

    local boatBodyVelocity = rootPart:FindFirstChild("BoatBodyVelocity")
    -- 处理停止移动的情况
    if not direction then
        -- 通过船只实例移除约束
        if boatBodyVelocity then
            boatBodyVelocity.Velocity = Vector3.new(0, 0, 0)
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

    -- 前後移動
    local localDirection = direction or Vector3.new(0,0,1)
    local worldDirection = rootPart.CFrame.LookVector * localDirection.Z
    boatBodyVelocity.Velocity = worldDirection * self.VelocityForce

    -- 獨立限制各軸速度
    local limitedVelocity = Vector3.new(
        math.clamp(boatBodyVelocity.Velocity.X, -self.MaxSpeed, self.MaxSpeed),
        0,
        math.clamp(boatBodyVelocity.Velocity.Z, -self.MaxSpeed, self.MaxSpeed)
    )
    
    boatBodyVelocity.Velocity = limitedVelocity
end

function BoatMovementService:ApplyAngular(player, direction)
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    local playerBoat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not playerBoat then
        return "船不存在，不能移动"
    end
    
    local rootPart = character.PrimaryPart
    if not rootPart then return end

    local bodyAngularVelocity = rootPart:FindFirstChild("BoatBodyAngularVelocity")
    -- 处理停止移动的情况
    if not direction then
        if bodyAngularVelocity then
            bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
            --bodyAngularVelocity:Destroy()
        end
        return
    end
    
    if not bodyAngularVelocity then
        bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.Name = "BoatBodyAngularVelocity"
        bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
        bodyAngularVelocity.P = 2500
        bodyAngularVelocity.Parent = rootPart
    end
    -- 左右轉向（僅在Y軸施加扭矩）
    -- 角速度参数已迁移到组件初始化时设置
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, direction.Z * self.AngularVelocity, 0)
    print('【调试】旋转输入:', 'Z轴='..direction.Z, '角速度:', bodyAngularVelocity.AngularVelocity.Y)
end

function BoatMovementService.Client:UpdateVelocity(player, direction)
    self.Server:ApplyVelocity(player, direction)
end

function BoatMovementService.Client:UpdateAngular(player, direction)
    self.Server:ApplyAngular(player, direction)
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