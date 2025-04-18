local MonsterConfig = {
    ["怪物1"]  = {
        Type = "Monster",
        Health = 100,
        WalkSpeed = 16,
        VisionRange = 200,
        AttackRange = 20,
        PatrolRadius = 35,
        RespawnTime = 30,
        Drops = {
            {ItemId = "Medkit", Chance = 0.3, Offset = Vector3.new(0, 2, 0)},
            {ItemId = "Ammo", Chance = 0.5, Offset = Vector3.new(1, 2, -1)}
        }
    },
}

return MonsterConfig