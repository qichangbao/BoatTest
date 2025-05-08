--[[
船只属性UI
版本：1.1.0
新增生命值和速度进度条
--]]
print('BoatAttributeUI.lua loaded')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'BoatAttributeUI_Gui'
_screenGui.Parent = PlayerGui

-- 进度条容器
local _container = Instance.new('Frame')
_container.Name = 'StatusContainer'
_container.Size = UDim2.new(0.4, 0, 0.15, 0)
_container.Position = UDim2.new(0.5, 0, 0.05, 0)
_container.AnchorPoint = Vector2.new(0.5, 1)
_container.BackgroundTransparency = 1
_container.Parent = _screenGui
_container.Visible = false

-- 生命值进度条
local _healthBar = Instance.new('Frame')
_healthBar.Name = 'HealthBar'
_healthBar.Size = UDim2.new(1, 0, 0.4, 0)
_healthBar.Position = UDim2.new(0, 0, 0, 0)
_healthBar.AnchorPoint = Vector2.new(0, 0)
_healthBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
_healthBar.BorderSizePixel = 0
_healthBar.Parent = _container

local _healthFill = Instance.new('Frame')
_healthFill.Name = 'Fill'
_healthFill.Size = UDim2.new(1, 0, 1, 0)
_healthFill.AnchorPoint = Vector2.new(0, 0.5)
_healthFill.Position = UDim2.new(0, 0, 0.5, 0)
_healthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
_healthFill.BorderSizePixel = 0
_healthFill.Parent = _healthBar

-- 速度进度条
local _speedBar = Instance.new('Frame')
_speedBar.Name = 'SpeedBar'
_speedBar.Size = UDim2.new(1, 0, 0.4, 0)
_speedBar.Position = UDim2.new(0, 0, 1, 0)
_speedBar.AnchorPoint = Vector2.new(0, 1)
_speedBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
_speedBar.BorderSizePixel = 0
_speedBar.Parent = _container

local _speedFill = Instance.new('Frame')
_speedFill.Name = 'Fill'
_speedFill.Size = UDim2.new(1, 0, 1, 0)
_speedFill.AnchorPoint = Vector2.new(0, 0.5)
_speedFill.Position = UDim2.new(0, 0, 0.5, 0)
_speedFill.BackgroundColor3 = Color3.fromRGB(60, 180, 255)
_speedFill.BorderSizePixel = 0
_speedFill.Parent = _speedBar

-- 文字标签
local function createLabel(text, parent)
    local label = Instance.new('TextLabel')
    label.Text = text
    label.Font = Enum.Font.Arimo
    label.TextSize = 18
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = parent
    return label
end

createLabel(LanguageConfig:Get(10013), _healthBar)
createLabel(LanguageConfig:Get(10014), _speedBar)

local function UpdateUI(type, value, maxValue)
    if type == 'Health' then
        _healthFill.Size = UDim2.new(value / maxValue, 0, 1, 0)
    elseif type == 'Speed' then
        _speedFill.Size = UDim2.new(value / maxValue, 0, 1, 0)
    end
end

Knit:OnStart():andThen(function()
    local BoatAttributeService = Knit.GetService("BoatAttributeService")
    BoatAttributeService.ChangeAttribute:Connect(function(type, value, maxValue)
        UpdateUI(type, value, maxValue)
    end)

    local BoatMovementService = Knit.GetService("BoatMovementService")
    BoatMovementService.isOnBoat:Connect(function(isOnBoat)
        _container.Visible = isOnBoat
    end)
end):catch(warn)