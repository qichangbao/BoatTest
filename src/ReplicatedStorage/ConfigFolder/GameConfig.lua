local GameConfig = {
    -- 地形类型配置
    TerrainType = {
        Land = {"Land"},
        Water = {
            Material = Enum.Material.Water,
            ChunkSize = 200,
            Depth = 30,
            WaveSpeed = 1,
            LoadDistance = 2,
        },
        IsLand = {
            [1] = {Name = "Land", Position = Vector3.new(0, 90, 0), ModelName = "IsLand1", WharfOffsetPos = Vector3.new(75, 20, 180),},
            [2] = {Name = "IsLand1", Position = Vector3.new(300, 90, 300), ModelName = "IsLand1", WharfOffsetPos = Vector3.new(75, 20, 180),},
            [3] = {Name = "IsLand2", Position = Vector3.new(600, 90, 600), ModelName = "IsLand1", WharfOffsetPos = Vector3.new(75, 20, 180),},
        },
    },
}

return GameConfig