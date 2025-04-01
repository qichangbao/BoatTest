-- 这个ModuleScript提供了计算和应用浮力的函数

local BuoyancyModule = {}

-- 计算浮力的函数
function BuoyancyModule.calculateBuoyancy(part, fluidDensity, waterLevel)
    local mass = part:GetMass()
    local gravity = workspace.Gravity
    local position = part.Position
    local size = part.Size
    
    -- 计算部件有多少部分在水下
    local submergedRatio = math.clamp((waterLevel - (position.Y - size.Y/2)) / size.Y, 0, 1)
    
    -- 计算物体体积
    local volume = size.X * size.Y * size.Z
    
    -- 理论浮力 = 物体排开水的体积 * 水的密度 * 重力加速度
    local theoreticalBuoyancy = volume * fluidDensity * gravity * submergedRatio
    
    return {
        submergedRatio = submergedRatio,
        mass = mass,
        volume = volume,
        theoreticalBuoyancy = theoreticalBuoyancy,
        netForce = theoreticalBuoyancy - (mass * gravity)
    }
end



-- 这个脚本演示了如
local RunService = game:GetService("RunService")

-- 获取父对象（
local part = script.Parent

-- 设置物理
part.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Water)

-- 注意：仅设置Material.Wat
-- 我们需要手动实现��

-- 使用LineForce约
local function addLineForceConstraint()
    local lineForce = Instance.new("LineForce")
    lineForce.Name = "LineForce"
    
    -- 设定LineForce的类型为Buoyancy（类
    lineForce.Type = Enum.LineForceType.Buoyancy
    
    -- 设定LineForce��
    lineForce.DirectionalForce = Vector3.new(0, 1, 0)
    
    lineForce.Parent = part
    return lineForce
end

-- 执行该�
local lineForce = addLineForceConstraint()



-- 为部件添加浮力的函数
function BuoyancyModule.applyBuoyancy(part, waterLevel, fluidDensity)
    fluidDensity = fluidDensity or 1.0
    
    local buoyancy = Instance.new("Buoyancy")
    buoyancy.Name = "PartBuoyancy"
    buoyancy.FluidDensity = fluidDensity
    buoyancy.PlaneNormal = Vector3.new(0, 1, 0)
    buoyancy.BaseHeight = waterLevel
    
    -- 计算相对密度
    local partDensity = part:GetMass() / (part.Size.X * part.Size.Y * part.Size.Z)
    buoyancy.RelativeDensity = partDensity / fluidDensity
    
    buoyancy.Parent = part
    return buoyancy
end

return BuoyancyModule