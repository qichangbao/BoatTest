local BoatWeaponConfig = {
    -- 船炮配置
    ["初级小船1_炮"] = {
        Damage = 15,           -- 伤害值
        AttackRange = 160,      -- 攻击范围
        AttackSpeed = 1,       -- 每秒攻击次数
        AttackAngle = 45,      -- 攻击角度（度）
        ProjectileName = "船炮弹1", -- 炮弹模型名称
        ProjectileSpeed = 80,  -- 炮弹速度
        ExplosionRadius = 5,   -- 爆炸半径
    },
    ["3级船_前炮"] = {
        Damage = 20,
        AttackRange = 170,
        AttackSpeed = 0.8,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 85,
        ExplosionRadius = 6,
    },
    ["3级船_左炮"] = {
        Damage = 25,
        AttackRange = 180,
        AttackSpeed = 0.7,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 90,
        ExplosionRadius = 7,
    },
    ["3级船_右炮"] = {
        Damage = 30,
        AttackRange = 190,
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