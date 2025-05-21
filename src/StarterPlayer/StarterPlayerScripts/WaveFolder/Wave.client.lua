print('Wave.lua loaded')
local TweenService = game:GetService('TweenService')
local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))


Knit:OnStart():andThen(function()
    -- 创建波浪
    Knit.GetService('TriggerService').CreateWave:Connect(function(data)
        local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local distance = (humanoidRootPart.Position - data.Position).Magnitude
            if distance > 400 then
                return
            end
        end
    end)
end):catch(warn)