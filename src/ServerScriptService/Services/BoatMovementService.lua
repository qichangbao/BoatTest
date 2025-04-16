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

function BoatMovementService:ApplyMovement(primaryPart, direction, angular)
    -- 应用物理效果到船体
    self:ApplyAngular(primaryPart, angular)
    self:ApplyVelocity(primaryPart, direction)
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