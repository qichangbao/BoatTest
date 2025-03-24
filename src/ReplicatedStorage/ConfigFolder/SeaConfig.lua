local SeaLevels = {
    {
        name = "起始海域",
        unlockLevel = 1,
        islands = {
            {name = "新手岛", buffType = "HealthRegen", buffValue = 0.1}
        }
    },
    {
        name = "暴风海域",
        unlockLevel = 3,
        islands = {
            {name = "铁锚岛", buffType = "DamageResist", buffValue = 0.2},
            {name = "珍珠湾", buffType = "SpeedBoost", buffValue = 0.15}
        }
    },
    {
        name = "深渊海域", 
        unlockLevel = 5,
        islands = {
            {name = "龙骨礁", buffType = "CritChance", buffValue = 0.25},
            {name = "幽灵船坞", buffType = "Stealth", buffValue = 0.3}
        }
    }
}

return {
    GetSeaByLevel = function(level)
        local unlocked = {}
        for _,sea in ipairs(SeaLevels) do
            if sea.unlockLevel <= level then
                table.insert(unlocked, sea)
            end
        end
        return unlocked
    end,
    
    GetRandomIsland = function(seaName)
        for _,sea in ipairs(SeaLevels) do
            if sea.name == seaName then
                return sea.islands[math.random(#sea.islands)]
            end
        end
    end
}