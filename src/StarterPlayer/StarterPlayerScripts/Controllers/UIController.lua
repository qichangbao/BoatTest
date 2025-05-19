print('UIController.lua loaded')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local Signal = require(ReplicatedStorage.Packages.Knit.Signal)

local UIController = Knit.CreateController {
    Name = "UIController",
    ShowAddBoatPartButton = Signal.new(),
    ShowMessageBox = Signal.new(),
    ShowTip = Signal.new(),
    ShowAdminUI = Signal.new(),
    ShowInventoryUI = Signal.new(),
    UpdateInventoryUI = Signal.new(),
    ShowPlayersUI = Signal.new(),
    ShowGiftUI = Signal.new(),
    UpdateGoldUI = Signal.new(),
    IsAdmin = Signal.new(),
    GiftUIClose = Signal.new(),
    ShowChooseNumUI = Signal.new(),
    ShowNpcDialogUI = Signal.new(),
    CloseNpcDialogUI = Signal.new(),
}

function UIController:KnitInit()
    print('UIController initialized')
end

function UIController:KnitStart()
    print('UIController started')
end

return UIController