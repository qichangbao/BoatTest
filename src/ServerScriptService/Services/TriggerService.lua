print('TriggerService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local TriggerService = Knit.CreateService({
    Name = 'TriggerService',
    Client = {
        CreateWave = Knit.CreateSignal(),
    },
})

-- 波浪碰撞到船时触发的事件
function TriggerService.Client:WaveHitBoat(player, changeHp)
    local BoatAttribute = require(game.ServerScriptService:WaitForChild('BoatFolder'):WaitForChild('BoatAttribute'))
    local boatModel = BoatAttribute:GetPlayerBoat(player)
    if not boatModel then
        return
    end

    BoatAttribute:ChangeHealth(player, changeHp)
end

function TriggerService:KnitInit()
    print('TriggerService initialized')
end

function TriggerService:KnitStart()
    print('TriggerService started')
end

return TriggerService