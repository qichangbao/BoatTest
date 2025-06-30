local BoatConfig = {
    ["初级小船1"] = {
        ["初级小船1_船身"] = {PartType = "PrimaryPart", HP = 100, speed = 10},
        ["初级小船1_副船桨"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船1_旗帜"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船1_桅杆"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船1_梯子"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船1_船桨"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["初级小船1_座椅"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["初级小船1_炮"] = {PartType = "WeaponPart", HP = 10, speed = 1},
    },
    ["3级船"] = {
        ["3级船_船身"] = {PartType = "PrimaryPart", HP = 100, speed = 10},
        ["3级船_箱子"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["3级船_旗帜2"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["3级船_桅杆"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["3级船_绳子002"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["3级船_绳子003"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["3级船_舵"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["3级船_船舵"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["3级船_船锚"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["3级船_风帆1"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["3级船_风帆2"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["3级船_驾驶室"] = {PartType = "SeatPart", HP = 10, speed = 1},
        ["3级船_炮"] = {PartType = "WeaponPart", HP = 10, speed = 1},
        ["3级船_右炮"] = {PartType = "WeaponPart", HP = 10, speed = 1},
        ["3级船_左炮"] = {PartType = "WeaponPart", HP = 10, speed = 1},
    }
}

function BoatConfig.GetBoatConfig(boatName)
    return BoatConfig[boatName]
end

return BoatConfig