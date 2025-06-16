local LanguageConfig = require(script.Parent:WaitForChild("LanguageConfig"))

local TowerConfig = {
    Tower1 = {
        ModelName = LanguageConfig.Get(10062),
        Price = 100,
        Damage = 20,
        ArrowName = "箭矢1",
        ArrowSpeed = 80,
        Health = 100, -- 默认生命值
        AttackSpeed = 1, -- 每秒攻击次数
        AttackRange = 50 -- 攻击范围
    },
    Tower2 = {
        ModelName = LanguageConfig.Get(10064),
        Price = 200,
        Damage = 40,
        ArrowName = "箭矢2",
        ArrowSpeed = 100,
        Health = 150, -- 默认生命值
        AttackSpeed = 1.5, -- 每秒攻击次数
        AttackRange = 60 -- 攻击范围
    }
}

return TowerConfig