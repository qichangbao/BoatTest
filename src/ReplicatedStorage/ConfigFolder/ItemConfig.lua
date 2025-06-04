local _data = {
    ["船"] = {
        Name = "船",
        Random = 100,
        Parts = {
            ["Polysurface351"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface11"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface121"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface141"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface161"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface181"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface201"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface21"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface31"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface371"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface381"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface41"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["Polysurface51"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象001"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象002"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象003"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象004"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象005"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象006"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象007"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象008"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象009"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象010"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象011"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象012"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象013"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象014"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象015"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象016"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象017"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象018"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象019"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象020"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象022"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
            ["对象023"] = {icon = "rbxassetid://12345678", sellPrice = 10, Random = 10},
        },
    },
}

local ItemConfig = {}

local _randomMainMaxNum = 0
local _randomTable = {}
for i, v in pairs(_data) do
    _randomMainMaxNum += v.Random
    local subMaxNum = 0
    local randomSubMaxNum = {}
    for j, k in pairs(v.Parts) do
        k.itemName = j
        k.modelName = i
        subMaxNum += k.Random
        table.insert(randomSubMaxNum, {subItem = k, random = subMaxNum})
    end
    table.insert(_randomTable, {mainItem = v, random = _randomMainMaxNum, subMaxNum = subMaxNum, randomSubMaxNum = randomSubMaxNum})
end

function ItemConfig.GetItemConfig(itemName)
    for i, v in pairs(_data) do
        for j, k in pairs(v.Parts) do
            if j == itemName then
                return k
            end
        end
    end
end

function ItemConfig.GetRandomItem()
    local curMainItem = nil
    local mainNum = math.random(1, _randomMainMaxNum)
    for i, v in pairs(_randomTable) do
        if mainNum <= v.random then
            curMainItem = v
            break
        end
    end

    local subNum = math.random(1, curMainItem.subMaxNum)
    for i, v in pairs(curMainItem.randomSubMaxNum) do
        if subNum <= v.random then
            return v.subItem
        end
    end
end

return ItemConfig