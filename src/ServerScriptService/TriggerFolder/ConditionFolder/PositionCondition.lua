print("加载PositionCondition")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local PositionCondition = {}
setmetatable(PositionCondition, ConditionBase)
PositionCondition.__index = PositionCondition

function PositionCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), PositionCondition)
    
    self.position = self.config.Position
    self.radius = self.config.Radius
    self.lastConditionTime = 0
    
    return self
end

function PositionCondition:StartMonitoring()
    ConditionBase.StartMonitoring(self)
end

function PositionCondition:MonitorPlayer(player)
    -- 检查是否超过最大触发次数
    if self:IsReachingMaxConditions() then
        return
    end

    -- 检查冷却时间
    if self:IsReachingCooldown() then
        return
    end

    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local distance = (rootPart.Position - self.position).Magnitude
    if distance <= self.radius then
        self.conditionCount += 1
        self.lastConditionTime = tick()

        self.bindableEvent:Fire({
            Player = player,
            Position = rootPart.Position,
            ConditionPosition = self.position,
            ConditionCount = self.conditionCount
        })
    end
end

return PositionCondition