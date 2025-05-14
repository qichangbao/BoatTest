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

local camera = game.Workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer
local humanoid = localPlayer.Character:WaitForChild("Humanoid")
-- 玩家坐下时，相机会拉远与玩家的距离，因此需要在玩家坐下时，将相机会拉远与玩家的距离恢复到初始值
humanoid.Seated:Connect(function(isSeated, seat)
    camera.CameraSubject = humanoid
end)