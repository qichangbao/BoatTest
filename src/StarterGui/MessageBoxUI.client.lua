--[[
模块名称：通用提示框系统
功能：实现可配置的模态对话框，支持回调函数和动态参数
作者：Trea AI
版本：1.0.0
最后修改：2024-05-28
]]
print('MessageBoxUI.client.lua loaded')

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'MessageBoxUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateFrame(_screenGui)
_frame.Size = UDim2.new(0.4, 0, 0.3, 0)
UIConfig.CreateCorner(_frame, UDim.new(0, 8))

local _confirmCallFunc = nil
local _cancelCallFunc = nil
local function Hide()
    _screenGui.Enabled = false
    _confirmCallFunc = nil
    _cancelCallFunc = nil
end

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(_frame, function()
    _screenGui.Enabled = false
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0.5, 0)

-- 标题
local _titleLabel = Instance.new('TextLabel')
_titleLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
_titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
_titleLabel.Font = UIConfig.Font
_titleLabel.TextSize = 22
_titleLabel.TextColor3 = Color3.new(1, 1, 1)
_titleLabel.BackgroundTransparency = 1
_titleLabel.Parent = _frame
UIConfig.CreateCorner(_titleLabel, UDim.new(0, 8))

-- 内容
local _contentLabel = Instance.new('TextLabel')
_contentLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
_contentLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
_contentLabel.Font = UIConfig.Font
_contentLabel.TextSize = 18
_contentLabel.TextWrapped = true
_contentLabel.TextColor3 = Color3.new(1, 1, 1)
_contentLabel.BackgroundTransparency = 1
_contentLabel.Parent = _frame

-- 按钮容器
local _buttonContainer = Instance.new('Frame')
_buttonContainer.Size = UDim2.new(0.8, 0, 0.2, 0)
_buttonContainer.Position = UDim2.new(0.1, 0, 0.8, 0)
_buttonContainer.BackgroundTransparency = 1
_buttonContainer.Parent = _frame

-- 确认按钮
local _confirmButton = UIConfig.CreateConfirmButton(_buttonContainer, function()
    if _confirmCallFunc then
        _confirmCallFunc()
    end
    Hide()
end)
_confirmButton.Position = UDim2.new(0.7, 0, 0.85, 0)

-- 取消按钮
local _cancelButton = UIConfig.CreateCancelButton(_buttonContainer, function()
    if _cancelCallFunc then
        _cancelCallFunc()
    end
    Hide()
end)
_cancelButton.Position = UDim2.new(0.3, 0, 0.85, 0)

local uiListLayout = Instance.new('UIListLayout')
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
uiListLayout.Padding = UDim.new(0.1, 0)
uiListLayout.Parent = _buttonContainer

local function Show(config)
    -- 设置基础属性
    _screenGui.Enabled = true
    _titleLabel.Text = config.Title or LanguageConfig.Get(10001)
    _contentLabel.Text = config.Content or ''

    _confirmButton.Text = config.ConfirmText or LanguageConfig.Get(10002)
    _cancelButton.Text = config.CancelText or LanguageConfig.Get(10003)
    -- 事件绑定
    _confirmCallFunc = config.OnConfirm
    _cancelCallFunc = config.OnCancel
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowMessageBox:Connect(Show)
end)