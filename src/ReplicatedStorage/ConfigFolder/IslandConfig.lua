local IslandConfig = {
    IsLand = {
        [1] = {
            Name = "奥林匹斯",
            Position = Vector3.new(0, 0, 0),
            ModelName = "岛屿1",
        },
        -- [2] = {
        --     Name = "奥林匹斯",
        --     Position = Vector3.new(0, 0, 0),
        --     ModelName = "岛屿1",
        --     OwnerModelOffsetPos = CFrame.new(Vector3.new(0, 27, 65)) * CFrame.fromOrientation(math.rad(0), math.rad(180), math.rad(0)),
        --     TowerOffsetPos = {Vector3.new(100, 12, 140), Vector3.new(70, 12, 140)},
        --     Price = 100,
        -- },
        -- [3] = {
        --     Name = "奥林匹斯",
        --     Position = Vector3.new(0, 0, 0),
        --     ModelName = "岛屿1",
        --     OwnerModelOffsetPos = CFrame.new(Vector3.new(0, 27, 65)) * CFrame.fromOrientation(math.rad(0), math.rad(180), math.rad(0)),
        --     TowerOffsetPos = {Vector3.new(100, 12, 140), Vector3.new(70, 12, 140), Vector3.new(40, 12, 140)},
        --     Price = 150,
        -- },
    },

    IsLandPart = {
        [1] = {
            type = "Tree",
            parts = {
                "tree1",
                "tree2",
                "tree3",
                "tree4",
            },
        },
        [2] = {
            type = "Stone",
            parts = {
                "stone1",
                "stone2",
                "stone3",
            },
        },
        [3] = {
            type = "Chest",
            parts = {
                "chest1",
                "chest2",
                "chest3",
            }
        }
    },
}

IslandConfig.FindIsLand = function(name)
    for _, v in ipairs(IslandConfig.IsLand) do
        if v.Name == name then
            return v
        end
    end
    return nil
end

IslandConfig.GetRandomIsland = function()
    local index = math.random(1, #IslandConfig.IsLand)
    return IslandConfig.IsLand[index]
end

IslandConfig.GetIslandPart = function(num)
    local count = 0
    local parts = {}
    for i = 1, num do
        count += 1
        if count > #IslandConfig.IsLandPart then
            count = 1
        end
        local partType = IslandConfig.IsLandPart[count]
        local partCount = math.random(1, #partType.parts)
        table.insert(parts, {partType = partType.type, partName = partType.parts[partCount]})
    end
    
    -- 打乱parts数组
    for i = #parts, 2, -1 do
        local j = math.random(1, i)
        parts[i], parts[j] = parts[j], parts[i]
    end
    
    return parts
end

return IslandConfig