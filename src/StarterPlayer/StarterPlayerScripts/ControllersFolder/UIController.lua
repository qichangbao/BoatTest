local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Signal = require(ReplicatedStorage.Packages.Knit.Signal)

local UIController = Knit.CreateController {
    Name = "UIController",
    UIScripts = {},
    AddUI = Signal.new(),
    ShowAddBoatPartButton = Signal.new(),
    ShowMessageBox = Signal.new(),
    HideMessageBox = Signal.new(),
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
    ShowWharfUI = Signal.new(),
    HideWharfUI = Signal.new(),
    IsLandOwner = Signal.new(),
    IsLandOwnerChanged = Signal.new(),
    ShowSystemMessage = Signal.new(),
    BuffChanged = Signal.new(),
    ShowBuffUI = Signal.new(),
    ShowIslandManageUI = Signal.new(),
    ShowTowerSelectUI = Signal.new(),
    ShowOccupingUI = Signal.new(),
    UpdateCompassIsland = Signal.new(),
    RemoveCompassIsland = Signal.new(),
    ShowRankUI = Signal.new(),
    ShowPurchaseUI = Signal.new(),
    UpdateRankUI = Signal.new(),
    ShowBoatChooseUI = Signal.new(),
    ShowFeedbackUI = Signal.new(),
    ShowBadgeUI = Signal.new(),
    BadgeComplete = Signal.new(),
}

function UIController:KnitInit()
    self.AddUI:Connect(function(uiScript, destroyCallFunc)
        table.insert(self.UIScripts, {uiScript = uiScript, destroyCallFunc = destroyCallFunc})
    end)

    Players.LocalPlayer.CharacterAdded:Connect(function()
        print('CharacterAdded')
    end)

    Players.LocalPlayer.CharacterRemoving:Connect(function()
        print('CharacterRemoving')
        for _, uiData in ipairs(self.UIScripts) do
            if uiData.destroyCallFunc then
                uiData.destroyCallFunc()
            end
        end
        self.UIScripts = {}
    end)
end

function UIController:KnitStart()
end

return UIController