local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local TimeCondition = {}
setmetatable(TimeCondition, ConditionBase)
TimeCondition.__index = TimeCondition

function TimeCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), TimeCondition)
    
    self.minTime = config.MinTime or 10
    self.maxTime = config.MaxTime or 30
    self.excuteTime = math.random(self.minTime, self.maxTime)

    return self
end

function TimeCondition:StartMonitoring(player)
    ConditionBase.StartMonitoring(self, player)
    
    -- local randomValue = math.random(1, 100)
    -- if randomValue <= self.randomChance then
    --     print("触发了RandomCondition")
    --     self.bindableEvent:Fire({
    --     })
    -- end
end

function TimeCondition:MonitorPlayer(player)
    -- 检查是否超过最大触发次数
    if self:IsReachingMaxConditions(player) then
        return
    end

    -- 检查冷却时间
    if self:IsReachingCooldown(player) then
        return
    end

    -- local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    -- if not rootPart then
    --     return
    -- end

    -- local distance = (Vector3.new(rootPart.Position.X - self.position.X, 0, rootPart.Position.Z - self.position.Z)).Magnitude
    -- if distance <= self.radius then
    --     self:Fire({
    --         Player = player,
    --         Position = rootPart.Position,
    --         ConditionPosition = self.position,
    --     })
    -- end
end

return TimeCondition