local BoatAttribute = {}
BoatAttribute.__index = BoatAttribute
setmetatable({}, BoatAttribute)

BoatAttribute.BoatProperties = {
    Speed = 25,
    Durability = 1.0
}

function BoatAttribute:GetHealth(player)
    local boat = self:GetPlayerBoat(player)
    return boat and boat:GetAttribute('Health')
end

function BoatAttribute:GetPlayerBoat(player)
    return workspace:FindFirstChild('PlayerBoat_'..player.UserId)
end

function BoatAttribute:ChangeHealth(player, hp)
    local boat = self:GetPlayerBoat(player)
    if not boat then
        print('Boat not found for player '..player.Name)
        return
    end
    
    local curHp = boat:GetAttribute('Health') + hp
    if curHp <= 0 then
        print('Boat destroyed for player '..player.Name)
        local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))
        Knit.GetService('BoatAssemblingService'):DestroyBoat(player, boat)
        return
    end
    boat:SetAttribute('Health', curHp)
end

return BoatAttribute