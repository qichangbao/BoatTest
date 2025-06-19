local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))

-- 存储箭塔血条UI
local _towerHealthBars = {}
-- 存储上次血量，用于计算伤害值
local _lastHealthValues = {}

-- 创建箭塔血条
local function CreateHealthBar(towerModel)
    if not towerModel then return end
    
    -- 检查是否已经有血条
    local existingHealthBar = _towerHealthBars[towerModel.Name]
    if existingHealthBar then
        return existingHealthBar
    end
    
    -- 创建血条UI
    local healthBarGui = Instance.new("BillboardGui")
    healthBarGui.Name = "HealthBar"
    healthBarGui.AlwaysOnTop = true
    healthBarGui.Size = UDim2.new(0, 100, 0, 20)
    healthBarGui.StudsOffset = Vector3.new(0, 5, 0) -- 在箭塔上方显示
    healthBarGui.Adornee = towerModel.PrimaryPart
    healthBarGui.Enabled = false -- 默认不显示
    
    -- 创建背景
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    background.BorderSizePixel = 0
    background.Parent = healthBarGui
    
    -- 创建血条
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- 红色血条
    healthBar.BorderSizePixel = 0
    healthBar.Parent = background
    
    -- 添加圆角
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 4)
    uiCorner.Parent = background
    
    local uiCorner2 = Instance.new("UICorner")
    uiCorner2.CornerRadius = UDim.new(0, 4)
    uiCorner2.Parent = healthBar
    
    -- 添加到工作区
    healthBarGui.Parent = towerModel
    
    -- 存储血条引用
    _towerHealthBars[towerModel.Name] = healthBarGui
    
    return healthBarGui
end

-- 更新箭塔血条
local function UpdateHealthBar(towerModel, health, maxHealth)
    if not towerModel then return end
    
    -- 获取或创建血条
    local healthBarGui = _towerHealthBars[towerModel.Name] or CreateHealthBar(towerModel)
    if not healthBarGui then return end
    
    -- 计算血量百分比
    local healthPercent = health / maxHealth
    
    -- 更新血条大小
    local healthBar = healthBarGui:FindFirstChild("Background"):FindFirstChild("HealthBar")
    if healthBar then
        healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    end
    
    -- 显示血条
    healthBarGui.Enabled = true
end

-- 移除箭塔血条
local function RemoveHealthBar(towerName)
    -- 获取血条
    local healthBarGui = _towerHealthBars[towerName]
    if not healthBarGui then return end
    
    -- 销毁血条
    healthBarGui:Destroy()
    _towerHealthBars[towerName] = nil
end

-- 根据岛屿名称和箭塔索引查找箭塔模型
local function FindTowerModel(islandName, towerName)
    local island = workspace:FindFirstChild(islandName)
    if not island then return nil end
    
    return island:FindFirstChild(towerName)
end

-- 创建伤害数值飘出效果
local function CreateDamageNumber(towerModel, damageValue)
    if not towerModel or not towerModel.PrimaryPart then return end
    
    -- 创建伤害数值GUI
    local damageGui = Instance.new("BillboardGui")
    damageGui.Name = "DamageNumber"
    damageGui.AlwaysOnTop = true
    damageGui.Size = UDim2.new(0, 80, 0, 40)
    damageGui.StudsOffset = Vector3.new(math.random(-2, 2), 8, math.random(-2, 2)) -- 在箭塔上方随机位置
    damageGui.Adornee = towerModel.PrimaryPart
    
    -- 创建伤害数值标签
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Name = "DamageLabel"
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "-" .. tostring(damageValue)
    damageLabel.Font = Enum.Font.SourceSansBold
    damageLabel.TextSize = 24
    damageLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- 红色伤害数值
    damageLabel.TextStrokeTransparency = 0
    damageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- 黑色描边
    damageLabel.TextXAlignment = Enum.TextXAlignment.Center
    damageLabel.TextYAlignment = Enum.TextYAlignment.Center
    damageLabel.Parent = damageGui
    
    -- 添加到工作区
    damageGui.Parent = towerModel
    
    -- 创建飘出动画
    local tweenInfo = TweenInfo.new(
        1.5, -- 持续时间1.5秒
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    -- 向上飘出并逐渐透明
    local upwardTween = TweenService:Create(damageGui, tweenInfo, {
        StudsOffset = damageGui.StudsOffset + Vector3.new(0, 5, 0)
    })
    
    local fadeTween = TweenService:Create(damageLabel, tweenInfo, {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    
    -- 播放动画
    upwardTween:Play()
    fadeTween:Play()
    
    -- 动画完成后销毁GUI
    fadeTween.Completed:Connect(function()
        if damageGui and damageGui.Parent then
            damageGui:Destroy()
        end
    end)
end

-- 处理箭塔受损信号
local function HandleTowerDamaged(data)
    if not data or not data.islandName or not data.towerName then return end
    
    -- 查找箭塔模型
    local towerModel = FindTowerModel(data.islandName, data.towerName)
    if not towerModel then return end
    
    -- 计算伤害值
    local towerKey = data.islandName .. "_" .. data.towerName
    local lastHealth = _lastHealthValues[towerKey] or data.maxHealth
    local damageValue = lastHealth - data.health
    
    -- 如果有伤害，显示伤害数值
    if damageValue > 0 then
        CreateDamageNumber(towerModel, damageValue)
    end
    
    -- 更新上次血量记录
    _lastHealthValues[towerKey] = data.health
    
    -- 更新血条
    UpdateHealthBar(towerModel, data.health, data.maxHealth)
end

-- 处理箭塔被摧毁信号
local function HandleTowerDestroyed(data)
    if not data or not data.islandName or not data.towerName then return end
    
    -- 清除血量记录
    local towerKey = data.islandName .. "_" .. data.towerName
    _lastHealthValues[towerKey] = nil
    
    -- 移除血条
    RemoveHealthBar(data.towerName)
end

Knit:OnStart():andThen(function()
    -- 获取TowerService
    local TowerService = Knit.GetService("TowerService")
    
    -- 监听箭塔受损信号
    TowerService.TowerDamaged:Connect(function(data)
        HandleTowerDamaged(data)
    end)
    
    -- 监听箭塔被摧毁信号
    TowerService.TowerDestroyed:Connect(function(data)
        HandleTowerDestroyed(data)
    end)
    
    print("TowerController已启动，开始监听箭塔状态变化")
end)