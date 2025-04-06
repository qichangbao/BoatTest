print("start.lua loaded")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- 初始化Knit框架
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'))
Knit.AddControllers(game.StarterPlayer.StarterPlayerScripts:WaitForChild('Controllers'))
Knit.Start():andThen(function()
    print("Knit Started")
end):catch(warn)