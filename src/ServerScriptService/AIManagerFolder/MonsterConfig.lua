local MonsterConfig = {
    ["海怪1"]  = {
        Type = "Monster",
        Health = 100,
        WalkSpeed = 16,
        VisionRange = 100,
        AttackRange = 40,
        Damage = 10,
        PatrolRadius = 80,
        MaxDisForSpawn = 300,
        RespawnTime = 30,
        Drops = {
            {ItemId = "Medkit", Chance = 0.3, Offset = Vector3.new(0, 2, 0)},
            {ItemId = "Ammo", Chance = 0.5, Offset = Vector3.new(1, 2, -1)}
        }
    },
}

return MonsterConfig