local LanguageConfig = require(script.Parent:WaitForChild("LanguageConfig"))

local _data = {
    -- -- 攻击/伤害类BUFF
    -- damage = {
    --     buffType = "damage",
    --     Random = 100,
    --     Parts = {
    --         attack_boost = {
    --             displayName = "攻击强化",
    --             buffType = "damage",
    --             effectType = "multiplier",
    --             value = 1.2,
    --             duration = 60,
    --             Random = 10,
    --         },
    --     }
    -- },
    
    -- -- 速度类BUFF
    -- speed = {
    --     buffType = "speed",
    --     Random = 100,
    --     Parts = {
    --         speed_boost = {
    --             displayName = LanguageConfig.Get(10052),
    --             buffType = "speed",
    --             effectType = "additive",
    --             value = 5,
    --             duration = 45,
    --             Random = 10,
    --         },
    --     }
    -- },
    
    -- -- 生命类BUFF
    -- health = {
    --     buffType = "health",
    --     Random = 100,
    --     Parts = {
    --         health_boost = {
    --             displayName = LanguageConfig.Get(10053),
    --             buffType = "health",
    --             effectType = "multiplier",
    --             value = 1.2,
    --             duration = 60,
    --             Random = 10,
    --         },
    --     }
    -- },
    
    -- 幸运类BUFF
    lucky = {
        buffType = "lucky",
        Random = 100,
        Parts = {
            lucky_boost = {
                displayName = LanguageConfig.Get(10054),
                buffType = "lucky",
                effectType = "chance",
                value = 0.3,
                duration = 90,
                Random = 100,
            },
        }
    },
}

local BuffConfig = {}

local _randomMainMaxNum = 0
local _randomTable = {}
for i, v in pairs(_data) do
    _randomMainMaxNum += v.Random
    local subMaxNum = 0
    local randomSubMaxNum = {}
    for j, k in pairs(v.Parts) do
        k.buffId = j
        subMaxNum += k.Random
        table.insert(randomSubMaxNum, {subItem = k, random = subMaxNum})
    end
    table.insert(_randomTable, {mainItem = v, random = _randomMainMaxNum, subMaxNum = subMaxNum, randomSubMaxNum = randomSubMaxNum})
end

function BuffConfig.GetBuffConfig(buffId)
    for i, v in pairs(_data) do
        for j, k in pairs(v.Parts) do
            if j == buffId then
                return k
            end
        end
    end
end

function BuffConfig.GetRandomBuff()
    local curMainItem = nil
    local mainNum = math.random(1, _randomMainMaxNum)
    for i, v in pairs(_randomTable) do
        if mainNum <= v.random then
            curMainItem = v
            break
        end
    end

    local subNum = math.random(1, curMainItem.subMaxNum)
    for i, v in pairs(curMainItem.randomSubMaxNum) do
        if subNum <= v.random then
            return v.subItem
        end
    end
end

return BuffConfig