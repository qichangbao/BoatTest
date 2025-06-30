local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local PositionCondition = {}
setmetatable(PositionCondition, ConditionBase)
PositionCondition.__index = PositionCondition

function PositionCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), PositionCondition)
    
    self.position = self.config.Position
    self.radius = self.config.Radius
    
    return self
end

function PositionCondition:MonitorPlayer(player)
    -- 检查是否超过最大触发次数
    if self:IsReachingMaxConditions(player) then
        return
    end

    -- 检查冷却时间
    if self:IsReachingCooldown(player) then
        return
    end

    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local distance = (Vector3.new(rootPart.Position.X - self.position.X, 0, rootPart.Position.Z - self.position.Z)).Magnitude
    if distance <= self.radius then
        self:Fire({
            Player = player,
            Position = rootPart.Position,
            ConditionPosition = self.position,
        })
    end
end

return PositionCondition