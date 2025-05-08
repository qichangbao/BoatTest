print("StarterPlayerScripts start.lua loaded...")

-- 禁用滚轮缩放
local contextActionService = game:GetService('ContextActionService')
contextActionService:BindAction("BlockZoom",
    function()
        return Enum.ContextActionResult.Sink
    end,
    false,
    Enum.UserInputType.MouseWheel
)

local loadingUI = require(game.StarterGui:WaitForChild("LoadingUI"))
loadingUI.Show(3)

require(game.StarterGui:WaitForChild("AdminPanelUI"))
local messageBoxUI = require(game.StarterGui:WaitForChild("MessageBoxUI"))
messageBoxUI:Init()