local ActionBase = {}

function ActionBase.new(config)
    local self = setmetatable({}, ActionBase)
    self.config = config
    return self
end

function ActionBase:Execute()
    error("Execute方法必须被子类实现")
end

return ActionBase