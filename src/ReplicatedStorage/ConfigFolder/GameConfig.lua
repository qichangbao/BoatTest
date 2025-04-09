local GameConfig = {
    -- 地形类型配置
    TerrainType = {
        Land = {
            Position = Vector3.new(0, 0, 0),
            Material = Enum.Material.Grass,
            Size = Vector3.new(200, 30, 200),
            LoadDistance = 2,
        },
        Water = {
            Material = Enum.Material.Water,
            ChunkSize = 200,
            Depth = 30,
            Height = 15,
            WaveSpeed = 1,
            LoadDistance = 2
        }
    },
    
    -- 岛屿配置
    Islands = {
        {
            Position = Vector3.new(120, 0, 80),
            Size = Vector3.new(40, 40, 40),
            SpawnChance = 1.0
        },
        {
            Position = Vector3.new(-200, 0, -70),
            Size = Vector3.new(10, 10, 10),
            SpawnChance = 0.8
        }
    }
}

return GameConfig