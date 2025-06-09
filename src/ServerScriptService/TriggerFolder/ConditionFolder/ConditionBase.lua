local ConditionBase = {}
ConditionBase.__index = ConditionBase

function ConditionBase.new(config)
    local self = setmetatable({}, ConditionBase)
    self.config = config
    self.maxConditions = self.config.MaxConditions or -1
    self.cooldown = self.config.Cooldown or 0
    self.randomChance = config.RandomChance or 100
    self.isGoodCondition = config.IsGoodCondition
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

function ConditionBase:Reset()
    self.conditionCount = 0
    self.lastConditionTime = 0
end

function ConditionBase:Fire(data)
    self.lastConditionTime = tick()
    local playerLucky = data.Player:GetAttribute("Lucky") or 0
    local curRandomChance = self.randomChance
    if self.isGoodCondition then
        curRandomChance = math.min(curRandomChance + playerLucky * 100, 100)
    else
        curRandomChance = math.max(curRandomChance - playerLucky * 100, 0)
    end
    if curRandomChance <= 100 then
        local randomValue = math.random(1, 100)
        if randomValue <= curRandomChance then
            print("条件触发")
            self.conditionCount = self.conditionCount + 1
            self.bindableEvent:Fire(data)
            return
        else
            print("条件触发，但随机数不够")
            return
        end
    end
end

function ConditionBase:Connect(callback)
    return self.bindableEvent.Event:Connect(callback)
end

return ConditionBase