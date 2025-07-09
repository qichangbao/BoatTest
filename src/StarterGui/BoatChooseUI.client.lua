--[[
模块名称：船只选择UI界面
功能：显示玩家拥有的船只，允许选择并创建船只
作者：Trea AI
版本：1.0.0
最后修改：2024-12-19
]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("ItemConfig"))
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local player = Players.LocalPlayer

-- 创建主界面
local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'BoatChooseUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

-- 创建背景遮罩
UIConfig.CreateBlock(_screenGui)

-- 创建主框架
local _frame = UIConfig.CreateMiddleFrame(_screenGui, "选择船只")

-- 创建滚动框架
local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Size = UDim2.new(1, -20, 1, -20)
_scrollFrame.Position = UDim2.new(0, 10, 0, 10)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
_scrollFrame.Parent = _frame

-- 船只条目模板
local _boatTemplate = Instance.new('Frame')
_boatTemplate.Name = '_boatTemplate'
_boatTemplate.Size = UDim2.new(0.95, 0, 0, 80)
_boatTemplate.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
_boatTemplate.BorderSizePixel = 0
_boatTemplate.Visible = false
UIConfig.CreateCorner(_boatTemplate, UDim.new(0, 8))

-- 船只名称标签
local _boatNameLabel = Instance.new('TextLabel')
_boatNameLabel.Name = 'BoatNameLabel'
_boatNameLabel.Size = UDim2.new(0.6, -10, 0.5, 0)
_boatNameLabel.Position = UDim2.new(0, 10, 0, 5)
_boatNameLabel.BackgroundTransparency = 1
_boatNameLabel.Text = ""
_boatNameLabel.Font = UIConfig.Font
_boatNameLabel.TextScaled = true
_boatNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_boatNameLabel.TextXAlignment = Enum.TextXAlignment.Left
_boatNameLabel.Parent = _boatTemplate

-- 船只HP标签
local _boatHPLabel = Instance.new('TextLabel')
_boatHPLabel.Name = 'BoatHPLabel'
_boatHPLabel.Size = UDim2.new(0.3, -5, 0.5, 0)
_boatHPLabel.Position = UDim2.new(0, 10, 0.5, 0)
_boatHPLabel.BackgroundTransparency = 1
_boatHPLabel.Text = ""
_boatHPLabel.Font = UIConfig.Font
_boatHPLabel.TextScaled = true
_boatHPLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
_boatHPLabel.TextXAlignment = Enum.TextXAlignment.Left
_boatHPLabel.Parent = _boatTemplate

-- 船只速度标签
local _boatSpeedLabel = Instance.new('TextLabel')
_boatSpeedLabel.Name = 'BoatSpeedLabel'
_boatSpeedLabel.Size = UDim2.new(0.3, -5, 0.5, 0)
_boatSpeedLabel.Position = UDim2.new(0.3, 5, 0.5, 0)
_boatSpeedLabel.BackgroundTransparency = 1
_boatSpeedLabel.Text = ""
_boatSpeedLabel.Font = UIConfig.Font
_boatSpeedLabel.TextScaled = true
_boatSpeedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
_boatSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
_boatSpeedLabel.Parent = _boatTemplate

-- 选择按钮
local _selectButton = Instance.new('TextButton')
_selectButton.Name = 'SelectButton'
_selectButton.Size = UDim2.new(0, 100, 0, 35)
_selectButton.Position = UDim2.new(1, -110, 0.5, -17.5)
_selectButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
_selectButton.Text = ""
_selectButton.Font = UIConfig.Font
_selectButton.TextScaled = true
_selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_selectButton.Parent = _boatTemplate
UIConfig.CreateCorner(_selectButton, UDim.new(0, 6))

