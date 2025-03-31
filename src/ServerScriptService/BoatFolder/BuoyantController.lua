-- local PhysicsService = game:GetService('PhysicsService')

-- local BuoyantController = {}

-- local WATER_DENSITY = 1000
-- local GRAVITY = 9.81
-- local BUOYANCY_FACTOR = 2.0 -- 增强浮力补偿系数

-- function BuoyantController.calculateDisplacedVolume(boatModel)
--     local totalVolume = 0
--     local waterPart = workspace:FindFirstChild('Water')
--     local waterLevel = if waterPart then waterPart.Position.Y else 100  -- 默认水位100
--     print("[Buoyancy] 当前水位:", waterLevel)
--     if waterLevel <= 0 then
--         warn("检测到无效水位值，使用默认水位100")
--         waterLevel = 100
--     end
    
--     for _, part in ipairs(boatModel:GetDescendants()) do
--         if part:IsA('BasePart') then
--             local partBottomY = part.Position.Y - part.Size.Y/2
--             local submergedDepth = math.clamp(waterLevel - partBottomY, 0, part.Size.Y)
--             local effectiveVolume = (part.Size.X * part.Size.Z) * submergedDepth
--             totalVolume += effectiveVolume
--         end
--     end
--     return totalVolume * BUOYANCY_FACTOR
-- end

-- function BuoyantController.applyBuoyancy(primaryPart, boatModel)
--     local RunService = game:GetService('RunService')
--     local totalMass = 0
--     for _, part in ipairs(boatModel:GetDescendants()) do
--         if part:IsA('BasePart') then
--             totalMass += part:GetMass()
--         end
--     end
--     print("船的质量为："..totalMass)
--     local MASS_COMPENSATION = math.clamp(totalMass/800, 2.0, 3.0) -- 扩展补偿系数范围
    
--     local volume = BuoyantController.calculateDisplacedVolume(boatModel)
--     local buoyantForce = WATER_DENSITY * volume * GRAVITY
--     local massForce = totalMass * GRAVITY * 10
    
--     -- 添加最大浮力限制
--     local minBuoyancy = massForce * 0.98
--     local maxBuoyancy = massForce * 1.2
--     buoyantForce = math.clamp(buoyantForce, minBuoyancy, maxBuoyancy)
--     print("总质量：", totalMass)
--     print("浮力质量比：", buoyantForce / massForce)
--     print("总浮力：", buoyantForce)
--     print("部件数：", #boatModel:GetDescendants())
--     print("有效浮力：", buoyantForce - massForce)

--     for _, part in ipairs(boatModel:GetDescendants()) do
--         if part:IsA('BasePart') then
--             local buoyancy = part:FindFirstChild('BodyForce') or Instance.new('BodyForce')
--             buoyancy.Force = Vector3.new(0, buoyantForce / #boatModel:GetDescendants(), 0)
--             buoyancy.Parent = part
--         end
--     end
    
--     -- 持续更新循环
--     local connection
--     connection = RunService.Heartbeat:Connect(function()
--         if not boatModel.Parent then
--             connection:Disconnect()
--             for _, part in ipairs(boatModel:GetDescendants()) do
--                 if part:IsA('BasePart') then
--                     local buoyancy = part:FindFirstChild('BodyForce')
--                     if buoyancy then
--                         buoyancy:Destroy()
--                     end
--                 end
--             end
--             return
--         end
        
--         local currentVolume = BuoyantController.calculateDisplacedVolume(boatModel)
--         local adjustedForce = WATER_DENSITY * currentVolume * GRAVITY
--         buoyantForce = math.clamp(adjustedForce, minBuoyancy, maxBuoyancy)
        
--         for _, part in ipairs(boatModel:GetDescendants()) do
--             if part:IsA('BasePart') then
--                 local buoyancy = part:FindFirstChild('BodyForce')
--                 if buoyancy then
--                     buoyancy.Force = Vector3.new(0, buoyantForce / #boatModel:GetDescendants(), 0)
--                 end
--             end
--         end
--     end)
-- end

-- return BuoyantController
