-- 数量选择界面
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')

-- 按钮交互逻辑
local _currentCount = 1
local _maxCount = 0
local _callback = nil

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'ChooseNumUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateSmallFrame(_screenGui, LanguageConfig.Get(10029))

-- 加减按钮
local _minusButton = Instance.new('TextButton')
_minusButton.Name = "_minusButton"
_minusButton.Size = UDim2.new(0, 50, 0, 50)
_minusButton.Position = UDim2.new(0.2, 0, 0.4, 0)
_minusButton.AnchorPoint = Vector2.new(0.5, 0.5)
_minusButton.Text = '-'
_minusButton.Font = UIConfig.Font
_minusButton.TextScaled = true
_minusButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
_minusButton.Parent = _frame

local _plusButton = Instance.new('TextButton')
_plusButton.Name = "_plusButton"
_plusButton.Size = UDim2.new(0, 50, 0, 50)
_plusButton.Position = UDim2.new(0.8, 0, 0.4, 0)
_plusButton.AnchorPoint = Vector2.new(0.5, 0.5)
_plusButton.Text = '+'
_plusButton.Font = UIConfig.Font
_plusButton.TextScaled = true
_plusButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
_plusButton.Parent = _frame

-- 数量输入框
local _countLabel = Instance.new('TextBox')
_countLabel.Size = UDim2.new(0, 100, 0, 30)
_countLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
_countLabel.AnchorPoint = Vector2.new(0.5, 0.5)
_countLabel.Text = '1'
_countLabel.Font = UIConfig.Font
_countLabel.TextScaled = true
_countLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
_countLabel.BackgroundTransparency = 0.9
_countLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
_countLabel.PlaceholderText = '输入数量'
_countLabel.Parent = _frame

-- 确认按钮
local _confirmButton = UIConfig.CreateConfirmButton(_frame, function()
    _callback(_currentCount)
    _screenGui.Enabled = false
    _callback = nil
end)
_confirmButton.Position = UDim2.new(0.7, 0, 0.85, 0)

-- 取消按钮
local _cancelButton = UIConfig.CreateCancelButton(_frame, function()
    _screenGui.Enabled = false
    _callback = nil
end)
_cancelButton.Position = UDim2.new(0.3, 0, 0.85, 0)

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

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowChooseNumUI:Connect(function(num, callback)
        _maxCount = tonumber(num) or 0
        _callback = callback
        _screenGui.Enabled = true
        updateCount(1)
    end)
end):catch(warn)