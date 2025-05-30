--[[
船只属性UI
版本：1.1.0
新增生命值和速度进度条
--]]
print('BoatAttributeUI.lua loaded')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))
local GameConfig = require(ConfigFolder:WaitForChild('GameConfig'))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface'))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'BoatAttributeUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

-- 进度条容器
local _container = Instance.new('Frame')
_container.Name = 'StatusContainer'
_container.Size = UDim2.new(0.4, 0, 0.15, 0)
_container.Position = UDim2.new(0.5, 0, 0.1, 0)
_container.AnchorPoint = Vector2.new(0.5, 0)
_container.BackgroundTransparency = 1
_container.Parent = _screenGui
_container.Visible = true

-- 新增指南针界面
local compassFrame = Instance.new('Frame')
compassFrame.Name = 'CompassFrame'
compassFrame.Size = UDim2.new(0.5, 0, 0.1, 0)
compassFrame.Position = UDim2.new(0.5, 0, 0, 0)  -- 清除Y轴偏移
compassFrame.AnchorPoint = Vector2.new(0.5, 0)
compassFrame.BackgroundTransparency = 0.2
compassFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.4)
compassFrame.Parent = _screenGui

local gradient = Instance.new('UIGradient')
gradient.Rotation = 0
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
    ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
    ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
})
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.45, 0),
    NumberSequenceKeypoint.new(0.55, 0),
    NumberSequenceKeypoint.new(1, 1)
})
gradient.Parent = compassFrame

local viewportFrame = Instance.new('Frame')
viewportFrame.Size = UDim2.new(1, 0, 1, 0)
viewportFrame.ClipsDescendants = true
viewportFrame.BackgroundTransparency = 1
viewportFrame.Parent = compassFrame

local labelGradient = Instance.new('UIGradient')
labelGradient.Rotation = 0
labelGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.4, 0),
    NumberSequenceKeypoint.new(0.6, 0),
    NumberSequenceKeypoint.new(1, 1)
})
labelGradient.Parent = viewportFrame

-- 生命值进度条
local _healthBar = Instance.new('Frame')
_healthBar.Name = 'HealthBar'
_healthBar.Size = UDim2.new(1, 0, 0.4, 0)
_healthBar.Position = UDim2.new(0, 0, 0, 0)
_healthBar.AnchorPoint = Vector2.new(0, 0)
_healthBar.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
_healthBar.BorderSizePixel = 0
_healthBar.Parent = _container

local _healthFill = Instance.new('Frame')
_healthFill.Name = 'Fill'
_healthFill.Size = UDim2.new(1, 0, 1, 0)
_healthFill.AnchorPoint = Vector2.new(0, 0.5)
_healthFill.Position = UDim2.new(0, 0, 0.5, 0)
_healthFill.BackgroundColor3 = Color3.new(0.5, 1, 0.2)
_healthFill.BorderSizePixel = 0
_healthFill.Parent = _healthBar

-- 速度进度条
local _speedBar = Instance.new('Frame')
_speedBar.Name = 'SpeedBar'
_speedBar.Size = UDim2.new(1, 0, 0.4, 0)
_speedBar.Position = UDim2.new(0, 0, 1, 0)
_speedBar.AnchorPoint = Vector2.new(0, 1)
_speedBar.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
_speedBar.BorderSizePixel = 0
_speedBar.Parent = _container

local _speedFill = Instance.new('Frame')
_speedFill.Name = 'Fill'
_speedFill.Size = UDim2.new(1, 0, 1, 0)
_speedFill.AnchorPoint = Vector2.new(0, 0.5)
_speedFill.Position = UDim2.new(0, 0, 0.5, 0)
_speedFill.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
_speedFill.BorderSizePixel = 0
_speedFill.Parent = _speedBar

