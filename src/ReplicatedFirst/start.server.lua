print("start.lua loaded")

-- 确保脚本正常运行的调试信息
local success, err = pcall(function()
    -- 添加一些更明显的输出
    warn("ReplicatedFirst 中的 start 脚本正在执行!")
    
    -- 可以添加一些延迟来确保输出不会被其他消息淹没
    task.wait(1)
    print("过了1秒，start.lua 仍在执行中")
    
    -- 使用BindableEvent确认脚本执行
    local event = Instance.new("BindableEvent")
    event.Name = "StartScriptExecuted"
    event.Parent = game:GetService("ReplicatedStorage")
    event:Fire()
    
    -- 确认脚本是在客户端还是服务器运行
    if game:GetService("RunService"):IsClient() then
        print("此脚本正在客户端运行")
    else
        print("此脚本正在服务器运行")
    end
end)

if not success then
    warn("start.lua 执行时发生错误:", err)
end

