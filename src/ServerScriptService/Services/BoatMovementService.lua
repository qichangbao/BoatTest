local Players = game:GetService('Players')
local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit.Knit)

local BoatMovementService = Knit.CreateService({
    Name = 'BoatMovementService',
    Client = {
        isOnBoat = Knit.CreateSignal(),
    },
    VelocityForce = 15,
    AngularVelocity = 1, -- 降低角速度值，使用更合理的恒定旋转速度
    MaxSpeed = 25,
    HeartbeatHandle = nil,
    Boats = {},
    AngularDamping = 0.75, -- 降低角速度阻尼系数，使停止更平滑
    LinearDamping = 0.85, -- 调整线性阻尼系数，使船更快停止
})

function BoatMovementService:ApplyVelocity(primaryPart, direction)
    local boatBodyVelocity = primaryPart:FindFirstChild("BoatBodyVelocity")
    -- 处理停止移动的情况
    if direction == Vector3.new(0, 0, 0) then
        boatBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        return
    end

    -- 使用船头方向作为前进方向
    local forwardDirection = primaryPart.CFrame.LookVector
    local worldDirection = forwardDirection * direction.Z

    -- 独立限制速度
    local speed = math.clamp(math.abs(direction.Z) * self.VelocityForce, 0, self.MaxSpeed)
    boatBodyVelocity.Velocity = worldDirection * speed
end

function BoatMovementService:ApplyAngular(primaryPart, direction)
    local bodyAngularVelocity = primaryPart:FindFirstChild("BoatBodyAngularVelocity")
    
    -- 当方向为0时完全停止旋转
    if direction == Vector3.new(0, 0, 0) then
        -- 立即停止旋转，增加更强的反向力矩来抵消现有角动量
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        
        -- -- 应用一个短暂的反向力矩来抵消现有角动量
        -- local currentAngularVelocity = primaryPart.AssemblyAngularVelocity
        -- if currentAngularVelocity.Magnitude > 0.1 then
        --     -- 创建一个反向的角速度来快速停止旋转
        --     bodyAngularVelocity.AngularVelocity = -currentAngularVelocity * 0.5
        --     -- 使用task.delay在短时间后重置为零
        --     task.delay(0.05, function()
        --         if bodyAngularVelocity and bodyAngularVelocity.Parent then
        --             bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        --         end
        --     end)
        -- end
        return
    end
    
    -- 应用固定角速度，使用恒定值
    local angularSpeed = math.sign(direction.Z) * self.AngularVelocity
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, angularSpeed, 0)
end

function BoatMovementService:StabilizeBoat(primaryPart)
    -- 获取当前船体的角速度和线性速度
    local currentLinearVelocity = primaryPart.AssemblyLinearVelocity
    local currentAngularVelocity = primaryPart.AssemblyAngularVelocity
    
    -- 创建或获取必要的物理组件
    local bodyAngularVelocity = primaryPart:FindFirstChild("BoatBodyAngularVelocity")
    local boatBodyVelocity = primaryPart:FindFirstChild("BoatBodyVelocity")
    
    -- 创建或获取稳定用的AlignOrientation和Attachment
    local originAttachment = primaryPart:FindFirstChild("OriginAttachment") or Instance.new("Attachment")
    originAttachment.Name = "OriginAttachment"
    originAttachment.Parent = primaryPart
    
    local targetAttachment = primaryPart:FindFirstChild("TargetAttachment") or Instance.new("Attachment")
    targetAttachment.Name = "TargetAttachment"
    targetAttachment.Parent = primaryPart
    
    -- 更新目标附件方向（只保留Y轴旋转）
    local _, yRot, _ = primaryPart.CFrame:ToEulerAnglesYXZ()
    targetAttachment.CFrame = CFrame.Angles(0, yRot, 0)
    
    -- 创建或配置AlignOrientation
    local alignOrientation = primaryPart:FindFirstChild("BoatAlignOrientation") or Instance.new("AlignOrientation")
    alignOrientation.Name = "BoatAlignOrientation"
    alignOrientation.MaxTorque = 8000000  -- 更强的力矩
    alignOrientation.MaxAngularVelocity = 400  -- 更高的角速度限制
    alignOrientation.Responsiveness = 1500  -- 更快的响应
    alignOrientation.RigidityEnabled = true
    alignOrientation.Attachment0 = originAttachment
    alignOrientation.Attachment1 = targetAttachment
    alignOrientation.Parent = primaryPart

    -- 浮力修正（保持在水面上）
    local waterLevel = 0
    local idealHeight = waterLevel + 1.2
    local heightDiff = idealHeight - primaryPart.Position.Y
    
    -- 应用更真实的水面阻尼效果
    if boatBodyVelocity then
        -- 使用服务参数中的阻尼系数
        -- 非线性动态阻尼计算
        local speedFactor = math.clamp(currentLinearVelocity.Magnitude / self.MaxSpeed, 0.1, 1.5)
        local dynamicDamping = self.LinearDamping * (0.8 + speedFactor * 0.4)
        
        boatBodyVelocity.Velocity = Vector3.new(
            currentLinearVelocity.X * dynamicDamping * (1 - math.abs(currentLinearVelocity.X)/self.MaxSpeed),
            currentLinearVelocity.Y * (dynamicDamping * 0.6) * (1 - math.abs(currentLinearVelocity.Y)/3),
            currentLinearVelocity.Z * dynamicDamping * (1 - math.abs(currentLinearVelocity.Z)/self.MaxSpeed)
        )
        
        
        if math.abs(heightDiff) > 0.05 then  -- 更敏感的浮力修正
            -- 使用更平滑的浮力过渡
            local buoyancyFactor = math.clamp(heightDiff * 0.6, -0.25, 0.25)  -- 减小浮力修正幅度
            boatBodyVelocity.Velocity = boatBodyVelocity.Velocity + Vector3.new(0, buoyancyFactor, 0)
        end
        print("LinearVelocity: ", currentLinearVelocity)
        print("CurLinearVelocity: ", boatBodyVelocity.Velocity)
    end
    
    -- 应用角速度阻尼
    if bodyAngularVelocity then
        -- 使用服务参数中的角速度阻尼和稳定力
        -- 角速度动态阻尼
        local angularSpeedFactor = math.clamp(currentAngularVelocity.Magnitude, 0.5, 3.0)
        local angularDamping = self.AngularDamping * (0.7 + angularSpeedFactor * 0.3)
        
        bodyAngularVelocity.AngularVelocity = Vector3.new(
            currentAngularVelocity.X * angularDamping * 0.8,
            bodyAngularVelocity.AngularVelocity.Y * angularDamping * 1.2,  -- 增强Y轴稳定
            currentAngularVelocity.Z * angularDamping * 0.8
        )
        
        -- 应用渐进式反向力矩来平滑停止摇晃
        if currentAngularVelocity.Magnitude > 0.01 then
            -- 动态线性阻尼系数（基于当前速度）
            local speedFactor = math.clamp(currentLinearVelocity.Magnitude / self.MaxSpeed, 0.1, 1.2)
            local linearDamping = self.LinearDamping * (0.9 + speedFactor * 0.3)
            
            -- 应用速度相关的非线性阻尼
            local velocityDamping = Vector3.new(
                currentLinearVelocity.X * linearDamping * (1 - math.abs(currentLinearVelocity.X)/self.MaxSpeed),
                currentLinearVelocity.Y * (linearDamping * 0.8) * (1 - math.abs(currentLinearVelocity.Y)/2),
                currentLinearVelocity.Z * linearDamping * (1 - math.abs(currentLinearVelocity.Z)/self.MaxSpeed)
            )
            boatBodyVelocity.Velocity = velocityDamping
            
            -- 非线性浮力修正（带死区）
            heightDiff = idealHeight - primaryPart.Position.Y  -- 重新计算当前高度差
            if math.abs(heightDiff) > 0.02 then
                local buoyancyCurve = math.sin(math.clamp(math.abs(heightDiff)*5, 0, math.pi/2))
                local buoyancyFactor = math.sign(heightDiff) * buoyancyCurve * 0.35
                boatBodyVelocity.Velocity = boatBodyVelocity.Velocity + Vector3.new(0, buoyancyFactor, 0)
            end
            print("AngularVelocity: ", currentAngularVelocity)
            print("CurAngularVelocity: ", bodyAngularVelocity.AngularVelocity)
        end
    end
