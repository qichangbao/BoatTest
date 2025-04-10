local Knit = require(game:GetService('ReplicatedStorage').Packages.Knit.Knit)
local PhysicsService = game:GetService('PhysicsService')

local BoatMovementService = Knit.CreateService({
    Name = 'BoatMovementService',
    Client = {
        isOnBoat = Knit.CreateSignal(),
    },
    VelocityForce = 15,
    AngularVelocity = 100000, -- 提升角速度以加快转向响应
    MaxSpeed = 25,
    HeartbeatHandle = nil,
    Boats = {},
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

    -- 獨立限制速度
    local speed = math.clamp(math.abs(direction.Z) * self.VelocityForce, 0, self.MaxSpeed)
    boatBodyVelocity.Velocity = worldDirection * speed
end

function BoatMovementService:ApplyAngular(primaryPart, direction)
    local bodyAngularVelocity = primaryPart:FindFirstChild("BoatBodyAngularVelocity")
    -- 处理停止移动的情况
    if direction == Vector3.new(0, 0, 0) then
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        return
    end
    -- 左右轉向（僅在Y軸施加扭矩）
    -- 角速度参数已迁移到组件初始化时设置
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, direction.Z * self.AngularVelocity * 2, 0)
end

function BoatMovementService:ApplyMovement(player, direction, angular)
    -- 通过玩家ID获取对应船只模型
    local boat = workspace:FindFirstChild("PlayerBoat_"..player.UserId)
    if not boat then return end
    
    -- 使用船只的主部件进行物理约束
    local primaryPart = boat.PrimaryPart
    if not primaryPart then
        warn("船只 "..boat.Name.." 缺少PrimaryPart")
        return
    end
    
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
                print("船只 "..boat.Name.." 不存在")
                continue
            end

            local primaryPart = boat.PrimaryPart
            if not primaryPart then
                self.Boats[player] = nil
                print("船只 "..boat.Name.." 缺少PrimaryPart")
                continue
            end

            self:ApplyMovement(player, data.direction, data.angular)
        end
    end)
end

function BoatMovementService:KnitStart()
    print('BoatMovementService Started')
end

return BoatMovementService