local BuffConfig = {
    attack_boost = {
        displayName = "攻击强化",
        effectType = "multiplier",
        value = 1.2,
        duration = 60,
        icon = "rbxassetid://12345678"
    },
    speed_boost = {
        displayName = "机动强化",
        effectType = "additive",
        value = 0.3,
        duration = 45,
        icon = "rbxassetid://87654321"
    },
    fishing_bonus = {
        displayName = "渔获加成",
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