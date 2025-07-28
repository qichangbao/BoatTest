local ItemConfig = {}
ItemConfig.BoatTag = "船"

local _data = {
    [ItemConfig.BoatTag] = {
        Random = 100,
        Parts = {
            ["初级小船"] = {
                Name = "初级小船",
                MinTime = 0,   -- 需要达到的最小天数才能抽取
                MaxTime = 5,   -- 需要达到的最大天数才能抽取
                Parts = {
                    ["初级小船_船身"] = {
                        itemName = "初级小船_船身", 
                        modelName = "初级小船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船_旗帜"] = {
                        itemName = "初级小船_旗帜", 
                        modelName = "初级小船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 20
                    },
                    ["初级小船_桅杆"] = {
                        itemName = "初级小船_桅杆", 
                        modelName = "初级小船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船_绳子"] = {
                        itemName = "初级小船_绳子", 
                        modelName = "初级小船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                },
            },
            ["2级船"] = {
                Name = "2级船",
                MinTime = 5,   -- 需要达到的最小天数才能抽取
                MaxTime = -1,  -- 需要达到的最大天数才能抽取
                Parts = {
                    ["2级船_船身"] = {
                        itemName = "2级船_船身", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["2级船_前杠"] = {
                        itemName = "2级船_前杠", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["2级船_桅杆"] = {
                        itemName = "2级船_桅杆", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["2级船_舵"] = {
                        itemName = "2级船_舵", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["2级船_船舵"] = {
                        itemName = "2级船_船舵", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_船锚"] = {
                        itemName = "2级船_船锚", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_风帆1"] = {
                        itemName = "2级船_风帆1", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_风帆2"] = {
                        itemName = "2级船_风帆2", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_驾驶室"] = {
                        itemName = "2级船_驾驶室", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_前炮"] = {
                        itemName = "2级船_前炮", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_右炮"] = {
                        itemName = "2级船_右炮", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["2级船_左炮"] = {
                        itemName = "2级船_左炮", 
                        modelName = "2级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                },
            },
        },
    },
}

function ItemConfig.GetItemConfig(itemName)
    for i, v in pairs(_data) do
        if i == ItemConfig.BoatTag then
            for j, k in pairs(v.Parts) do
                for m, n in pairs(k.Parts) do
                    if m == itemName then
                        return n
                    end
                end
            end
        else
            for j, k in pairs(v.Parts) do
                if j == itemName then
                    return k
                end
            end
        end
    end
end

function ItemConfig.GetRandomItem(playerDay)
    playerDay = tonumber(playerDay)
    local randomCount = math.random(100)
    local curCount = 0
    for i, v in pairs(_data) do
        if randomCount <= curCount + v.Random then
            if i == ItemConfig.BoatTag then
                for j, k in pairs(v.Parts) do
                    if playerDay >= k.MinTime and (playerDay < k.MaxTime or k.MaxTime == -1) then
                        local randomSubCount = math.random(100)
                        local curSubCount = 0
                        for m, n in pairs(k.Parts) do
                            if randomSubCount <= curSubCount + n.Random then
                                return n
                            end
                            curSubCount += n.Random
                        end
                    end
                end
            else
                local randomSubCount = math.random(100)
                local curSubCount = 0
                for j, k in pairs(v.Parts) do
                    if randomSubCount <= curSubCount + k.Random then
                        return k
                    end
                    curSubCount += k.Random
                end
            end
        end
        curCount += v.Random
    end
end

return ItemConfig