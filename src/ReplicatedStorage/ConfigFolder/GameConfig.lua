local GameConfig = {
    -- 地形类型配置
    TerrainType = {
        Land = {
            Material = Enum.Material.Grass,
            ChunkSize = 256,
            Height = 0,
            LoadDistance = 2,
        },
        Water = {
            Material = Enum.Material.Water,
            ChunkSize = 256,
            Depth = 1,
            Height = 0,
            WaveSpeed = 1,
            LoadDistance = 2
        }
    },
    
    -- 岛屿配置
    Islands = {
        {
            Position = Vector3.new(120, 0, 80),
            Size = 40,
            SpawnChance = 1.0
        },
        {
            Position = Vector3.new(-200, 0, -70),
            Size = 30,
            SpawnChance = 0.8
        }
    }
}

return GameConfig