-- local CollectionService = game:GetService("CollectionService")
-- local FLOATABLE_TAG = "BoatPart"

-- local function applyBuoyancy(part)
--     part.CustomPhysicalProperties = PhysicalProperties.new(
--         100,  -- 优化后的密度值
--         0.8,  -- 增加摩擦系数
--         0.2,  -- 降低弹性系数
--         1.0,  -- 最大摩擦权重
--         0.3   -- 降低弹性权重
--     )
--     part.Anchored = false
    
--     local buoyancy = Instance.new("VectorForce")
--     buoyancy.Force = Vector3.new(0, 80000, 0)
    
--     local drag = Instance.new("LinearVelocity")
--     drag.MaxForce = 10000
--     drag.LineVelocity = 10000 * -0.5
--     drag.Parent = part
--     buoyancy.RelativeTo = Enum.ActuatorRelativeTo.World
--     buoyancy.Parent = part
-- end

-- CollectionService:GetInstanceAddedSignal(FLOATABLE_TAG):Connect(applyBuoyancy)

-- -- 初始化已存在的部件
-- for _, part in ipairs(CollectionService:GetTagged(FLOATABLE_TAG)) do
--     applyBuoyancy(part)
-- end