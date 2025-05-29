print('TriggerService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local TriggerService = Knit.CreateService({
    Name = 'TriggerService',
    Client = {
        CreateWave = Knit.CreateSignal(),
    },
})

-- 波浪碰撞到船时触发的事件
function TriggerService.Client:WaveHitBoat(player, changeHp)
    local boat = Interface.GetBoatByPlayerUserId(player.UserId)
    if not boat then
        return
    end
    local hp = boat:GetAttribute('Health')
    local curHp = math.max(hp - changeHp, 0)
    boat:SetAttribute('Health', curHp)
end

function TriggerService:KnitInit()
    print('TriggerService initialized')
end

function TriggerService:KnitStart()
    print('TriggerService started')
end

return TriggerService