-- 获取玩家拥有的船只
-- @return table 返回玩家拥有的船只列表
local function getPlayerBoats()
    local boats = {}
    local inventory = ClientData.InventoryItems
    
    -- 遍历库存物品，找出船只部件
    for _, itemData in pairs(inventory) do
        if itemData.itemType == ItemConfig.BoatTag then
            local modelName = itemData.modelName
            
            -- 如果这个船型还没有记录，创建新记录
            if not boats[modelName] then
                boats[modelName] = {
                    name = modelName,
                    parts = {},
                    totalParts = 0,
                    availableParts = 0,
                    canAssemble = false
                }
            end
            
            -- 添加部件信息
            table.insert(boats[modelName].parts, {
                itemName = itemData.itemName,
                num = itemData.num or 1,
            })
            
            boats[modelName].totalParts = boats[modelName].totalParts + (itemData.num or 1)
            boats[modelName].availableParts = boats[modelName].availableParts + (itemData.num or 1)
        end
    end
    
    -- 检查每个船型是否可以启航（只需要主部件）
    for modelName, boatData in pairs(boats) do
        local boatConfig = BoatConfig.GetBoatConfig(modelName)
        if boatConfig then
            local hasAvailablePrimaryPart = false
            local totalHP = 0
            local totalSpeed = 0
            
            -- 检查是否有可用的主部件，并计算总HP和速度
            for _, partData in pairs(boatData.parts) do
                local partConfig = boatConfig[partData.itemName]
                if partConfig then
                    -- 检查是否有可用的主部件
                    if partConfig.PartType == "PrimaryPart" then
                        hasAvailablePrimaryPart = true
                    end
                    
                    -- 计算可用部件的HP和速度
                    totalHP = totalHP + (partConfig.HP or 0) * (partData.num or 1)
                    totalSpeed = totalSpeed + (partConfig.speed or 0) * (partData.num or 1)
                end
            end
            
            boatData.canAssemble = hasAvailablePrimaryPart
            boatData.totalHP = totalHP
            boatData.totalSpeed = totalSpeed
        end
    end
    
    return boats
end

-- 创建船只条目
-- @param boatData table 船只数据
-- @param yPosition number Y轴位置
-- @return Frame 创建的船只条目框架
local function createBoatEntry(boatData, yPosition)
    local entry = _boatTemplate:Clone()
    entry.Position = UDim2.new(0, 0, 0, yPosition)
    entry.Visible = true
    entry.Parent = _scrollFrame
    
    -- 设置船只名称
    local nameLabel = entry:FindFirstChild('BoatNameLabel')
    if nameLabel then
        nameLabel.Text = boatData.name
    end
    
    -- 设置船只HP和速度显示
    local hpLabel = entry:FindFirstChild('BoatHPLabel')
    local speedLabel = entry:FindFirstChild('BoatSpeedLabel')
    local selectButton = entry:FindFirstChild('SelectButton')
    
    if hpLabel and speedLabel and selectButton then
        -- 显示HP和速度
        hpLabel.Text = LanguageConfig.Get(10013) .. string.format(": %d", boatData.totalHP or 0)
        speedLabel.Text = LanguageConfig.Get(10014) .. string.format(": %d", boatData.totalSpeed or 0)
        
        if boatData.canAssemble then
            selectButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243) -- 蓝色
            selectButton.Text = LanguageConfig.Get(10099)
        else
            selectButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120) -- 灰色
            selectButton.Text = LanguageConfig.Get(10100)
        end
    end
    
    -- 设置按钮点击事件
    if selectButton then
        selectButton.MouseButton1Click:Connect(function()
            if boatData.canAssemble then
                -- 设置组装状态
                ClientData.IsBoatAssembling = true
                -- 调用船只组装服务
                Knit.GetService('BoatAssemblingService'):AssembleBoat(boatData.name):andThen(function(tipId)
                    Knit.GetController('UIController').ShowTip:Fire(tipId)
                    -- 关闭船只选择界面
                    _screenGui.Enabled = false
                end)
            end
        end)
    end
    
    return entry
end

-- 更新船只列表
-- @return void
local function updateBoatList()
    -- 清除现有条目
    for _, child in ipairs(_scrollFrame:GetChildren()) do
        if child:IsA('Frame') and child.Name ~= '_boatTemplate' then
            child:Destroy()
        end
    end
    
    -- 获取玩家船只
    local boats = getPlayerBoats()
    local yPos = 0
    
    -- 创建船只条目
    for _, boatData in pairs(boats) do
        createBoatEntry(boatData, yPos)
        yPos = yPos + 90 -- 条目高度80 + 间距10
    end
    
    -- 设置滚动框架的画布大小
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- 等待Knit启动
Knit:OnStart():andThen(function()
    -- 注册UI到UIController
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    
    -- 监听显示船只选择UI的事件
    Knit.GetController('UIController').ShowBoatChooseUI:Connect(function()
        _screenGui.Enabled = true
        updateBoatList()
    end)
    
    -- 监听库存更新事件，刷新船只列表
    Knit.GetController('UIController').UpdateInventoryUI:Connect(function()
        if _screenGui.Enabled then
            updateBoatList()
        end
    end)
end):catch(warn)