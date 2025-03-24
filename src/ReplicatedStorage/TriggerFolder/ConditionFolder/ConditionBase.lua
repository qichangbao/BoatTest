local ConditionBase = {}
ConditionBase.__index = ConditionBase

function ConditionBase.new(config)
    local self = setmetatable({}, ConditionBase)
    self.config = config
    self.bindableEvent = Instance.new("BindableEvent")
    return self
end

function ConditionBase:StartMonitoring()
    error("必须由子类实现监测逻辑")
end

function ConditionBase:Connect(callback)
    return self.bindableEvent.Event:Connect(callback)
end

return ConditionBase