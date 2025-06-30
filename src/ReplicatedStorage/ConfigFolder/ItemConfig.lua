local ItemConfig = {}
ItemConfig.BoatTag = "船"

local _data = {
    [ItemConfig.BoatTag] = {
        Random = 100,
        Parts = {
            ["初级小船1"] = {
                Name = "初级小船1",
                MinTime = 0,   -- 需要达到的最小天数才能抽取
                MaxTime = 5,   -- 需要达到的最大天数才能抽取
                Parts = {
                    ["初级小船1_船身"] = {
                        itemName = "初级小船1_船身", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船1_副船桨"] = {
                        itemName = "初级小船1_副船桨", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 20
                    },
                    ["初级小船1_旗帜"] = {
                        itemName = "初级小船1_旗帜", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 20
                    },
                    ["初级小船1_桅杆"] = {
                        itemName = "初级小船1_桅杆", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船1_梯子"] = {
                        itemName = "初级小船1_梯子", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船1_船桨"] = {
                        itemName = "初级小船1_船桨", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船1_座椅"] = {
                        itemName = "初级小船1_座椅", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["初级小船1_炮"] = {
                        itemName = "初级小船1_炮", 
                        modelName = "初级小船1",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                },
            },
            ["3级船"] = {
                Name = "3级船",
                MinTime = 5,   -- 需要达到的最小天数才能抽取
                MaxTime = 10,  -- 需要达到的最大天数才能抽取
                Parts = {
                    ["3级船_船身"] = {
                        itemName = "3级船_船身", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["3级船_箱子"] = {
                        itemName = "3级船_箱子", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["3级船_旗帜2"] = {
                        itemName = "3级船_旗帜2", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["3级船_桅杆"] = {
                        itemName = "3级船_桅杆", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["3级船_绳子002"] = {
                        itemName = "3级船_绳子002", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 10
                    },
                    ["3级船_绳子003"] = {
                        itemName = "3级船_绳子003", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_舵"] = {
                        itemName = "3级船_舵", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_船舵"] = {
                        itemName = "3级船_船舵", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_船锚"] = {
                        itemName = "3级船_船锚", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_风帆1"] = {
                        itemName = "3级船_风帆1", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_风帆2"] = {
                        itemName = "3级船_风帆2", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_驾驶室"] = {
                        itemName = "3级船_驾驶室", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_炮"] = {
                        itemName = "3级船_炮", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_右炮"] = {
                        itemName = "3级船_右炮", 
                        modelName = "3级船",
                        itemType = ItemConfig.BoatTag,
                        icon = "rbxassetid://12345678", 
                        sellPrice = 10, 
                        Random = 5
                    },
                    ["3级船_左炮"] = {
                        itemName = "3级船_左炮", 
                        modelName = "3级船",
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

local time111 = 3
function ItemConfig.GetRandomItem()
    local randomCount = math.random(100)
    local curCount = 0
    for i, v in pairs(_data) do
        if randomCount <= curCount + v.Random then
            if i == ItemConfig.BoatTag then
                for j, k in pairs(v.Parts) do
                    if time111 >= k.MinTime and time111 < k.MaxTime then
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