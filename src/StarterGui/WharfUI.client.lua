local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local RunService = game:GetService("RunService")
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'WharfUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateFrame(_screenGui)
_frame.Size = UDim2.new(0.35, 0, 0.4, 0)
UIConfig.CreateCorner(_frame, UDim.new(0, 8))

local function Hide()
    _screenGui.Enabled = false
end

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(_frame, function()
    Hide()
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
_contentLabel.Text = LanguageConfig.Get(10035)
_contentLabel.TextSize = 18
_contentLabel.TextWrapped = true
_contentLabel.TextColor3 = Color3.new(1, 1, 1)
_contentLabel.BackgroundTransparency = 1
_contentLabel.Parent = _frame

-- 占领按钮
local _occupyButton = Instance.new('TextButton')
_occupyButton.Name = "_occupyButton"
_occupyButton.Visible = false
_occupyButton.AnchorPoint = Vector2.new(0.5, 0)
_occupyButton.Position = UDim2.new(0.7, 0, 0.7, 0)
_occupyButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_occupyButton.Text = LanguageConfig.Get(10036)
_occupyButton.TextSize = 30
_occupyButton.Font = UIConfig.Font
_occupyButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
_occupyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_occupyButton.Parent = _frame
UIConfig.CreateCorner(_occupyButton)
_occupyButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
    Knit.GetService("LandService"):StartOccupy(_titleLabel.Text)
    Knit.GetController("UIController").ShowOccupingUI:Fire(true)
end)

-- 交费按钮
local _payButton = Instance.new('TextButton')
_payButton.Name = "_payButton"
_payButton.Visible = false
_payButton.AnchorPoint = Vector2.new(0.5, 0)
_payButton.Position = UDim2.new(0.3, 0, 0.7, 0)
_payButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_payButton.Text = string.format(LanguageConfig.Get(10041), 0)
_payButton.TextSize = 30
_payButton.Font = UIConfig.Font
_payButton.BackgroundColor3 = Color3.fromRGB(243, 193, 57)
_payButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_payButton.Parent = _frame
UIConfig.CreateCorner(_payButton)
_payButton.MouseButton1Click:Connect(function()
    Hide()
    Knit.GetService("LandService"):Pay(_titleLabel.Text):andThen(function(tipId, price)
        if not price then
            Knit.GetController('UIController').ShowTip:Fire(tipId)
        else
            Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(tipId), price))
        end
    end)
end)

-- 上岛按钮
local _intoIsLandButton = Instance.new('TextButton')
_intoIsLandButton.Name = "_intoIsLandButton"
_intoIsLandButton.Visible = false
_intoIsLandButton.AnchorPoint = Vector2.new(0.5, 0)
_intoIsLandButton.Position = UDim2.new(0.5, 0, 0.7, 0)
_intoIsLandButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_intoIsLandButton.Text = LanguageConfig.Get(10040)
_intoIsLandButton.TextSize = 30
_intoIsLandButton.Font = UIConfig.Font
_intoIsLandButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
_intoIsLandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_intoIsLandButton.Parent = _frame
UIConfig.CreateCorner(_intoIsLandButton)
_intoIsLandButton.MouseButton1Click:Connect(function()
    Hide()
    Knit.GetService("LandService"):IntoIsLand(_titleLabel.Text)
end)

-- 连接Knit服务
Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowWharfUI:Connect(function(landName)
        local landData = GameConfig.FindIsLand(landName)
        if not landData then
            return
        end

        _screenGui.Enabled = true
        _frame.Visible = true
        _titleLabel.Text = landName
        _occupyButton.Visible = false
        _payButton.Visible = false
        _intoIsLandButton.Visible = false
        _contentLabel.Text = LanguageConfig.Get(10035)
        _payButton.Text = string.format(LanguageConfig.Get(10041), landData.Price or 0)

        if not landData.Price or landData.Price == 0 then
            _intoIsLandButton.Visible = true
            _occupyButton.Visible = false
            _payButton.Visible = false
            _intoIsLandButton.Position = UDim2.new(0.5, 0, 0.7, 0)
            return
        end

        if ClientData.IsLandOwners[landName] then
            if ClientData.IsLandOwners[landName].userId == Players.LocalPlayer.UserId then
                _intoIsLandButton.Visible = true
                _intoIsLandButton.Position = UDim2.new(0.5, 0, 0.7, 0)
            else
                _contentLabel.Text = string.format(LanguageConfig.Get(10046), ClientData.IsLandOwners[landName].playerName)
                _occupyButton.Visible = true
                _occupyButton.Position = UDim2.new(0.75, 0, 0.7, 0)
                _payButton.Visible = true
                _payButton.Text = string.format(LanguageConfig.Get(10041), landData.Price or 0)
                _payButton.Position = UDim2.new(0.25, 0, 0.7, 0)
            end
        else
            _occupyButton.Visible = true
            _occupyButton.Position = UDim2.new(0.5, 0, 0.7, 0)
        end
        _occupyButton.Visible = true
    end)

    Knit.GetController('UIController').HideWharfUI:Connect(function()
        Hide()
    end)
end):catch(warn)