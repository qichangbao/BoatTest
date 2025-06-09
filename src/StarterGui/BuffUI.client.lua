local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local _screenGui = Instance.new("ScreenGui")
_screenGui.Name = "BuffUI_GUI"
_screenGui.ResetOnSpawn = false
_screenGui.Enabled = false
_screenGui.Parent = playerGui

-- 主框架
local _frame = Instance.new("Frame")
_frame.Name = "BuffFrame"
_frame.Size = UDim2.new(0, 400, 0, 300)
_frame.Position = UDim2.new(0.5, -200, 0.5, -150)
_frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
_frame.BackgroundTransparency = 0.1
_frame.BorderSizePixel = 0
_frame.Parent = _screenGui
UIConfig.CreateCorner(_frame, UDim.new(0, 8))

-- 标题栏
local _titleBar = Instance.new('Frame')
_titleBar.Size = UDim2.new(1, 0, 0.15, 0)
_titleBar.Position = UDim2.new(0, 0, 0, 0)
_titleBar.BackgroundColor3 = Color3.fromRGB(103, 80, 164)
_titleBar.Parent = _frame
UIConfig.CreateCorner(_titleBar, UDim.new(0, 8))

-- 标题
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "当前效果"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = UIConfig.Font
titleLabel.Parent = _titleBar

-- 关闭按钮
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = UIConfig.Font
closeButton.Parent = _frame
UIConfig.CreateCorner(closeButton)

-- 关闭按钮点击事件
closeButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
end)

-- BUFF列表容器
local _buffList = Instance.new("ScrollingFrame")
_buffList.Name = "BuffList"
_buffList.Size = UDim2.new(1, -20, 1, -60)
_buffList.Position = UDim2.new(0, 10, 0, 50)
_buffList.BackgroundTransparency = 1
_buffList.BorderSizePixel = 0
_buffList.ScrollBarThickness = 6
_buffList.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
_buffList.Parent = _frame

-- 列表布局
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = _buffList

-- 创建单个BUFF显示项
local function createBuffItem(buffId, buffType, remainingTime, config)
    local buffItem = Instance.new("Frame")
    buffItem.Name = buffId .. "_" .. buffType
    buffItem.Size = UDim2.new(1, -8, 0, 25)
    buffItem.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    buffItem.BorderSizePixel = 0
    buffItem.Parent = _buffList
    
    UIConfig.CreateCorner(buffItem, UDim.new(0, 8))
    
    -- 格式化效果显示文本
    local function formatEffectText()
        local effectText = ""
        if config.effectType == "additive" then
            effectText = string.format("+%.0f", config.value)
        elseif config.effectType == "multiplier" then
            effectText = string.format("×%.1f", config.value)
        elseif config.effectType == "chance" then
            effectText = string.format("+%.0f%%", config.value * 100)
        else
            effectText = string.format("+%.1f", config.value)
        end
        return effectText
    end
    
    -- BUFF名称和效果
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -80, 1, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.BackgroundTransparency = 1
    
    -- 组合显示名称和效果值
    local displayName = config.displayName or buffId
    local effectText = formatEffectText()
    nameLabel.Text = displayName .. " (" .. effectText .. ")"
    
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = UIConfig.Font
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = buffItem
    
    -- 剩余时间
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 50, 1, 0)
    timeLabel.Position = UDim2.new(1, -52, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = string.format("%.0fs", remainingTime)
    timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    timeLabel.TextScaled = true
    timeLabel.Font = UIConfig.Font
    timeLabel.Parent = buffItem
    
    return buffItem
end

-- 更新BUFF显示
local function updateBuffDisplay()
    -- 清除现有显示
    for _, child in pairs(_buffList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- 重新创建BUFF显示
    for buffKey, buffData in pairs(ClientData.ActiveBuffs) do
        local buffId, buffType = buffKey:match("(.+)_(.+)")
        local buffItem = createBuffItem(buffId, buffType, buffData.remainingTime, buffData.config)
        
        -- 更新时间显示和颜色
        local timeLabel = buffItem:FindFirstChild("TimeLabel")
        if timeLabel then
            timeLabel.Text = string.format("%.0fs", buffData.remainingTime)
            
            -- 时间不足10秒时变红
            if buffData.remainingTime <= 10 then
                timeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            else
                timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end
    
    -- 更新滚动框大小
    local contentSize = #_buffList:GetChildren() * 27 -- 25 + 2 padding
    _buffList.CanvasSize = UDim2.new(0, 0, 0, contentSize)
end

-- 等待Knit启动
Knit.OnStart():andThen(function()
    local UIController = Knit.GetController('UIController')
    local RunService = game:GetService("RunService")
    local heartbeatConnection = nil
    
    -- 实时更新界面显示的函数
    local function updateUIDisplay()
        if _screenGui.Enabled then
            for buffKey, buffData in pairs(ClientData.ActiveBuffs) do
                local buffItem = _buffList:FindFirstChild(buffKey)
                if buffItem then
                    local timeLabel = buffItem:FindFirstChild("TimeLabel")
                    if timeLabel then
                        timeLabel.Text = string.format("%.0fs", buffData.remainingTime)
                        
                        -- 时间不足10秒时变红
                        if buffData.remainingTime <= 10 then
                            timeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                        else
                            timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                        end
                    end
                end
            end
        end
    end
    
    -- 监听Buff改变事件
    UIController.BuffChanged:Connect(function()
        if _screenGui.Enabled then
            updateBuffDisplay() -- 界面打开时刷新显示
        end
    end)
    
    -- 监听显示BuffUI事件
    UIController.ShowBuffUI:Connect(function()
        _screenGui.Enabled = true
        updateBuffDisplay() -- 显示时从ClientData获取最新数据
        
        -- 启动实时更新
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
        end
        heartbeatConnection = RunService.Heartbeat:Connect(updateUIDisplay)
    end)
    
    -- 监听界面关闭，停止更新
    _screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not _screenGui.Enabled and heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
    end)
end)