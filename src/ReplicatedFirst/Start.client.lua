local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

math.randomseed(os.time())
-- 初始化Knit框架
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Knit'):waitForChild('Knit'))
Knit.AddControllers(StarterPlayer:WaitForChild('StarterPlayerScripts'):WaitForChild('ControllersFolder'))

Knit.Start():andThen(function()
    -- 在此处调用StarterGui相关服务初始化代码
    -- 确保所有GetService调用都在此回调之后
end):catch(warn)