local ConditionBase = {}
ConditionBase.__index = ConditionBase

function ConditionBase.new(config)
    local self = setmetatable({}, ConditionBase)
    self.config = config
    self.maxConditions = self.config.MaxConditions or -1
    self.cooldown = self.config.Cooldown or 0
    self.lastConditionTime = 0
    self.conditionCount = 0
    self.bindableEvent = Instance.new("BindableEvent")
    return self
end

function ConditionBase:StartMonitoring()
end

-- 检查是否达到最大触发次数
function ConditionBase:IsReachingMaxConditions()
    if self.maxConditions > 0 then
        return self.conditionCount >= self.maxConditions
    end
    return false
end

-- 检查是否达到冷却时间
function ConditionBase:IsReachingCooldown()
    local currentTime = tick()
    -- 检查冷却时间
    if self.lastConditionTime == 0 or currentTime - self.lastConditionTime > self.cooldown then
        return false
    end
    return true
end

function ConditionBase:Connect(callback)
    return self.bindableEvent.Event:Connect(callback)
end

return ConditionBase