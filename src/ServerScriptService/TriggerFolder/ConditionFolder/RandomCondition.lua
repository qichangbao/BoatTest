print("加载RandomCondition")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local RandomCondition = {}
setmetatable(RandomCondition, ConditionBase)
RandomCondition.__index = RandomCondition

function RandomCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), RandomCondition)
    
    self.randomChance = config.RandomChance or 0.5

    return self
end

function RandomCondition:StartMonitoring()
    ConditionBase.StartMonitoring(self)
    
    local randomValue = math.random(1, 100)
    if randomValue <= self.randomChance then
        print("触发了RandomCondition")
        self.bindableEvent:Fire({
        })
    end
end

return RandomCondition