end

function BoatMovementService:ApplyMovement(primaryPart, direction, angular)
    -- 应用物理效果到船体
    self:ApplyAngular(primaryPart, angular)
    self:ApplyVelocity(primaryPart, direction)
    
    -- 如果没有输入，应用稳定功能
    if direction.Magnitude < 0.1 and angular.Magnitude < 0.1 then
        self:StabilizeBoat(primaryPart)
    end
end

function BoatMovementService:OnBoat(player, isOnBoat)
    if isOnBoat then
        self.Boats[player] = {direction = Vector3.new(), angular = Vector3.new(), hasPlayer = true}
        local boat = workspace:FindFirstChild("PlayerBoat_"..player.UserId)
        local driverSeat = boat:FindFirstChild('DriverSeat')
        local handle
        handle = driverSeat:GetPropertyChangedSignal('Occupant'):Connect(function()
            if not self.Boats[player] then
                handle:Disconnect()
                return
            end
            local occupant = driverSeat.Occupant
            -- 玩家从座位上移除时（跳起）
            if not occupant then
                self.Boats[player].direction = Vector3.new()
                self.Boats[player].angular = Vector3.new()
                self.Boats[player].hasPlayer = false
                return
            else
                self.Boats[player].hasPlayer = true
            end
        end)
    else
        self.Boats[player] = nil
    end
    self.Client.isOnBoat:Fire(player, isOnBoat)
end

function BoatMovementService.Client:UpdateMovement(player, direction, angular)
    if not self.Server.Boats[player] or not self.Server.Boats[player].hasPlayer then
        print("玩家不在船座上   ", player.Name)
        return
    end

    self.Server.Boats[player] = {direction = direction, angular = angular, hasPlayer = true}
end

function BoatMovementService:KnitInit()
    print('BoatMovementService Initialized')
    -- 初始化心跳事件
    game:GetService('RunService').Heartbeat:Connect(function()
        for player, data in pairs(self.Boats) do
            local boat = workspace:FindFirstChild("PlayerBoat_"..player.UserId)
            if not boat then
                self.Boats[player] = nil
                continue
            end

            local primaryPart = boat.PrimaryPart
            if not primaryPart then
                self.Boats[player] = nil
                print("船只 "..boat.Name.." 缺少PrimaryPart")
                continue
            end

            self:ApplyMovement(primaryPart, data.direction, data.angular)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        print("玩家 "..player.Name.." 退出游戏，移除玩家船数据")
        self.Boats[player] = nil
    end)
end

function BoatMovementService:KnitStart()
    print('BoatMovementService Started')
end

return BoatMovementService