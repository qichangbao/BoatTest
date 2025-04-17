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
    local hp = player:GetAttribute('Health')
    local curHp = math.max(hp + changeHp, 0)
    player:SetAttribute('Health', curHp)
end

function TriggerService:KnitInit()
    print('TriggerService initialized')
end

function TriggerService:KnitStart()
    print('TriggerService started')
end

return TriggerService