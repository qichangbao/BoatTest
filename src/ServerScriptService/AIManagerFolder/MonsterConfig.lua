return {
    Zombie = {
        Health = 100,
        WalkSpeed = 16,
        VisionRange = 50,
        AttackRange = 5,
        PatrolRadius = 35,
        RespawnTime = 30,
        Drops = {
            {ItemId = "Medkit", Chance = 0.3, Offset = Vector3.new(0, 2, 0)},
            {ItemId = "Ammo", Chance = 0.5, Offset = Vector3.new(1, 2, -1)}
        }
    },
    Skeleton = {
        Health = 80,
        WalkSpeed = 18,
        VisionRange = 40,
        AttackRange = 3,
        PatrolRadius = 25,
        RespawnTime = 20,
        Drops = {
            {ItemId = "Bones", Chance = 0.8, Offset = Vector3.new(0, 1, 0)}
        }
    }
}