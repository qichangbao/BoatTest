local BoatAttribute = {}
BoatAttribute.__index = BoatAttribute
setmetatable({}, BoatAttribute)

BoatAttribute.BoatProperties = {
    MaxHealth = 100,
    Speed = 25,
    Durability = 1.0
}

function BoatAttribute:GetHealth(player)
    local boat = self:GetPlayerBoat(player)
    return boat and boat:GetAttribute('Health') or self.BoatProperties.MaxHealth
end

function BoatAttribute:GetPlayerBoat(player)
    return workspace:FindFirstChild('PlayerBoat_'..player.UserId)
end

return BoatAttribute