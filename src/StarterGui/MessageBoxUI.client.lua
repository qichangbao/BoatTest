--[[
模块名称：通用提示框系统
功能：实现可配置的模态对话框，支持回调函数和动态参数
作者：Trea AI
版本：1.0.0
最后修改：2024-05-28
]]
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
_screenGui.DisplayOrder = 100
_screenGui.Parent = PlayerGui

local _confirmCallFunc = nil
local _cancelCallFunc = nil
local function Hide()
    _screenGui.Enabled = false
    _confirmCallFunc = nil
    _cancelCallFunc = nil
end

UIConfig.CreateBlock(_screenGui)

local _frame, _titleLabel = UIConfig.CreateSmallFrame(_screenGui, LanguageConfig.Get(10078), function()
    Hide()
end)

-- 内容
local _contentLabel = Instance.new('TextLabel')
_contentLabel.Size = UDim2.new(1, -40, 0.6, 0)
_contentLabel.Position = UDim2.new(0, 20, 0, 20)
_contentLabel.Font = UIConfig.Font
_contentLabel.TextSize = 18
_contentLabel.TextWrapped = true
_contentLabel.TextColor3 = Color3.new(1, 1, 1)
_contentLabel.BackgroundTransparency = 1
_contentLabel.Parent = _frame

-- 确认按钮
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
    Knit.GetController('UIController').HideMessageBox:Connect(Hide)
end)