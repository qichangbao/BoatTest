local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local PlayerAttributeService = Knit.CreateService({
    Name = 'PlayerAttributeService',
    Client = {
        ChangeAttribute = Knit.CreateSignal(),
        ChangeGold = Knit.CreateSignal(),
    },
})

function PlayerAttributeService:GetPlayerHealth(player)
    if player.Humanoid then
        return player.Humanoid.Health
    end
    return 0
end

function PlayerAttributeService.Client:GetPlayerHealth(player)
    return self.Server:GetPlayerHealth(player)
end

function PlayerAttributeService:ChangePlayerHealth(player, hp, maxHp)
    self.Client.ChangeAttribute:Fire(player, 'Health', math.max(hp, 0), maxHp)
end

function PlayerAttributeService:GetPlayerSpeed(player)
    if player.Humanoid then
        return player.Humanoid.WalkSpeed
    end
    return 0
end

function PlayerAttributeService.Client:GetPlayerSpeed(player)
    return self.Server:GetPlayerSpeed(player)
end

function PlayerAttributeService:ChangePlayerSpeed(player, speed, maxSpeed)
    self.Client.ChangeAttribute:Fire(player, 'Speed', math.max(speed, 0), maxSpeed)
end

function PlayerAttributeService:ChangeGold(player, gold)
    self.Client.ChangeGold:Fire(player, math.max(gold, 0))
end

function PlayerAttributeService:KnitInit()
    print('PlayerAttributeService initialized')

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local boat = Knit.GetService('BoatAttributeService'):GetPlayerBoat(player)
            if boat then
                boat:Destroy()
            end
            character:SetAttribute("ModelType", "Player")
        end)
    
        player:GetAttributeChangedSignal('Gold'):Connect(function()
            self:ChangeGold(player, player:GetAttribute('Gold'))
        end)
    
        -- 初始化重生点
        player.RespawnLocation = game.Workspace.LandSpawnLocation
        player:SetAttribute("Gold", 1000)
        --CollectionService:AddTag(player, "Player")
    end)

    Players.PlayerRemoving:Connect(function(player)
        --CollectionService:RemoveTag(player, "Player")
    end)
end

function PlayerAttributeService:KnitStart()
    print('PlayerAttributeService started')
end

return PlayerAttributeService