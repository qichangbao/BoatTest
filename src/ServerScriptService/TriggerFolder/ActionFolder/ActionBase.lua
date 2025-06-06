local ActionBase = {}

function ActionBase.new(config, condition)
    local self = setmetatable({}, ActionBase)
    self.config = config
    self.condition = condition
    self.position = self.config.Position or Vector3.new(0, 0, 0)
    self.lifetime = self.config.Lifetime or -1
    return self
end

function ActionBase:Execute(data)
end

return ActionBase