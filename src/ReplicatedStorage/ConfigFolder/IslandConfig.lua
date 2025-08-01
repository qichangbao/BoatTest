local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

local IslandConfig = {
    IsLand = {
        [1] = {
            Name = "奥林匹斯",
            DisplayName = LanguageConfig.Get(10139),
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
    RandomIsLand = {
        [1] = {ModelName = "岛屿1"},
        [2] = {ModelName = "岛屿2"},
    },

    IsLandPart = {
        [1] = {
            type = "Tree",
            parts = {
                "tree1",
            },
        },
        [2] = {
            type = "Stone",
            parts = {
                "stone1",
                "stone2",
                "stone3",
                "stone4",
                "stone5",
            },
        },
        [3] = {
            type = "Decoration",
            parts = {
                "decoration1",
                "decoration2",
                "decoration3",
                "decoration4",
                "decoration5",
            }
        },
        [4] = {
            type = "Chest",
            parts = {
                "chest1",
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
    local index = math.random(1, #IslandConfig.RandomIsLand)
    return IslandConfig.RandomIsLand[index]
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