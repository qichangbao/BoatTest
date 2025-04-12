local ConditionBase = {}
ConditionBase.__index = ConditionBase

function ConditionBase.new(config)
    local self = setmetatable({}, ConditionBase)
    self.config = config
    self.maxConditions = self.config.MaxConditions or -1
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

function ConditionBase:Connect(callback)
    return self.bindableEvent.Event:Connect(callback)
end

return ConditionBase