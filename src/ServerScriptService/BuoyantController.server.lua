local CollectionService = game:GetService("CollectionService")
local FLOATABLE_TAG = "BoatPart"

local function applyBuoyancy(part)
    part.CustomPhysicalProperties = PhysicalProperties.new(
        800,  -- 密度（kg/m³）低于水密度1000
        0.3,  -- 摩擦系数
        0.5,  -- 弹性系数
        0.8,  -- 摩擦权重
        0.5   -- 弹性权重
    )
    
    local buoyancy = Instance.new("VectorForce")
    buoyancy.Force = Vector3.new(0, 5000, 0)  -- Y轴方向浮力
    buoyancy.RelativeTo = Enum.ActuatorRelativeTo.World
    buoyancy.Parent = part
end

CollectionService:GetInstanceAddedSignal(FLOATABLE_TAG):Connect(applyBuoyancy)

-- 初始化已存在的部件
for _, part in ipairs(CollectionService:GetTagged(FLOATABLE_TAG)) do
    applyBuoyancy(part)
end