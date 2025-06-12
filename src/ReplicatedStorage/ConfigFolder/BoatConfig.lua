local BoatConfig = {
    ["船"] = {
        ["Polysurface351"] = {isPrimaryPart = true, HP = 100, speed = 10},
        ["Polysurface11"] = {HP = 10, speed = 1},
        ["Polysurface121"] = {HP = 10, speed = 1},
        ["Polysurface141"] = {HP = 10, speed = 1},
        ["Polysurface161"] = {HP = 10, speed = 1},
        ["Polysurface181"] = {HP = 10, speed = 1},
        ["Polysurface201"] = {HP = 10, speed = 1},
        ["Polysurface21"] = {HP = 10, speed = 1},
        ["Polysurface31"] = {HP = 10, speed = 1},
        ["Polysurface41"] = {HP = 10, speed = 1},
        ["Polysurface51"] = {HP = 10, speed = 1},
        ["对象001"] = {HP = 10, speed = 1},
        ["对象002"] = {HP = 10, speed = 1},
        ["对象003"] = {HP = 10, speed = 1},
        ["对象004"] = {HP = 10, speed = 1},
        ["对象005"] = {HP = 10, speed = 1},
        ["对象006"] = {HP = 10, speed = 1},
        ["对象007"] = {HP = 10, speed = 1},
        ["对象008"] = {HP = 10, speed = 1},
        ["对象009"] = {HP = 10, speed = 1},
        ["对象010"] = {HP = 10, speed = 1},
        ["对象011"] = {HP = 10, speed = 1},
        ["对象012"] = {HP = 10, speed = 1},
        ["对象013"] = {HP = 10, speed = 1},
        ["对象014"] = {HP = 10, speed = 1},
        ["对象015"] = {HP = 10, speed = 1},
        ["对象016"] = {HP = 10, speed = 1},
        ["对象017"] = {HP = 10, speed = 1},
        ["对象018"] = {HP = 10, speed = 1},
        ["对象019"] = {HP = 10, speed = 1},
        ["对象020"] = {HP = 10, speed = 1},
        ["对象023"] = {HP = 10, speed = 1},
        ["船炮1"] = {HP = 10, speed = 1},
        ["船炮2"] = {HP = 10, speed = 1},
        ["船炮3"] = {HP = 10, speed = 1},
        ["船炮4"] = {HP = 10, speed = 1},
    }
}

function BoatConfig.GetBoatConfig(boatName)
    return BoatConfig[boatName]
end

return BoatConfig