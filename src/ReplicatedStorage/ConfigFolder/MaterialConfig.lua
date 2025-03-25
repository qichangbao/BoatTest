local MaterialTiers = {
    [1] = {name = "朽木", health = 50, unlockLevel = 1, expYield = 10},
    [2] = {name = "铁板", health = 150, unlockLevel = 3, expYield = 30},
    [3] = {name = "精钢", health = 300, unlockLevel = 5, expYield = 60},
    [4] = {name = "星尘合金", health = 600, unlockLevel = 8, expYield = 100}
}

return {
    GetTierData = function(tier)
        return MaterialTiers[tier]
    end,

    GetTierByLevel = function(level)
        local available = {}
        for tier,data in pairs(MaterialTiers) do
            if data.unlockLevel <= level then
                table.insert(available, data)
            end
        end
        return available
    end,
    
    RandomMaterial = function(currentLevel)
        local validTiers = {}
        for tier,data in pairs(MaterialTiers) do
            if data.unlockLevel <= currentLevel then
                table.insert(validTiers, data)
            end
        end
        return validTiers[math.random(#validTiers)]
    end
}