
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local BoatAttributeService = Knit.CreateService({
    Name = 'BoatAttributeService',
    Client = {
        ChangeAttribute = Knit.CreateSignal(),
    },
})

function BoatAttributeService:GetPlayerBoat(player)
    return workspace:FindFirstChild('PlayerBoat_'..player.UserId)
end

function BoatAttributeService:GetHealth(player)
    local boat = self:GetPlayerBoat(player)
    if not boat then
        return -1
    end
    return tonumber(boat:GetAttribute('Health'))
end

function BoatAttributeService.Client:GetHealth(player)
    return self.Server:GetHealth(player)
end

function BoatAttributeService:GetSpeed(player)
    local boat = self:GetPlayerBoat(player)
    if not boat then
        return -1
    end
    return tonumber(boat:GetAttribute('Speed'))
end

function BoatAttributeService.Client:GetSpeed(player)
    return self.Server:GetSpeed(player)
end

function BoatAttributeService:ChangeHealth(player, hp)
    local boat = self:GetPlayerBoat(player)
    if not boat then
        print('Boat not found for player '..player.Name)
        return
    end

    self.Client.ChangeAttribute:Fire(player, 'Health', math.max(hp, 0), boat:GetAttribute('MaxHealth'))
end

function BoatAttributeService:ChangeSpeed(player, speed)
    local boat = self:GetPlayerBoat(player)
    if not boat then
        print('Boat not found for player '..player.Name)
        return
    end

    self.Client.ChangeAttribute:Fire(player, 'Speed', math.max(speed, 0), boat:GetAttribute('MaxSpeed'))
end

return BoatAttributeService