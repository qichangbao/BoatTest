local ConditionBase = {}
ConditionBase.__index = ConditionBase

function ConditionBase.new(config)
    local self = setmetatable({}, ConditionBase)
    self.config = config
    self.maxConditions = self.config.MaxConditions or -1
    self.cooldown = self.config.Cooldown or 0
    self.randomChance = config.RandomChance or 100
    self.isGoodCondition = config.IsGoodCondition
    self.lastConditionTime = {}
    self.conditionCount = {}
    self.bindableEvent = Instance.new("BindableEvent")
    return self
end

function ConditionBase:StartMonitoring(player)
    self.conditionCount[player.UserId] = self.conditionCount[player.UserId] or 0
    self.lastConditionTime[player.UserId] = tick()
end

function ConditionBase:StopMonitoring(player)
    self.conditionCount[player.UserId] = nil
    self.lastConditionTime[player.UserId] = nil
end

-- 检查是否达到最大触发次数
function ConditionBase:IsReachingMaxConditions(player)
    if self.maxConditions > 0 then
        return self.conditionCount[player.UserId] or 0 >= self.maxConditions
    end
    return false
end

-- 检查是否达到冷却时间
function ConditionBase:IsReachingCooldown(player)
    if not self.lastConditionTime[player.UserId] then
        return true
    end

    -- 检查冷却时间
    if tick() - self.lastConditionTime[player.UserId] > self.cooldown then
        return false
    end
    return true
end

function ConditionBase:Reset(player)
    self.conditionCount[player.UserId] = 0
    self.lastConditionTime[player.UserId] = tick()
end

function ConditionBase:Fire(data)
    self.lastConditionTime[data.Player.UserId] = tick()
    local playerLucky = data.Player:GetAttribute("Lucky") or 0
    local curRandomChance = self.randomChance
    if self.isGoodCondition == true then
        curRandomChance = math.min(curRandomChance + playerLucky * 100, 100)
    elseif self.isGoodCondition == false then
        curRandomChance = math.max(curRandomChance - playerLucky * 100, 0)
    end
    if curRandomChance <= 100 then
        local randomValue = math.random(1, 100)
        if randomValue <= curRandomChance then
            print("条件触发")
            self.conditionCount[data.Player.UserId] = self.conditionCount[data.Player.UserId] or 0 + 1
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