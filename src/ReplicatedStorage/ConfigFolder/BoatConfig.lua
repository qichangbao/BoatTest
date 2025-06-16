local BoatConfig = {
    ["船"] = {
        ["Polysurface351"] = {PartType = "PrimaryPart", HP = 100, speed = 10},
        ["Polysurface11"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface121"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface141"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface161"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface181"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface201"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface21"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface31"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface41"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["Polysurface51"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象001"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象002"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象003"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象004"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象005"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象006"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象007"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象008"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象009"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象010"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象011"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象012"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象013"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象014"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象015"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象016"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象017"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象018"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象019"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象020"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["对象023"] = {PartType = "OtherPart", HP = 10, speed = 1},
        ["船炮1"] = {PartType = "WeaponPart", HP = 10, speed = 1},
        ["船炮2"] = {PartType = "WeaponPart", HP = 10, speed = 1},
        ["船炮3"] = {PartType = "WeaponPart", HP = 10, speed = 1},
        ["船炮4"] = {PartType = "WeaponPart", HP = 10, speed = 1},
    }
}

function BoatConfig.GetBoatConfig(boatName)
    return BoatConfig[boatName]
end

return BoatConfig