print('SystemService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local SystemService = Knit.CreateService {
    Name = "SystemService",
    Client = {
        Tip = Knit.CreateSignal(),
    }
}

function SystemService:SendTip(player, tipId, name)
    self.Client.Tip:Fire(player, tipId, name)
end

return SystemService