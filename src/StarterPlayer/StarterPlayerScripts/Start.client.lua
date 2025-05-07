print("StarterPlayerScripts start.lua loaded...")

-- 禁用滚轮缩放
local ContextActionService = game:GetService('ContextActionService')
ContextActionService:BindAction("BlockZoom",
    function()
        return Enum.ContextActionResult.Sink
    end,
    false,
    Enum.UserInputType.MouseWheel
)