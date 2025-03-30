-- local CollectionService = game:GetService("CollectionService")
-- local Players = game:GetService("Players")
-- local FLOATABLE_TAG = "BoatPart"

-- local function calculateTotalMass(part)
--     local totalMass = 0
--     for _, player in ipairs(Players:GetPlayers()) do
--         if player.Character and player.Character.PrimaryPart then
--             local distance = (player.Character.PrimaryPart.Position - part.Position).Magnitude
--             if distance < 10 then
--                 totalMass += player.Character.PrimaryPart:GetMass()
--             end
--         end
--     end
--     return math.max(totalMass, 1)
-- end

-- local function applyBuoyancy(part)
--     local massFactor = calculateTotalMass(part)
--     part.CustomPhysicalProperties = PhysicalProperties.new(
--         0.01, 
--         0.35 + (massFactor * 0.05), 
--         0.2 + (massFactor * 0.02)
--     )
--     print(part.CustomPhysicalProperties)
--     part.Anchored = false
    
    
--     -- local buoyancy = Instance.new("VectorForce")
--     -- buoyancy.Force = Vector3.new(0, 80000, 0)
    
--     -- local drag = Instance.new("LinearVelocity")
--     -- drag.MaxForce = 10000
--     -- drag.LineVelocity = 10000-- * -0.5
--     -- drag.Parent = part
--     -- buoyancy.RelativeTo = Enum.ActuatorRelativeTo.World
--     -- buoyancy.Parent = part
-- end

-- CollectionService:GetInstanceAddedSignal(FLOATABLE_TAG):Connect(applyBuoyancy)

-- -- 初始化已存在的部件
-- for _, part in ipairs(CollectionService:GetTagged(FLOATABLE_TAG)) do
--     applyBuoyancy(part)
-- end
