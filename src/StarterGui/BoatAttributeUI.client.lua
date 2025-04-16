--[[
船只属性UI
版本：1.1.0
新增生命值和速度进度条
--]]
print('BoatAttributeUI.lua loaded')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'BoatAttributeUI'
screenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

-- 进度条容器
local container = Instance.new('Frame')
container.Name = 'StatusContainer'
container.Size = UDim2.new(0.4, 0, 0.15, 0)
container.Position = UDim2.new(0.5, 0, 0.05, 0)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundTransparency = 1
container.Parent = screenGui
container.Visible = false

-- 生命值进度条
local healthBar = Instance.new('Frame')
healthBar.Name = 'HealthBar'
healthBar.Size = UDim2.new(1, 0, 0.4, 0)
healthBar.Position = UDim2.new(0, 0, 0, 0)
healthBar.AnchorPoint = Vector2.new(0, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
healthBar.BorderSizePixel = 0

local healthFill = Instance.new('Frame')
healthFill.Name = 'Fill'
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.AnchorPoint = Vector2.new(0, 0.5)
healthFill.Position = UDim2.new(0, 0, 0.5, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBar

-- 速度进度条
local speedBar = Instance.new('Frame')
speedBar.Name = 'SpeedBar'
speedBar.Size = UDim2.new(1, 0, 0.4, 0)
speedBar.Position = UDim2.new(0, 0, 1, 0)
speedBar.AnchorPoint = Vector2.new(0, 1)
speedBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedBar.BorderSizePixel = 0

local speedFill = Instance.new('Frame')
speedFill.Name = 'Fill'
speedFill.Size = UDim2.new(1, 0, 1, 0)
speedFill.AnchorPoint = Vector2.new(0, 0.5)
speedFill.Position = UDim2.new(0, 0, 0.5, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(60, 180, 255)
speedFill.BorderSizePixel = 0
speedFill.Parent = speedBar

-- 文字标签
local function createLabel(text, parent)
    local label = Instance.new('TextLabel')
    label.Text = text
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = parent
    return label
end

createLabel('生命值:', healthBar)
createLabel('速度:', speedBar)

healthBar.Parent = container
speedBar.Parent = container

local function UpdateUI(type, value, maxValue)
    if type == 'Health' then
        healthFill.Size = UDim2.new(value / maxValue, 0, 1, 0)
    elseif type == 'Speed' then
        speedFill.Size = UDim2.new(value / maxValue, 0, 1, 0)
    end
end

Knit:OnStart():andThen(function()
    local BoatAttributeService = Knit.GetService("BoatAttributeService")
    BoatAttributeService.ChangeAttribute:Connect(function(type, value, maxValue)
        UpdateUI(type, value, maxValue)
    end)

    local BoatMovementService = Knit.GetService("BoatMovementService")
    BoatMovementService.isOnBoat:Connect(function(isOnBoat)
        container.Visible = isOnBoat
    end)
end):catch(warn)