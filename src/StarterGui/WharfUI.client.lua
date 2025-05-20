local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'WharfUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

-- 禁用背景点击
local _blocker = Instance.new("TextButton")
_blocker.Size = UDim2.new(1, 0, 1, 0)
_blocker.BackgroundTransparency = 1
_blocker.Text = ""
_blocker.Parent = _screenGui

-- 新增模态背景
local modalFrame = Instance.new("Frame")
modalFrame.Size = UDim2.new(1, 0, 1, 0)
modalFrame.BackgroundTransparency = 0.5
modalFrame.BackgroundColor3 = Color3.new(0, 0, 0)
modalFrame.Parent = _screenGui

-- 主框架
local _frame = Instance.new('Frame')
_frame.AnchorPoint = Vector2.new(0.5, 0.5)
_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_frame.Size = UDim2.new(0.35, 0, 0.4, 0)
_frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
_frame.BackgroundTransparency = 0.1
_frame.BorderSizePixel = 0
_frame.Parent = _screenGui

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(function()
    _screenGui.Enabled = false
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0, 0)
_closeButton.Parent = _frame

-- title显示
local _titleLabel = Instance.new('TextLabel')
_titleLabel.AnchorPoint = Vector2.new(0.5, 0)
_titleLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
_titleLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
_titleLabel.TextSize = 20
_titleLabel.Font = UIConfig.Font
_titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_titleLabel.TextXAlignment = Enum.TextXAlignment.Center
_titleLabel.TextYAlignment = Enum.TextYAlignment.Top
_titleLabel.TextWrapped = true
_titleLabel.BackgroundTransparency = 1
_titleLabel.Parent = _frame

-- 内容显示
local _contentLabel = Instance.new('TextLabel')
_contentLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
_contentLabel.Position = UDim2.new(0.1, 0, 0.15, 0)
_contentLabel.Font = UIConfig.Font
_contentLabel.Text = LanguageConfig:Get(10035)
_contentLabel.TextSize = 18
_contentLabel.TextWrapped = true
_contentLabel.TextColor3 = Color3.new(1, 1, 1)
_contentLabel.BackgroundTransparency = 1
_contentLabel.Parent = _frame

-- 占领按钮
local _occupyButton = Instance.new('TextButton')
_occupyButton.AnchorPoint = Vector2.new(0.5, 0)
_occupyButton.Position = UDim2.new(0.5, 0, 0.65, 0)
_occupyButton.Size = UDim2.new(0.7, 0, 0.1, 0)
_occupyButton.Text = LanguageConfig:Get(10036)
_occupyButton.TextSize = 18
_occupyButton.Font = UIConfig.Font
_occupyButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
_occupyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_occupyButton.Parent = _frame
_occupyButton.MouseButton1Click:Connect(function()
    local circleContainer = Instance.new("Frame")
    circleContainer.Name = "CircleProgress"
    circleContainer.Size = UDim2.new(0.2, 0, 0.2, 0)
    circleContainer.Position = UDim2.new(0.5, 0, 0.7, 0)
    circleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    circleContainer.BackgroundTransparency = 1
    circleContainer.Parent = _frame
    
    local countdownText = Instance.new("TextLabel")
    countdownText.Name = "Countdown"
    countdownText.Size = UDim2.new(0.6, 0, 0.6, 0)
    countdownText.Position = UDim2.new(0.2, 0, 0.2, 0)
    countdownText.Text = "10"
    countdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownText.BackgroundTransparency = 1
    countdownText.Font = UIConfig.Font
    countdownText.TextSize = 24
    countdownText.Parent = circleContainer
    
    local function updateCountdown(timeLeft)
        countdownText.Text = tostring(timeLeft)
        if timeLeft == 0 then
            -- 倒计时结束，执行相关操作
            circleContainer:Destroy()
            Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig:Get(10038), _titleLabel.Text))
        end
    end
    
    for i = 10, 0, -1 do
        task.delay(10 - i, function()
            updateCountdown(i)
        end)
    end
end)

-- 交费按钮
local _payButton = Instance.new('TextButton')
_payButton.AnchorPoint = Vector2.new(0.5, 0)
_payButton.Position = UDim2.new(0.5, 0, 0.8, 0)
_payButton.Size = UDim2.new(0.7, 0, 0.1, 0)
_payButton.Text = LanguageConfig:Get(10037)
_payButton.TextSize = 18
_payButton.Font = UIConfig.Font
_payButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
_payButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_payButton.Parent = _frame
_payButton.MouseButton1Click:Connect(function()
end)

-- 连接Knit服务
Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowWharfUI:Connect(function(landName)
        _titleLabel.Text = landName
        _screenGui.Enabled = true
    end)
end):catch(warn)