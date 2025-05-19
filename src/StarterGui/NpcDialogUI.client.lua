local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local NPCConfig = require(ConfigFolder:WaitForChild("NpcConfig"))
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'NpcDialogUI_Gui'
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

local _frame = Instance.new('Frame')
_frame.AnchorPoint = Vector2.new(0.5, 0.5)
_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_frame.Size = UDim2.new(0, 300, 0, 200)
_frame.Parent = _screenGui

local _confirmConnection = nil
local _cancelConnection = nil
local function CloseUI()
    _screenGui.Enabled = false
    if _confirmConnection then
        _confirmConnection:Disconnect()
        _confirmConnection = nil
    end
    if _cancelConnection then
        _cancelConnection:Disconnect()
        _cancelConnection = nil
    end
end

local _closeButton = UIConfig.CreateCloseButton(function()
    CloseUI()
end)
_closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0, 0)
_closeButton.Parent = _frame

local _confirmButton = Instance.new('TextButton')
_confirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
_confirmButton.Size = UDim2.new(0.2, 0, 0.2, 0)
_confirmButton.Position = UDim2.new(0.3, 0, 0.9, 0)
_confirmButton.TextSize = 18
_confirmButton.Parent = _frame

local _cancelButton = Instance.new('TextButton')
_cancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
_cancelButton.Size = UDim2.new(0.2, 0, 0.2, 0)
_cancelButton.Position = UDim2.new(0.7, 0, 0.9, 0)
_cancelButton.TextSize = 18
_cancelButton.Parent = _frame

local _textLabel = Instance.new('TextLabel')
_textLabel.AnchorPoint = Vector2.new(0, 0)
_textLabel.Position = UDim2.new(0, 20, 0, 10)  -- 左缩进20像素
_textLabel.Size = UDim2.new(0.8, 0, 0.7, 0)     -- 右侧留30像素边距
_textLabel.TextSize = 18
_textLabel.TextXAlignment = Enum.TextXAlignment.Left
_textLabel.TextYAlignment = Enum.TextYAlignment.Top
_textLabel.TextTruncate = Enum.TextTruncate.None
_textLabel.TextWrapped = true
_textLabel.Parent = _frame

local function ShowPrompt(NpcType, data)
    local config = NPCConfig[NpcType]
    _screenGui.Enabled = true
    if config.Buttons.Confirm and config.Buttons.Confirm.Text then
        _confirmButton.Text = config.Buttons.Confirm.Text
    else
        _confirmButton.Text = LanguageConfig:Get(10002)
    end
    if config.Buttons.Cancel and config.Buttons.Cancel.Text then
        _closeButton.Text = config.Buttons.Cancel.Text
    else
        _closeButton.Text = LanguageConfig:Get(10003)
    end
    _textLabel.Text = config.DialogText
    
    _confirmConnection = _confirmButton.MouseButton1Click:Connect(function()
        if config.Buttons.Confirm and config.Buttons.Confirm.Callback then
            if config.Buttons.Confirm.Callback == 'SetSpawnLocation' then
                Knit.GetService("PlayerAttributeService"):SetSpawnLocation(data.AreaName)
            end
        end
        CloseUI()
    end)
    _cancelConnection = _closeButton.MouseButton1Click:Connect(function()
        if config.Buttons.Cancel and config.Buttons.Cancel.Callback then
        end
        CloseUI()
    end)
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').ShowNpcDialogUI:Connect(function(NpcType, data)
        ShowPrompt(NpcType, data)
    end)
    Knit.GetController('UIController').CloseNpcDialogUI:Connect(function()
        CloseUI()
    end)
end):catch(warn)