-- print('BuoyantController loaded')
-- local PhysicsService = game:GetService('PhysicsService')
-- local RunService = game:GetService('RunService')

-- local BuoyantController = {}

-- local WATER_DENSITY = 1000 -- 水密度kg/m³
-- local GRAVITY = workspace.Gravity -- 重力加速度

-- function BuoyantController.calculateDisplacedVolume(boatModel)
--     local totalVolume = 0
--     for _, part in ipairs(boatModel:GetChildren()) do
--         if part:IsA('BasePart') then
--             local size = part.Size
--             totalVolume += size.X * size.Y * size.Z
--         end
--     end
--     return totalVolume
-- end

-- function BuoyantController.applyBuoyancy(primaryPart, boatModel)
--     local totalMass = 0
--     for _, part in ipairs(boatModel:GetChildren()) do
--         if part:IsA('BasePart') then
--             totalMass += part:GetMass()
--         end
--     end
    
--     local volume = BuoyantController.calculateDisplacedVolume(boatModel)
--     local buoyantForce = WATER_DENSITY * volume * GRAVITY
--     local massForce = totalMass * GRAVITY * 10
    
--     local buoyancy = primaryPart:FindFirstChild('BuoyancyForce') or Instance.new('BodyForce')
--     buoyancy.Name = 'BuoyancyForce'
--     buoyancy.Force = Vector3.new(0, math.max(buoyantForce - massForce, 0), 0)
--     buoyancy.Force = massForce
--     buoyancy.Parent = primaryPart
-- end

-- function BuoyantController:addBuoyancyConstraint(part)
--     local buoyancy = Instance.new("BodyForce")
--     buoyancy.Name = "BuoyancyForce"
    
--     -- 假设水面高度��
--     local waterLevel = 0
    
--     -- 设置浮力常�
--     local buoyancyForce = part:GetMass() * workspace.Gravity
    
--     -- 连接到心��
--     RunService.Heartbeat:Connect(function()
--         -- 获取
--         local position = part.Position
        
--         -- 计算有�
--         local submergedRatio = math.clamp((waterLevel - (position.Y - part.Size.Y/2)) / part.Size.Y, 0, 1)
        
--         -- 如果部件
--         if submergedRatio > 0 then
--             buoyancy.Force = Vector3.new(0, buoyancyForce * submergedRatio, 0)
--         else
--             buoyancy.Force = Vector3.new(0, 0, 0)
--         end
--         print(buoyancy.Force)
--     end)
    
--     buoyancy.Parent = part
--     return buoyancy
-- end

-- return BuoyantController
