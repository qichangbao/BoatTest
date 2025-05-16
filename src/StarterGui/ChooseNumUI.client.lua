-- 数量选择界面
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

-- 按钮交互逻辑
local _currentCount = 1
local _maxCount = 0
local _callback = nil

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'ChooseNumUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

local _blocker = Instance.new('TextButton')
_blocker.Size = UDim2.new(1, 0, 1, 0)
_blocker.BackgroundTransparency = 1
_blocker.Text = ""
_blocker.Active = true
_blocker.Parent = _screenGui

-- 拦截所有输入事件
_blocker.MouseButton1Click:Connect(function()
    -- 空事件处理，仅用于阻止穿透
end)

-- 创建数量选择界面
local _selectionFrame = Instance.new('Frame')
_selectionFrame.Size = UDim2.new(0, 300, 0, 150)
_selectionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
_selectionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
_selectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
_selectionFrame.BackgroundTransparency = 0.1
_selectionFrame.Parent = _screenGui

-- 标题栏
local _titleBar = Instance.new('Frame')
_titleBar.Size = UDim2.new(1, 0, 0.15, 0)
_titleBar.Position = UDim2.new(0, 0, 0, 0)
_titleBar.BackgroundColor3 = Color3.fromRGB(103, 80, 164)
_titleBar.Parent = _selectionFrame

local _titleLabel = Instance.new('TextLabel')
_titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
_titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
_titleLabel.Text = LanguageConfig:Get(10029)
_titleLabel.Font = Enum.Font.GothamBold
_titleLabel.TextSize = 20
_titleLabel.TextColor3 = Color3.new(1, 1, 1)
_titleLabel.BackgroundTransparency = 1
_titleLabel.Parent = _titleBar

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(function()
    _screenGui.Enabled = false
    _callback = nil
end)
_closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0.5, 0)
_closeButton.Parent = _titleBar

-- 加减按钮
local _minusButton = Instance.new('TextButton')
_minusButton.Size = UDim2.new(0, 50, 0, 50)
_minusButton.Position = UDim2.new(0.2, 0, 0.4, 0)
_minusButton.AnchorPoint = Vector2.new(0.5, 0.5)
_minusButton.Text = '-'
_minusButton.Font = Enum.Font.GothamBold
_minusButton.TextSize = 24
_minusButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
_minusButton.Parent = _selectionFrame

local _plusButton = Instance.new('TextButton')
_plusButton.Size = UDim2.new(0, 50, 0, 50)
_plusButton.Position = UDim2.new(0.8, 0, 0.4, 0)
_plusButton.AnchorPoint = Vector2.new(0.5, 0.5)
_plusButton.Text = '+'
_plusButton.Font = Enum.Font.GothamBold
_plusButton.TextSize = 24
_plusButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
_plusButton.Parent = _selectionFrame

-- 数量输入框
local _countLabel = Instance.new('TextBox')
_countLabel.Size = UDim2.new(0, 100, 0, 30)
_countLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
_countLabel.AnchorPoint = Vector2.new(0.5, 0.5)
_countLabel.Text = '1'
_countLabel.Font = Enum.Font.Gotham
_countLabel.TextSize = 20
_countLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
_countLabel.BackgroundTransparency = 0.9
_countLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
_countLabel.PlaceholderText = '输入数量'
_countLabel.Parent = _selectionFrame

-- 操作按钮
local _confirmButton = Instance.new('TextButton')
_confirmButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_confirmButton.Position = UDim2.new(0.7, 0, 0.7, 0)
_confirmButton.AnchorPoint = Vector2.new(0.5, 0)
_confirmButton.Text = LanguageConfig:Get(10002)
_confirmButton.Font = Enum.Font.Gotham
_confirmButton.TextSize = 18
_confirmButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
_confirmButton.TextColor3 = Color3.new(1, 1, 1)
_confirmButton.Parent = _selectionFrame

local _cancelButton = Instance.new('TextButton')
_cancelButton.Size = UDim2.new(0.3, 0, 0.2, 0)
_cancelButton.Position = UDim2.new(0.3, 0, 0.7, 0)
_cancelButton.AnchorPoint = Vector2.new(0.5, 0)
_cancelButton.Text = LanguageConfig:Get(10003)
_cancelButton.Font = Enum.Font.Gotham
_cancelButton.TextSize = 18
_cancelButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
_cancelButton.TextColor3 = Color3.new(1, 1, 1)
_cancelButton.Parent = _selectionFrame

local function updateCount(value)
    _currentCount = math.clamp(value, 1, _maxCount)
    _countLabel.Text = tostring(_currentCount)
    _plusButton.Visible = _currentCount < _maxCount
    _minusButton.Visible = _currentCount > 1
end

_countLabel.FocusLost:Connect(function()
    local num = tonumber(_countLabel.Text) or 1
    updateCount(num)
end)

_plusButton.MouseButton1Click:Connect(function()
    updateCount(_currentCount + 1)
end)

_minusButton.MouseButton1Click:Connect(function()
    updateCount(_currentCount - 1)
end)

_confirmButton.MouseButton1Click:Connect(function()
    _callback(_currentCount)
    _screenGui.Enabled = false
    _callback = nil
end)

_cancelButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
    _callback = nil
end)

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').ShowChooseNumUI:Connect(function(num, callback)
        _maxCount = tonumber(num) or 0
        _callback = callback
        _screenGui.Enabled = true
        updateCount(1)
    end)
end):catch(warn)