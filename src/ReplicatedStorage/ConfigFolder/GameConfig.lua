local GameConfig = {
    Water = {
        Material = Enum.Material.Water,
        ChunkSize = 200,
        Depth = 30,
        WaveSpeed = 1,
        LoadDistance = 2,
    },

    LandWharfDis = 50,      -- 岛屿码头距离(用于检测船靠岸弹出登岛提示界面)
    PlayerToBoatDis = 70,   -- 玩家到船距离(用于检测弹出玩家上船提示界面)
    OccupyTime = 30,        -- 占领时间
    OccupyMaxDis = 100,     -- 占领最大距离
}

return GameConfig