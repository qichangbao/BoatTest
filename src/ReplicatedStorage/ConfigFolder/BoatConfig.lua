local BoatConfig = {
    ["初级小船"] = {
        ["初级小船_船身"] = {PartType = "PrimaryPart", HP = 50, speed = 5},
        ["初级小船_旗帜"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船_桅杆"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船_绳子"] = {PartType = "OtherPart", HP = 10, speed = 1},
    },
    ["2级船"] = {
        ["2级船_船身"] = {PartType = "PrimaryPart", HP = 150, speed = 10},
        ["2级船_前杠"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_桅杆"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_舵"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_船舵"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_船锚"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_风帆1"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_风帆2"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_驾驶室"] = {PartType = "OtherPart", HP = 30, speed = 1},
        ["2级船_前炮"] = {PartType = "WeaponPart", HP = 30, speed = 1},
        ["2级船_右炮"] = {PartType = "WeaponPart", HP = 30, speed = 1},
        ["2级船_左炮"] = {PartType = "WeaponPart", HP = 30, speed = 1},
    }
}

function BoatConfig.GetBoatConfig(boatName)
    return BoatConfig[boatName]
end

return BoatConfig