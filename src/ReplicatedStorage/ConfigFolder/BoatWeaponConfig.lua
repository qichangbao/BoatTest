local BoatWeaponConfig = {
    -- 船炮配置
    ["2级船_前炮"] = {
        Damage = 20,
        AttackRange = 180,
        AttackSpeed = 0.8,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 85,
        ExplosionRadius = 6,
    },
    ["2级船_左炮"] = {
        Damage = 20,
        AttackRange = 140,
        AttackSpeed = 0.8,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 80,
        ExplosionRadius = 5,
    },
    ["2级船_右炮"] = {
        Damage = 20,
        AttackRange = 140,
        AttackSpeed = 0.8,
        AttackAngle = 45,
        ProjectileName = "船炮弹1",
        ProjectileSpeed = 80,
        ExplosionRadius = 5,
    },
}

function BoatWeaponConfig.GetWeaponConfig(weaponName)
    return BoatWeaponConfig[weaponName]
end

return BoatWeaponConfig