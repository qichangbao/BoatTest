require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

-- -- 禁用滚轮缩放
-- local contextActionService = game:GetService('ContextActionService')
-- contextActionService:BindAction("BlockZoom",
--     function()
--         return Enum.ContextActionResult.Sink
--     end,
--     false,
--     Enum.UserInputType.MouseWheel
-- )

local loadingUI = require(game.StarterGui:WaitForChild("LoadingUI"))
loadingUI.Show(5)

local camera = game.Workspace.CurrentCamera
local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    -- 玩家坐下时，相机会拉远与玩家的距离，因此需要在玩家坐下时，将相机会拉远与玩家的距离恢复到初始值
    humanoid.Seated:Connect(function(isSeated, seat)
        camera.CameraSubject = humanoid
    end)
end

local localPlayer = game.Players.LocalPlayer
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
else
    localPlayer.CharacterAdded:Connect(function(character)
        onCharacterAdded(character)
    end)
end