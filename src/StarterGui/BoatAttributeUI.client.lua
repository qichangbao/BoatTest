--[[
船只属性UI
版本：1.1.0
新增生命值和速度进度条
--]]
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))
local GameConfig = require(ConfigFolder:WaitForChild('GameConfig'))
local IslandConfig = require(ConfigFolder:WaitForChild('IslandConfig'))
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

local function createLabel(parent, barPos, barAnchorPoint, fillColor)
    -- 进度条
    local _bar = Instance.new('Frame')
    _bar.Size = UDim2.new(1, 0, 0.4, 0)
    _bar.Position = barPos
    _bar.AnchorPoint = barAnchorPoint
    _bar.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
    _bar.BorderSizePixel = 0
    _bar.Parent = parent

    local _fill = Instance.new('Frame')
    _fill.Name = 'Fill'
    _fill.Size = UDim2.new(1, 0, 1, 0)
    _fill.AnchorPoint = Vector2.new(0, 0.5)
    _fill.Position = UDim2.new(0, 0, 0.5, 0)
    _fill.BackgroundColor3 = fillColor
    _fill.BorderSizePixel = 0
    _fill.Parent = _bar

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
    label.Parent = _bar

    return _bar, _fill, label
end

local _healthBar, _healthFill, _healthLabel = createLabel(_container, UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), Color3.new(0.5, 1, 0.2))
local _speedBar, _speedFill, _speedLabel = createLabel(_container, UDim2.new(0, 0, 1, 0), Vector2.new(0, 1), Color3.new(0.2, 0.6, 1))

-- 存储当前值用于动画计算
local currentHealth = 0
local currentMaxHealth = 100
local currentSpeed = 0
local currentMaxSpeed = 100

-- 动画相关变量
local healthTween = nil
local speedTween = nil

local function UpdateUI(type, value, maxValue)
    if type == 'Health' then
        local oldHealth = currentHealth
        local oldMaxHealth = currentMaxHealth
        currentHealth = value
        currentMaxHealth = maxValue
        
        -- 停止之前的动画
        if healthTween then
            healthTween:Cancel()
        end
        
        -- 如果最大值发生变化，先调整比例
        if oldMaxHealth ~= maxValue then
            local adjustedRatio = math.min(oldHealth / maxValue, 1)
            _healthFill.Size = UDim2.new(adjustedRatio, 0, 1, 0)
        end
        
        -- 创建平滑动画到新的比例
        local targetRatio = value / maxValue
        healthTween = TweenService:Create(
            _healthFill,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(targetRatio, 0, 1, 0)}
        )
        healthTween:Play()
        
        -- 更新文本
        _healthLabel.Text = string.format(LanguageConfig.Get(10013), math.floor(value), math.floor(maxValue))
        
    elseif type == 'Speed' then
        local oldSpeed = currentSpeed
        local oldMaxSpeed = currentMaxSpeed
        currentSpeed = value
        currentMaxSpeed = maxValue
        
        -- 停止之前的动画
        if speedTween then
            speedTween:Cancel()
        end
        
        -- 如果最大值发生变化，先调整比例
        if oldMaxSpeed ~= maxValue then
            local adjustedRatio = math.min(oldSpeed / maxValue, 1)
            _speedFill.Size = UDim2.new(adjustedRatio, 0, 1, 0)
        end
        
        -- 创建平滑动画到新的比例
        local targetRatio = value / maxValue
        speedTween = TweenService:Create(
            _speedFill,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(targetRatio, 0, 1, 0)}
        )
        speedTween:Play()
        
        -- 更新文本
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
for _, landData in ipairs(IslandConfig.IsLand) do
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
                child.Visible = true -- distance <= 2000

                local showName = child.Name
                local start = child.Name:find("_")
                if start then
                    showName = child.Name:sub(1, start - 1)
                end
                child.Text = string.format('%s\n%d', showName, math.floor(distance))
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
    
    -- 监听指南针岛屿更新信号
    local UIController = Knit.GetController('UIController')
    UIController.UpdateCompassIsland:Connect(function(islandName, position)
        -- 查找是否已存在该岛屿标签
        local existingLabel = viewportFrame:FindFirstChild(islandName)
        if existingLabel then
            -- 更新现有标签的位置
            existingLabel:SetAttribute('Position', position)
        else
            -- 创建新的岛屿标签
            local landLabel = Instance.new('TextLabel')
            landLabel.Name = islandName
            landLabel.TextSize = 16
            landLabel.BackgroundTransparency = 1
            landLabel.TextTransparency = 0.3
            landLabel.TextColor3 = Color3.new(1,1,1)
            landLabel.Parent = viewportFrame
            landLabel:SetAttribute('Position', position)
        end
    end)
    
    -- 监听指南针岛屿移除信号
    UIController.RemoveCompassIsland:Connect(function(islandName)
        local existingLabel = viewportFrame:FindFirstChild(islandName)
        if existingLabel then
            existingLabel:Destroy()
        end
    end)
end):catch(warn)