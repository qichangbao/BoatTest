local BoatWeaponConfig = {
    -- 船炮配置
    ["船炮1"] = {
        Damage = 15,           -- 伤害值
        AttackRange = 60,      -- 攻击范围
        AttackSpeed = 1,       -- 每秒攻击次数
        AttackAngle = 45,      -- 攻击角度（度）
        ProjectileName = "船炮弹1", -- 炮弹模型名称
        ProjectileSpeed = 80,  -- 炮弹速度
        ExplosionRadius = 5,   -- 爆炸半径
    },
    ["船炮2"] = {
        Damage = 20,
        AttackRange = 70,
        AttackSpeed = 0.8,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 85,
        ExplosionRadius = 6,
    },
    ["船炮3"] = {
        Damage = 25,
        AttackRange = 80,
        AttackSpeed = 0.7,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 90,
        ExplosionRadius = 7,
    },
    ["船炮4"] = {
        Damage = 30,
        AttackRange = 90,
        AttackSpeed = 0.6,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 95,
        ExplosionRadius = 8,
    },
}

function BoatWeaponConfig.GetWeaponConfig(weaponName)
    return BoatWeaponConfig[weaponName]
end

return BoatWeaponConfig