-- 文字标签
local function createLabel(parent)
    local label = Instance.new('TextLabel')
    label.Position = UDim2.new(0.5, 0, 0.5, 0)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Text = ""
    label.Font = UIConfig.Font
    label.TextSize = 18
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.5
    label.Size = UDim2.new(0.3, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = parent
    return label
end

local _healthLabel = createLabel(_healthBar)
local _speedLabel = createLabel(_speedBar)

local function UpdateUI(type, value, maxValue)
    if type == 'Health' then
        _healthFill.Size = UDim2.new(value / maxValue, 0, 1, 0)
        _healthLabel.Text = string.format(LanguageConfig.Get(10013), math.floor(value), math.floor(maxValue))
    elseif type == 'Speed' then
        _speedFill.Size = UDim2.new(value / maxValue, 0, 1, 0)
        _speedLabel.Text = string.format(LanguageConfig.Get(10014), math.floor(value), math.floor(maxValue))
    end
end

-- 创建方位指示器
local directions = {
    {Name = 'N', Angle = 0},
    {Name = 'E', Angle = 90},
    {Name = 'S', Angle = 180},
    {Name = 'W', Angle = 270}
}

for _, dir in pairs(directions) do
    local dirLabel = Instance.new('TextLabel')
    dirLabel.Name = dir.Name
    dirLabel.Text = dir.Name
    dirLabel.TextSize = 20
    dirLabel.BackgroundTransparency = 1
    dirLabel.TextTransparency = 0.3
    dirLabel.TextColor3 = Color3.new(1, 1, 0.184313)
    dirLabel:SetAttribute('IsDirection', true)
    dirLabel:SetAttribute('BaseAngle', dir.Angle)
    dirLabel.Parent = viewportFrame
end

-- 初始化陆地数据
for _, landData in ipairs(GameConfig.IsLand) do
    local landLabel = Instance.new('TextLabel')
    landLabel.Name = landData.Name
    landLabel.TextSize = 16
    landLabel.BackgroundTransparency = 1
    landLabel.TextTransparency = 0.3
    landLabel.TextColor3 = Color3.new(1,1,1)
    landLabel.Parent = viewportFrame
    landLabel:SetAttribute('Position',
        Vector3.new(
            landData.Position.X + landData.WharfInOffsetPos.X,
            landData.Position.Y,
            landData.Position.Z + landData.WharfInOffsetPos.Z)
        )
end

-- 动态更新指南针
local function UpdateCompass()
    if not _screenGui.Enabled then
        return
    end
    
    -- 更新方位指示器
    local boat = Interface.GetBoatByPlayerUserId(game.Players.LocalPlayer.UserId)
    if not boat or not boat.PrimaryPart then return end
    
    local boatCFrame = boat.PrimaryPart.CFrame or CFrame.new()
    local lookVector = -boatCFrame.LookVector  -- 取反获得船头方向
    local rightVector = boatCFrame.RightVector
    
    -- 计算正北方向（世界坐标系Z轴负方向）
    local northDir = Vector3.new(0, 0, -1)
    local angleFromNorth = math.deg(math.atan2(northDir:Dot(rightVector), northDir:Dot(lookVector)))
    
    -- 更新四个方位标签位置
    for _, dirLabel in ipairs(viewportFrame:GetChildren()) do
        if dirLabel:GetAttribute('IsDirection') then
            local baseAngle = dirLabel:GetAttribute('BaseAngle')
            local targetAngle = (baseAngle - angleFromNorth) % 360
            
            -- 将角度映射到-180~180范围
            if targetAngle > 180 then
                targetAngle = targetAngle - 360
            end
            
            -- 显示视角前方±60度范围内的方位
            dirLabel.Visible = math.abs(targetAngle) <= 60
            
            -- 计算水平位置比例 (-60~60度 => 0~1)
            local positionRatio = (targetAngle + 60) / 120
            
            -- 根据位置计算透明度（中间0.5时0.3，边缘时1）
            local transparency = 1 - math.clamp(1 - math.abs(positionRatio - 0.5)*2, 0, 0.7)
            dirLabel.TextTransparency = transparency
            
            dirLabel.Position = UDim2.new(positionRatio, 0, 0.5, 0)
        end
    end

    for _, child in ipairs(viewportFrame:GetChildren()) do
        if child:IsA('TextLabel') then
            local landPos = child:GetAttribute('Position')
            if landPos then
                local offset = Vector3.new(landPos.X - boatCFrame.Position.X, 0, landPos.Z - boatCFrame.Position.Z)
                local direction = offset.Unit
                
                local horizontalAngle = math.deg(math.atan2(direction:Dot(rightVector), lookVector:Dot(direction)))  -- 添加负号修正方向
                local positionRatio = (60 - horizontalAngle) / 120  -- 调整位置比例计算
                
                -- 根据位置计算透明度
                local transparency = 1 - math.clamp(1 - math.abs(positionRatio - 0.5)*2, 0, 0.7)
                child.TextTransparency = transparency
                
                child.Position = UDim2.new(positionRatio, 0, 0.5, 0)
                child.AnchorPoint = Vector2.new(0.5, 0.5)
                
                -- 更新距离显示
                local distance = offset.Magnitude
                child.Visible = distance <= 2000
                child.Text = string.format('%s\n%d', child.Name, math.floor(distance))
            end
        end
    end
end

local _renderSteppedConnection = game:GetService('RunService').Heartbeat:Connect(UpdateCompass)

local function Destroy()
    print('BoatAttributeUI Destroy')
    if _renderSteppedConnection then
        _renderSteppedConnection:Disconnect()
        _renderSteppedConnection = nil
    end
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui, Destroy)

    local BoatAttributeService = Knit.GetService("BoatAttributeService")
    BoatAttributeService.ChangeAttribute:Connect(function(type, value, maxValue)
        UpdateUI(type, value, maxValue)
    end)

    local BoatMovementService = Knit.GetService("BoatMovementService")
    BoatMovementService.isOnBoat:Connect(function(isOnBoat)
        _screenGui.Enabled = isOnBoat
    end)
end):catch(warn)