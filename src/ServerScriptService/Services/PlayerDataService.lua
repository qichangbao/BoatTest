print('PlayerDataService loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerDataService = Knit.CreateService({
    Name = 'PlayerDataService',
    Client = {
        GoodChanged = Knit.CreateSignal(),
    },
})

function PlayerDataService:KnitInit()
    print('PlayerDataService initialized')
    Players.PlayerAdded:Connect(function(player)
        local function setupCharacter(character)
            character:SetAttribute("Gold", 100)
            self.Client.GoodChanged:Fire(player, 100)
        end
    
        -- 初始化已存在的角色
        if player.Character then
            setupCharacter(player.Character)
        else
            player.CharacterAdded:Connect(setupCharacter)
        end
    
        -- 初始化重生点
        player.RespawnLocation = game.Workspace.LandSpawnLocation
    end)
end

function PlayerDataService:KnitStart()
    print('PlayerDataService started')
end

return PlayerDataService