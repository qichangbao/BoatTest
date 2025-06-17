local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))

-- 存储箭塔血条UI
local _towerHealthBars = {}
-- 存储血条显示计时器
local _healthBarTimers = {}

-- 创建箭塔血条
local function CreateHealthBar(towerModel)
    if not towerModel then return end
    
    -- 检查是否已经有血条
    local existingHealthBar = _towerHealthBars[towerModel]
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
    _towerHealthBars[towerModel] = healthBarGui
    
    return healthBarGui
end

-- 更新箭塔血条
local function UpdateHealthBar(towerModel, health, maxHealth)
    if not towerModel then return end
    
    -- 获取或创建血条
    local healthBarGui = _towerHealthBars[towerModel] or CreateHealthBar(towerModel)
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
    
    -- 取消之前的计时器（如果有）
    local timer = _healthBarTimers[towerModel]
    if timer then
        task.cancel(timer)
        _healthBarTimers[towerModel] = nil
    end
    
    -- 设置新的计时器，3秒后隐藏血条
    _healthBarTimers[towerModel] = task.delay(3, function()
        if healthBarGui and healthBarGui.Parent then
            healthBarGui.Enabled = false
        end
        _healthBarTimers[towerModel] = nil
    end)
end

-- 移除箭塔血条
local function RemoveHealthBar(towerModel)
    if not towerModel then return end
    
    -- 获取血条
    local healthBarGui = _towerHealthBars[towerModel]
    if not healthBarGui then return end
    
    -- 取消计时器
    local timer = _healthBarTimers[towerModel]
    if timer then
        task.cancel(timer)
        _healthBarTimers[towerModel] = nil
    end
    
    -- 销毁血条
    healthBarGui:Destroy()
    _towerHealthBars[towerModel] = nil
end

-- 根据岛屿名称和箭塔索引查找箭塔模型
local function FindTowerModel(islandName, towerIndex)
    local island = workspace:FindFirstChild(islandName)
    if not island then return nil end
    
    -- 遍历岛屿中的所有子对象，查找箭塔
    for _, child in pairs(island:GetChildren()) do
        -- 检查是否是箭塔（名称格式：岛屿名_索引）
        local pattern = islandName .. "_" .. towerIndex
        if child.Name == pattern then
            return child
        end
    end
    
    return nil
end

-- 处理箭塔受损信号
local function HandleTowerDamaged(data)
    if not data or not data.islandName or not data.towerIndex then return end
    
    -- 查找箭塔模型
    local towerModel = FindTowerModel(data.islandName, data.towerIndex)
    if not towerModel then return end
    
    -- 更新血条
    UpdateHealthBar(towerModel, data.health, data.maxHealth)
end

-- 处理箭塔被摧毁信号
local function HandleTowerDestroyed(data)
    if not data or not data.islandName or not data.towerIndex then return end
    
    -- 查找箭塔模型
    local towerModel = FindTowerModel(data.islandName, data.towerIndex)
    if not towerModel then return end
    
    -- 移除血条
    RemoveHealthBar(towerModel)
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