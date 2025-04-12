local Players = game:GetService('Players')
local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit.Knit)
local PhysicsService = game:GetService('PhysicsService')

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
    StabilizationThreshold = 0.12, -- 进一步降低稳定化阈值，使稳定系统更早启动
    StabilizationForce = 1.5, -- 进一步增加稳定力度，使稳定更快
    StabilizationDamping = 3.0, -- 进一步增加阻尼系数，提供更强的抵消力
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
    -- 获取当前船体的角速度
    local currentAngularVelocity = primaryPart.AssemblyAngularVelocity
    local y = currentAngularVelocity.Y
    -- 只关注Y轴以外的摇晃（侧倾和前后倾）
    local rollPitchVelocity = Vector3.new(currentAngularVelocity.X, 0, currentAngularVelocity.Z)
    
    -- 始终应用基础稳定力，不仅在超过阈值时
    -- 这样可以持续保持船体稳定，防止小幅度累积摇晃
    local curMagnitude = rollPitchVelocity.Magnitude
    
    -- 根据摇晃程度应用不同强度的稳定力，而不是简单地使用if条件判断
    -- 即使摇晃很小，也应用基础稳定力，但强度较低
    local stabilizationMultiplier = 1
    
    -- 如果摇晃超过阈值，增加稳定力强度
    if curMagnitude > self.StabilizationThreshold then
        stabilizationMultiplier = 2 + (curMagnitude / self.StabilizationThreshold) -- 根据摇晃程度动态增加稳定力
    elseif curMagnitude > 0.05 then -- 对于小幅度摇晃，应用较低强度的稳定力
        stabilizationMultiplier = 1 + (curMagnitude / 0.05) * 0.5
    end
    -- 创建或获取稳定用的AlignOrientation和必要的Attachment
    local originAttachment = primaryPart:FindFirstChild("OriginAttachment")
    local targetAttachment = primaryPart:FindFirstChild("TargetAttachment")
    
    -- 如果附件不存在，创建它们
    if not originAttachment then
        originAttachment = Instance.new("Attachment")
        originAttachment.Name = "OriginAttachment"
        originAttachment.Parent = primaryPart
    end
    
    if not targetAttachment then
        targetAttachment = Instance.new("Attachment")
        targetAttachment.Name = "TargetAttachment"
        targetAttachment.Parent = primaryPart
    end
    
    -- 获取当前船体的CFrame
    local boatCFrame = primaryPart.CFrame
    
    -- 提取当前的Y轴旋转（船头方向）
    local _, yRot, _ = boatCFrame:ToEulerAnglesYXZ()
    
    -- 更新源附件位置（保持在船体中心）
    originAttachment.CFrame = CFrame.new()
    
    -- 更新目标附件方向（只保留Y轴旋转，X和Z轴归零）
    targetAttachment.CFrame = CFrame.Angles(0, yRot, 0)
    
    -- 创建或获取AlignOrientation
    local alignOrientation = primaryPart:FindFirstChild("BoatAlignOrientation")
    if not alignOrientation then
        alignOrientation = Instance.new("AlignOrientation")
        alignOrientation.Name = "BoatAlignOrientation"
        alignOrientation.MaxTorque = 200000 -- 大幅增加力矩以更强力地稳定船体
        alignOrientation.MaxAngularVelocity = 12 -- 进一步增加最大角速度以更快地纠正倾斜
        alignOrientation.Responsiveness = 50 -- 大幅提高响应速度，使稳定反应更快
        alignOrientation.RigidityEnabled = true -- 启用刚性以提供更强的稳定性
        alignOrientation.Attachment0 = originAttachment
        alignOrientation.Attachment1 = targetAttachment
        alignOrientation.Parent = primaryPart
    else
        -- 更新现有AlignOrientation的参数
        alignOrientation.MaxTorque = 200000
        alignOrientation.MaxAngularVelocity = 12
        alignOrientation.Responsiveness = 50
    end
    
    local bodyAngularVelocity = primaryPart:FindFirstChild("BoatBodyAngularVelocity")
    -- 应用反向阻尼力来抵消当前角速度，保留Y轴的控制
    -- 使用负号来创建反向力，这样才能真正抵消摇晃
    -- 根据稳定乘数动态调整阻尼系数
    local adjustedDamping = self.StabilizationDamping * stabilizationMultiplier
    
    local dampedVelocity = Vector3.new(
        currentAngularVelocity.X * -adjustedDamping,
        bodyAngularVelocity.AngularVelocity.Y,
        currentAngularVelocity.Z * -adjustedDamping
    )
    
    -- 如果角速度很小，应用更强的反向力来完全停止摇晃
    if curMagnitude < 0.03 then -- 降低微小摇晃的阈值，使系统对更小的摇晃也能响应
        -- 应用比当前角速度更强的反向力来确保完全停止
        dampedVelocity = Vector3.new(
            currentAngularVelocity.X * -10.0, -- 进一步提升反向力系数至10倍彻底消除微小摇晃
            bodyAngularVelocity.AngularVelocity.Y,
            currentAngularVelocity.Z * -10.0
        )
        
        -- 添加角速度归零阈值检测
        if dampedVelocity.Magnitude < 0.015 then -- 进一步降低归零阈值，使系统更容易将微小摇晃归零
            dampedVelocity = Vector3.new(0, bodyAngularVelocity.AngularVelocity.Y, 0)
        end
    end
    
    -- 应用额外的线性稳定力来减少水面波动影响
    local boatBodyVelocity = primaryPart:FindFirstChild("BoatBodyVelocity")
    if boatBodyVelocity then
        -- 获取当前垂直方向的速度
        local verticalVelocity = primaryPart.AssemblyLinearVelocity.Y
        -- 始终应用垂直方向的阻尼力，不仅在速度过大时
        -- 这样可以持续保持船体垂直稳定，防止小幅度波动累积
        local currentVelocity = boatBodyVelocity.Velocity
        
        -- 根据垂直速度大小动态调整阻尼系数
        local verticalDamping = 0.3 -- 增加基础阻尼系数
        if math.abs(verticalVelocity) > 1.0 then
            verticalDamping = 0.7 -- 大幅波动时大幅增加阻尼
        elseif math.abs(verticalVelocity) > 0.5 then
            verticalDamping = 0.5 -- 中等波动时增加中等阻尼
        end
        
        -- 保持水平速度不变，只减弱垂直方向的波动
        boatBodyVelocity.Velocity = Vector3.new(
            currentVelocity.X,
            currentVelocity.Y - (verticalVelocity * verticalDamping),
            currentVelocity.Z
        )
        
        -- 增强浮力计算，使船体更稳定地保持在水面上
        -- 假设水面高度为0
        local waterLevel = 0
        local boatHeight = primaryPart.Position.Y
        local idealHeight = waterLevel + 2 -- 理想的船体高度（水面上2个单位）
        
        -- 降低高度偏差阈值，更积极地应用修正力
        if math.abs(boatHeight - idealHeight) > 0.3 then
            -- 根据偏离程度动态调整修正力强度
            local deviationFactor = math.abs(boatHeight - idealHeight) / 0.3 -- 计算偏离倍数
            local heightCorrection = (idealHeight - boatHeight) * (0.15 * math.min(deviationFactor, 3)) -- 最高45%的修正力
            
            -- 应用更强的垂直稳定力
            boatBodyVelocity.Velocity = Vector3.new(
                currentVelocity.X,
                currentVelocity.Y + heightCorrection,
                currentVelocity.Z
            )
        end
        
        -- 添加额外的水平稳定控制，减少左右摇晃
        local horizontalVelocity = Vector3.new(primaryPart.AssemblyLinearVelocity.X, 0, primaryPart.AssemblyLinearVelocity.Z)
        if horizontalVelocity.Magnitude > 0.8 and currentVelocity.Magnitude < 5 then
            -- 当船只没有主动移动但有水平漂移时，应用水平阻尼
            local horizontalDamping = 0.4
            boatBodyVelocity.Velocity = Vector3.new(
                currentVelocity.X - (primaryPart.AssemblyLinearVelocity.X * horizontalDamping),
                currentVelocity.Y,
                currentVelocity.Z - (primaryPart.AssemblyLinearVelocity.Z * horizontalDamping)
            )
        end
    end
    
    --print("Damped Velocity: ", dampedVelocity)
    bodyAngularVelocity.AngularVelocity = dampedVelocity
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
                print("船只 "..boat.Name.." 不存在")
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