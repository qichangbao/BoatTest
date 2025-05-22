local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface'))

local _occupyTime = 3

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'WharfUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)
local _frame = UIConfig.CreateFrame(_screenGui)
_frame.Size = UDim2.new(0.35, 0, 0.4, 0)

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(_frame, function()
    _screenGui.Enabled = false
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0, 0)

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
_occupyButton.Visible = false
_occupyButton.AnchorPoint = Vector2.new(0.5, 0)
_occupyButton.Position = UDim2.new(0.7, 0, 0.7, 0)
_occupyButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_occupyButton.Text = LanguageConfig:Get(10036)
_occupyButton.TextSize = 30
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
    countdownText.Text = tostring(_occupyTime)
    countdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownText.BackgroundTransparency = 1
    countdownText.Font = UIConfig.Font
    countdownText.TextSize = 24
    countdownText.Parent = circleContainer
    
    local function updateCountdown(timeLeft)
        countdownText.Text = tostring(timeLeft)
        if timeLeft == 0 then
            -- 倒计时结束，执行相关操作
            _screenGui.Enabled = false
            circleContainer:Destroy()
            Knit.GetService("LandService"):Occupy(_titleLabel.Text):andThen(function(tipId)
                Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig:Get(tipId), _titleLabel.Text))
            end)
            return
        end
    end
    
    for i = _occupyTime, 0, -1 do
        task.delay(_occupyTime - i, function()
            updateCountdown(i)
        end)
    end
end)

-- 交费按钮
local _payButton = Instance.new('TextButton')
_payButton.Visible = false
_payButton.AnchorPoint = Vector2.new(0.5, 0)
_payButton.Position = UDim2.new(0.3, 0, 0.7, 0)
_payButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_payButton.Text = LanguageConfig:Get(10037)
_payButton.TextSize = 30
_payButton.Font = UIConfig.Font
_payButton.BackgroundColor3 = Color3.fromRGB(243, 193, 57)
_payButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_payButton.Parent = _frame
_payButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
    Knit.GetService("LandService"):Pay(_titleLabel.Text):andThen(function(tipId, price)
        if not price then
            Knit.GetController('UIController').ShowTip:Fire(tipId)
        else
            Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig:Get(tipId), price))
        end
    end)
end)

-- 上岛按钮
local _intoIsLandButton = Instance.new('TextButton')
_intoIsLandButton.Visible = false
_intoIsLandButton.AnchorPoint = Vector2.new(0.5, 0)
_intoIsLandButton.Position = UDim2.new(0.5, 0, 0.7, 0)
_intoIsLandButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_intoIsLandButton.Text = LanguageConfig:Get(10040)
_intoIsLandButton.TextSize = 30
_intoIsLandButton.Font = UIConfig.Font
_intoIsLandButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
_intoIsLandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_intoIsLandButton.Parent = _frame
_intoIsLandButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
    Knit.GetService("LandService"):IntoIsLand(_titleLabel.Text)
end)

-- 连接Knit服务
Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowWharfUI:Connect(function(landName)
        local landData = Interface.FindIsLand(landName)
        if not landData then
            return
        end

        _screenGui.Enabled = true
        _titleLabel.Text = landName
        _occupyButton.Visible = false
        _payButton.Visible = false
        _intoIsLandButton.Visible = false

        if landData.Price == 0 then
            _intoIsLandButton.Visible = true
            _occupyButton.Visible = false
            _payButton.Visible = false
            _intoIsLandButton.Position = UDim2.new(0.5, 0, 0.7, 0)
            return
        end

        local clientData = require(StarterPlayer.StarterPlayerScripts:WaitForChild("ClientData"))
        if clientData.IsLandOwners[landName] then
            if clientData.IsLandOwners[landName].userId == Players.LocalPlayer.UserId then
                _intoIsLandButton.Visible = true
                _intoIsLandButton.Position = UDim2.new(0.5, 0, 0.7, 0)
            else
                _occupyButton.Visible = true
                _occupyButton.Position = UDim2.new(0.75, 0, 0.7, 0)
                _payButton.Visible = true
                _payButton.Position = UDim2.new(0.25, 0, 0.7, 0)
            end
        else
            _occupyButton.Visible = true
            _occupyButton.Position = UDim2.new(0.5, 0, 0.7, 0)
        end
    end)
end):catch(warn)