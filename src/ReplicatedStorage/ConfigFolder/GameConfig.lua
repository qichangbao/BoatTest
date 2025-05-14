local GameConfig = {
    -- 地形类型配置
    TerrainType = {
        Land = {"Land", "IsLand1",},
        Water = {
            Material = Enum.Material.Water,
            ChunkSize = 200,
            Depth = 30,
            WaveSpeed = 1,
            LoadDistance = 2,
        }
    },
}

return GameConfig