print('TipController.lua loaded')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local Signal = require(ReplicatedStorage.Packages.Knit.Signal)

local TipController = Knit.CreateController {
    Name = "TipController",
    Tip = Signal.new()
}

function TipController:KnitInit()
    print('TipController initialized')
end

function TipController:KnitStart()
    print('TipController started')
end

return TipController