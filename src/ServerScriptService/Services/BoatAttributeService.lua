local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local BoatAttributeService = Knit.CreateService({
    Name = 'BoatAttributeService',
    Client = {
        ChangeAttribute = Knit.CreateSignal(),
        ChangeGold = Knit.CreateSignal(),
    },
})

function BoatAttributeService:GetPlayerBoat(player)
    return workspace:FindFirstChild('PlayerBoat_'..player.UserId)
end

function BoatAttributeService:GetHealth(player)
    return player:GetAttribute('Health')
end

function BoatAttributeService.Client:GetHealth(player)
    return self.Server:GetHealth(player)
end

function BoatAttributeService:ChangeHealth(player, hp, maxHp)
    self.Client.ChangeAttribute:Fire(player, 'Health', math.max(hp, 0), maxHp)
end

function BoatAttributeService:GetSpeed(player)
    return player:GetAttribute('Speed')
end

function BoatAttributeService.Client:GetSpeed(player)
    return self.Server:GetSpeed(player)
end

function BoatAttributeService:ChangeSpeed(player, speed, maxSpeed)
    self.Client.ChangeAttribute:Fire(player, 'Speed', math.max(speed, 0), maxSpeed)
end

function BoatAttributeService:ChangeGold(player, gold)
    self.Client.ChangeGold:Fire(player, math.max(gold, 0))
end

function BoatAttributeService:KnitInit()
    print('BoatAttributeService initialized')

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            character:SetAttribute("ModelType", "Player")
        end)
    
        player:GetAttributeChangedSignal('Gold'):Connect(function()
            self:ChangeGold(player, player:GetAttribute('Gold'))
        end)
    
        -- 初始化重生点
        player.RespawnLocation = game.Workspace.LandSpawnLocation
        player:SetAttribute("Gold", 1000)
    end)
end

function BoatAttributeService:KnitStart()
    print('BoatAttributeService started')
end

return BoatAttributeService