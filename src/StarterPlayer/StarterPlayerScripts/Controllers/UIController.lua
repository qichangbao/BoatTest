print('UIController.lua loaded')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local Signal = require(ReplicatedStorage.Packages.Knit.Signal)

local UIController = Knit.CreateController {
    Name = "UIController",
    ShowAddBoatPartButton = Signal.new()
}

function UIController:KnitInit()
    print('UIController initialized')
end

function UIController:KnitStart()
    print('UIController started')
end

return UIController