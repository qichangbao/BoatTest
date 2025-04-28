print("ReplicatedFirst start.lua loaded")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
-- 初始化Knit框架
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'):waitForChild('Knit'))
Knit.AddControllers(StarterPlayer:WaitForChild('StarterPlayerScripts'):WaitForChild('Controllers'))

Knit.Start():andThen(function()
    print("Knit Client Started")
    -- 在此处调用StarterGui相关服务初始化代码
    -- 确保所有GetService调用都在此回调之后
end):catch(warn)