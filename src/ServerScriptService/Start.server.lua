print("ServerScriptService start.lua loaded")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 初始化Knit框架
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
Knit.AddServices(game.ServerScriptService.Services)
Knit.Start():andThen(function()
    print("Knit Server Started")
end):catch(warn)

print("服务器脚本初始化完成")