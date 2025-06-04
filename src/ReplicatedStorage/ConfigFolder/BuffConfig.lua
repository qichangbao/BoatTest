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
    --             icon = "rbxassetid://12345678",
    --             Random = 10,
    --         },
    --     }
    -- },
    
    -- 速度类BUFF
    speed = {
        buffType = "speed",
        Random = 100,
        Parts = {
            speed_boost = {
                displayName = "机动强化",
                buffType = "speed",
                effectType = "additive",
                value = 5,
                duration = 45,
                icon = "rbxassetid://87654321",
                Random = 10,
            },
        }
    },
    
    -- 生命类BUFF
    health = {
        buffType = "health",
        Random = 100,
        Parts = {
            health_boost = {
                displayName = "轻微生命提升",
                buffType = "health",
                effectType = "multiplier",
                value = 1.2,
                duration = 60,
                icon = "rbxassetid://11111111",
                Random = 10,
            },
        }
    },
    
    -- -- 其他类BUFF
    -- other = {
    --     buffType = "other",
    --     Random = 100,
    --     Parts = {
    --         fishing_bonus = {
    --             displayName = "渔获加成",
    --             buffType = "other",
    --             effectType = "chance",
    --             value = 0.15,
    --             duration = 90,
    --             icon = "rbxassetid://13579246",
    --             Random = 10,
    --         },
    --     }
    -- },
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