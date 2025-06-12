local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))

local BoatAttributeService = Knit.CreateService({
    Name = 'BoatAttributeService',
    Client = {
        ChangeAttribute = Knit.CreateSignal(),
    },
})

function BoatAttributeService:GetBoatHealth(player)
    local boat = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface")).GetBoatByPlayerUserId(player.UserId)
    if boat then
        return boat:GetAttribute('Health')
    end
    return 0
end

function BoatAttributeService.Client:GetBoatHealth(player)
    return self.Server:GetBoatHealth(player)
end

function BoatAttributeService:ChangeBoatHealth(player, hp, maxHp)
    self.Client.ChangeAttribute:Fire(player, 'Health', math.max(hp, 0), maxHp)
end

function BoatAttributeService:GetBoatSpeed(player)
    local boat = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface")).GetBoatByPlayerUserId(player.UserId)
    if boat then
        return boat:GetAttribute('Speed')
    end
    return 0
end

function BoatAttributeService.Client:GetBoatSpeed(player)
    return self.Server:GetBoatSpeed(player)
end

function BoatAttributeService:ChangeBoatSpeed(player, speed, maxSpeed)
    self.Client.ChangeAttribute:Fire(player, 'Speed', math.max(speed, 0), maxSpeed)
end

function BoatAttributeService:KnitInit()
end

function BoatAttributeService:KnitStart()
end

return BoatAttributeService