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

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateFrame(_screenGui)
_frame.Size = UDim2.new(0.4, 0, 0.3, 0)
UIConfig.CreateCorner(_frame, UDim.new(0, 8))

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

local _confirmCallFunc = nil
local _cancelCallFunc = nil
local function Hide()
    _screenGui.Enabled = false
    _confirmCallFunc = nil
    _cancelCallFunc = nil
end

local _closeButton = UIConfig.CreateCloseButton(_frame, function()
    Hide()
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0, 0)

local _confirmButton = UIConfig.CreateConfirmButton(_frame, function()
    if _confirmCallFunc then
        _confirmCallFunc()
    end
    Hide()
end)
_confirmButton.Position = UDim2.new(0.7, 0, 0.8, 0)

-- 取消按钮
local _cancelButton = UIConfig.CreateCancelButton(_frame, function()
    if _cancelCallFunc then
        _cancelCallFunc()
    end
    Hide()
end)
_cancelButton.Position = UDim2.new(0.3, 0, 0.8, 0)

local _textLabel = Instance.new('TextLabel')
_textLabel.AnchorPoint = Vector2.new(0.5, 0)
_textLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
_textLabel.Size = UDim2.new(0.9, 0, 0.6, 0)
_textLabel.TextSize = 20
_textLabel.Font = UIConfig.Font
_textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_textLabel.TextXAlignment = Enum.TextXAlignment.Center
_textLabel.TextYAlignment = Enum.TextYAlignment.Center
_textLabel.TextTruncate = Enum.TextTruncate.None
_textLabel.TextWrapped = true
_textLabel.BackgroundTransparency = 1
_textLabel.Parent = _frame

local function Show(NPCName, NpcType, index, data)
    local config = NPCConfig[NpcType][index]
    _screenGui.Enabled = true
    _titleLabel.Text = NPCName
    _textLabel.Text = config.DialogText
    if config.Buttons.Confirm and config.Buttons.Confirm.Visible then
        _confirmButton.Visible = true
    else
        _confirmButton.Visible = false
    end
    if config.Buttons.Cancel and config.Buttons.Cancel.Visible then
        _cancelButton.Visible = true
    else
        _cancelButton.Visible = false
    end
    if config.Buttons.Confirm and config.Buttons.Confirm.Text then
        _confirmButton.Text = config.Buttons.Confirm.Text
    else
        _confirmButton.Text = LanguageConfig.Get(10002)
    end
    if config.Buttons.Cancel and config.Buttons.Cancel.Text then
        _cancelButton.Text = config.Buttons.Cancel.Text
    else
        _cancelButton.Text = LanguageConfig.Get(10003)
    end

    if _confirmButton.Visible and _cancelButton.Visible then
        _confirmButton.Position = UDim2.new(0.7, 0, 0.8, 0)
        _cancelButton.Position = UDim2.new(0.3, 0, 0.8, 0)
    elseif _confirmButton.Visible then
        _confirmButton.Position = UDim2.new(0.5, 0, 0.8, 0)
    elseif _cancelButton.Visible then
        _cancelButton.Position = UDim2.new(0.5, 0, 0.8, 0)
    end
    
    _confirmCallFunc = data.ConfirmCallFunc
    _cancelCallFunc = data.CancelCallFunc
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowNpcDialogUI:Connect(function(NPCName, NpcType, index, data)
        Show(NPCName, NpcType, index, data)
    end)
    Knit.GetController('UIController').CloseNpcDialogUI:Connect(function()
        Hide()
    end)
end):catch(warn)