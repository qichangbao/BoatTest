local GameConfig = {
    Water = {
        Material = Enum.Material.Water,
        ChunkSize = 200,
        Depth = 30,
        WaveSpeed = 1,
        LoadDistance = 2,
    },

    Real_To_Game_Second = 288,      -- 现实1秒 = 游戏288秒
    TotalDistanceRank = 501,        -- 总距离排行榜只取前500名
    MaxDistanceRank = 501,          -- 最大距离排行榜只取前500名
    TotalTimeRank = 501,            -- 总航行时间排行榜只取前500名
    MaxTimeRank = 501,              -- 最大航行时间排行榜只取前500名
    LandWharfDis = 20,              -- 岛屿码头距离(用于检测船靠岸弹出登岛提示界面)
    PlayerToBoatDis = 50,           -- 玩家到船距离(用于检测弹出玩家上船提示界面)
    OccupyTime = 30,                -- 占领时间
    OccupyMaxDis = 100,             -- 占领最大距离
}

return GameConfig