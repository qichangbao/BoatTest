-- local ReplicatedStorage = game:GetService('ReplicatedStorage')
-- local RunService = game:GetService('RunService')
-- local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
-- local BOAT_PARTS_FOLDER_NAME = '船'
-- local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]

-- local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
-- local MOVEMENT_FORCE = 1500
-- local TURN_TORQUE = 80000

-- local controlEvent = ReplicatedStorage:WaitForChild(BOAT_CONTROL_RE_NAME)
-- local activeBoats = {}

-- local function createPhysicsObjects(boatModel)
--     local boatBase = boatModel
    
--     -- 设置船体物理属性
--     for _, part in ipairs(boatModel:GetDescendants()) do
--         if part:IsA('BasePart') then
--             part.Material = Enum.Material.Wood
--             part.CustomPhysicalProperties = PhysicalProperties.new(450, 0.3, 0.5)
--         end
--     end

--     -- 添加浮力效果(考虑体积因素)
--     local buoyancy = Instance.new('BodyForce')
--     local waterLevel = workspace:FindFirstChild('WaterSpawnLocation').Position.Y
--     local submergedDepth = math.clamp(waterLevel - boatBase.Position.Y, 0, boatBase.Size.Y)
--     local submergedRatio = submergedDepth / boatBase.Size.Y
    
--     local volumeFactor = (boatBase.Size.X * submergedDepth * boatBase.Size.Z) / 100  -- 根据浸水深度计算有效体积
--     buoyancy.Force = Vector3.new(0, 1962 * boatBase:GetMass() * volumeFactor * (1 + submergedRatio^2), 0)  -- 增加浸水比例平方的修正系数
--     buoyancy.Parent = boatBase
    
--     local velocity = Instance.new('LinearVelocity')
--     velocity.LineVelocity = 0
--     velocity.MaxForce = 4000
--     velocity.Parent = boatBase
    
--     local angularVelocity = Instance.new('AngularVelocity')
--     angularVelocity.AngularVelocity = Vector3.new()
--     angularVelocity.MaxTorque = 80000
--     angularVelocity.Parent = boatBase
    
--     return velocity, angularVelocity
-- end

-- controlEvent.OnServerEvent:Connect(function(player, direction, state)
--     if 1 then
--         return
--     end
--     local boat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
--     if not boat then return end
    
--     local controlData = activeBoats[boat] or {
--         velocity = nil,
--         angular = nil,
--         connections = {}
--     }
    
--     if not controlData.velocity then
--         controlData.velocity, controlData.angular = createPhysicsObjects(boat)
--         activeBoats[boat] = controlData
--     end
    
--     local forceMultiplier = state and 10000 or 0
--     local baseForce = MOVEMENT_FORCE * forceMultiplier
--     local baseTorque = TURN_TORQUE * forceMultiplier
    
--     if direction == 'Forward' then
--         controlData.velocity.LineVelocity = -baseForce
--     elseif direction == 'Backward' then
--         controlData.velocity.LineVelocity = baseForce
--     elseif direction == 'Left' then
--         controlData.angular.AngularVelocity = Vector3.new(0, baseTorque, 0)
--     elseif direction == 'Right' then
--         controlData.angular.AngularVelocity = Vector3.new(0, -baseTorque, 0)
--     end
    
--     -- 持续运动更新循环
--     if not controlData.connections.updateLoop then
--         controlData.connections.updateLoop = RunService.Heartbeat:Connect(function()
--             if not boat.Parent then
--                 controlData.velocity:Destroy()
--                 controlData.angular:Destroy()
--                 activeBoats[boat] = nil
--                 return
--             end
            
--             -- 应用水面阻力模拟和水面保持效果
--             controlData.velocity.LineVelocity *= 0.95  -- 增加线性阻力
--             controlData.angular.AngularVelocity *= 0.92
            
--             -- 增强水面保持效果
--             local boatBase = boat:FindFirstChildOfClass('BasePart')
--             if boatBase then
--                 local waterLevel = 0  -- 水面高度
--                 local depth = waterLevel - boatBase.Position.Y
                
--                 if depth > 0 then  -- 船体在水下
--                     -- 根据浸入深度增加浮力
--                     local additionalBuoyancy = depth * 500
--                     boatBase.CFrame = boatBase.CFrame + Vector3.new(0, additionalBuoyancy * 0.01, 0)
--                 elseif depth < -1 then  -- 船体过高
--                     -- 轻微下压防止漂浮过高
--                     boatBase.CFrame = boatBase.CFrame + Vector3.new(0, -0.05, 0)
--                 end
--             end
--         end)
--     end
-- end)

-- -- 清理物理组件当驾驶座释放时
-- game:GetService('Players').PlayerRemoving:Connect(function(player)
--     local boat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
--     if boat and activeBoats[boat] then
--         activeBoats[boat].velocity:Destroy()
--         activeBoats[boat].angular:Destroy()
--         if activeBoats[boat].connections.updateLoop then
--             activeBoats[boat].connections.updateLoop:Disconnect()
--         end
--         activeBoats[boat] = nil
--     end
-- end)