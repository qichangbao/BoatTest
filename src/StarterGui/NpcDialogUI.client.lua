local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local NPCConfig = require(ConfigFolder:WaitForChild("NpcConfig"))
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'NpcDialogUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

local _frame = Instance.new('Frame')
_frame.AnchorPoint = Vector2.new(0.5, 0.5)
_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_frame.Size = UDim2.new(0.4, 0, 0.3, 0)  -- 相对屏幕比例
_frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
_frame.BackgroundTransparency = 0.1
_frame.BorderSizePixel = 0
_frame.Parent = _screenGui

local _confirmCallFunc = nil
local _cancelCallFunc = nil
local function Hide()
    _screenGui.Enabled = false
    _confirmCallFunc = nil
    _cancelCallFunc = nil
end

local _closeButton = UIConfig.CreateCloseButton(function()
    Hide()
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0, 0)
_closeButton.Parent = _frame

local _confirmButton = UIConfig.CreateConfirmButton(function()
    if _confirmCallFunc then
        _confirmCallFunc()
    end
    Hide()
end)
_confirmButton.Position = UDim2.new(0.7, 0, 0.85, 0)
_confirmButton.Parent = _frame

-- 取消按钮
local _cancelButton = UIConfig.CreateCancelButton(function()
    if _cancelCallFunc then
        _cancelCallFunc()
    end
    Hide()
end)
_cancelButton.Position = UDim2.new(0.3, 0, 0.85, 0)
_cancelButton.Parent = _frame

local _textLabel = Instance.new('TextLabel')
_textLabel.AnchorPoint = Vector2.new(0.5, 0)
_textLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
_textLabel.Size = UDim2.new(0.9, 0, 0.6, 0)
_textLabel.TextSize = 20
_textLabel.Font = UIConfig.Font
_textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_textLabel.TextXAlignment = Enum.TextXAlignment.Center
_textLabel.TextYAlignment = Enum.TextYAlignment.Top
_textLabel.TextTruncate = Enum.TextTruncate.None
_textLabel.TextWrapped = true
_textLabel.BackgroundTransparency = 1
_textLabel.Parent = _frame

local function Show(NpcType, data)
    local config = NPCConfig[NpcType]
    _screenGui.Enabled = true
    if config.Buttons.Confirm and config.Buttons.Confirm.Text then
        _confirmButton.Text = config.Buttons.Confirm.Text
    else
        _confirmButton.Text = LanguageConfig:Get(10002)
    end
    if config.Buttons.Cancel and config.Buttons.Cancel.Text then
        _cancelButton.Text = config.Buttons.Cancel.Text
    else
        _cancelButton.Text = LanguageConfig:Get(10003)
    end
    _textLabel.Text = config.DialogText
    
    _confirmCallFunc = data.ConfirmCallFunc
    _cancelCallFunc = data.CancelCallFunc
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowNpcDialogUI:Connect(function(NpcType, data)
        Show(NpcType, data)
    end)
    Knit.GetController('UIController').CloseNpcDialogUI:Connect(function()
        Hide()
    end)
end):catch(warn)