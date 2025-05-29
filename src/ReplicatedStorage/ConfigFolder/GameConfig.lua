local GameConfig = {
    Water = {
        Material = Enum.Material.Water,
        ChunkSize = 200,
        Depth = 30,
        WaveSpeed = 1,
        LoadDistance = 2,
    },
    IsLand = {
        [1] = {
            Name = "奥林匹斯",
            Position = Vector3.new(0, 90, 0),
            ModelName = "IsLand1",
            WharfInOffsetPos = Vector3.new(75, 20, 180),
            WharfOutOffsetPos = CFrame.new(Vector3.new(180, 20, 20)) * CFrame.fromOrientation(math.rad(90), math.rad(-100), math.rad(180)),
            OwnerModelOffsetPos = CFrame.new(Vector3.new(75, 27, 120)) * CFrame.fromOrientation(math.rad(0), math.rad(180), math.rad(0)),
            Price = 0,
        },
        [2] = {
            Name = "阿卡迪亚",
            Position = Vector3.new(400, 90, 400),
            ModelName = "IsLand1",
            WharfInOffsetPos = Vector3.new(75, 20, 180),
            WharfOutOffsetPos = CFrame.new(Vector3.new(180, 20, 20)) * CFrame.fromOrientation(math.rad(90), math.rad(-100), math.rad(180)),
            OwnerModelOffsetPos = CFrame.new(Vector3.new(75, 27, 120)) * CFrame.fromOrientation(math.rad(0), math.rad(180), math.rad(0)),
            Price = 100,
        },
        [3] = {
            Name = "埃尔多拉多",
            Position = Vector3.new(800, 90, 800),
            ModelName = "IsLand1",
            WharfInOffsetPos = Vector3.new(75, 20, 180),
            WharfOutOffsetPos = CFrame.new(Vector3.new(180, 20, 20)) * CFrame.fromOrientation(math.rad(90), math.rad(-100), math.rad(180)),
            OwnerModelOffsetPos = CFrame.new(Vector3.new(75, 27, 120)) * CFrame.fromOrientation(math.rad(0), math.rad(180), math.rad(0)),
            Price = 100,
        },
    },
}

GameConfig.FindIsLand = function(name)
    for _, v in ipairs(GameConfig.IsLand) do
        if v.Name == name then
            return v
        end
    end
    return nil
end

return GameConfig