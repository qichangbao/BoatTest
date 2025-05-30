local BuffConfig = {
    -- 攻击/伤害类BUFF
    attack_boost = {
        displayName = "攻击强化",
        buffType = "damage",
        effectType = "multiplier",
        value = 1.2,
        duration = 60,
        icon = "rbxassetid://12345678"
    },
    
    -- 速度类BUFF
    speed_boost = {
        displayName = "机动强化",
        buffType = "speed",
        effectType = "additive",
        value = 5,
        duration = 45,
        icon = "rbxassetid://87654321"
    },
    
    -- 生命类BUFF
    health_boost = {
        displayName = "轻微生命提升",
        buffType = "health",
        effectType = "multiplier",
        value = 1.2,
        duration = 60,
        icon = "rbxassetid://11111111"
    },
    
    -- 其他类BUFF
    fishing_bonus = {
        displayName = "渔获加成",
        buffType = "other",
        effectType = "chance",
        value = 0.15,
        duration = 90,
        icon = "rbxassetid://13579246"
    }
}

function BuffConfig.GetBuffConfig(buffId)
    return BuffConfig[buffId]
end

return BuffConfig