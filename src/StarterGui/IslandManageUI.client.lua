--[[
模块功能：岛屿管理界面
版本：1.0.0
作者：Trea
修改记录：
2024-02-26 创建岛屿管理UI
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local _screenGui = Instance.new("ScreenGui")
_screenGui.Name = "IslandManageUI_GUI"
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = playerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateFrame(_screenGui)
_frame.Size = UDim2.new(0, 700, 0, 450)
UIConfig.CreateCorner(_frame, UDim.new(0, 12))

-- 标题栏
local _titleBar = Instance.new('Frame')
_titleBar.Size = UDim2.new(1, 0, 0.1, 0)
_titleBar.Position = UDim2.new(0, 0, 0, 0)
_titleBar.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
_titleBar.Parent = _frame
UIConfig.CreateCorner(_titleBar, UDim.new(0, 8))

local _titleLabel = Instance.new('TextLabel')
_titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
_titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
_titleLabel.Text = "岛屿管理"
_titleLabel.Font = UIConfig.Font
_titleLabel.TextSize = 20
_titleLabel.TextColor3 = Color3.new(1, 1, 1)
_titleLabel.BackgroundTransparency = 1
_titleLabel.Parent = _titleBar

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(_titleBar, function()
    _screenGui.Enabled = false
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0.5, 0)

-- 左侧岛屿列表框架
local _leftFrame = Instance.new("Frame")
_leftFrame.Name = "LeftFrame"
_leftFrame.Size = UDim2.new(0.35, -15, 1, -60)
_leftFrame.Position = UDim2.new(0, 10, 0, 50)
_leftFrame.BackgroundColor3 = Color3.fromRGB(52, 58, 64)
_leftFrame.BorderSizePixel = 0
_leftFrame.Parent = _frame
UIConfig.CreateCorner(_leftFrame, UDim.new(0, 10))

-- 左侧标题
local leftTitleLabel = Instance.new("TextLabel")
leftTitleLabel.Name = "LeftTitleLabel"
leftTitleLabel.Size = UDim2.new(1, 0, 0, 40)
leftTitleLabel.Position = UDim2.new(0, 0, 0, 0)
leftTitleLabel.BackgroundColor3 = Color3.fromRGB(74, 144, 226)
leftTitleLabel.Text = "我的岛屿"
leftTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
leftTitleLabel.TextSize = 18
leftTitleLabel.Font = UIConfig.Font
leftTitleLabel.Parent = _leftFrame
UIConfig.CreateCorner(leftTitleLabel, UDim.new(0, 10))

-- 岛屿列表滚动框
local _islandList = Instance.new("ScrollingFrame")
_islandList.Name = "IslandList"
_islandList.Size = UDim2.new(1, -15, 1, -50)
_islandList.Position = UDim2.new(0, 8, 0, 45)
_islandList.BackgroundTransparency = 1
_islandList.BorderSizePixel = 0
_islandList.ScrollBarThickness = 8
_islandList.ScrollBarImageColor3 = Color3.fromRGB(74, 144, 226)
_islandList.ScrollBarImageTransparency = 0.3
_islandList.Parent = _leftFrame

-- 岛屿列表布局
local islandListLayout = Instance.new("UIListLayout")
islandListLayout.SortOrder = Enum.SortOrder.LayoutOrder
islandListLayout.Padding = UDim.new(0, 8)
islandListLayout.Parent = _islandList

-- 右侧详情框架
local _rightFrame = Instance.new("Frame")
_rightFrame.Name = "RightFrame"
_rightFrame.Size = UDim2.new(0.65, -15, 1, -60)
_rightFrame.Position = UDim2.new(0.35, 5, 0, 50)
_rightFrame.BackgroundColor3 = Color3.fromRGB(52, 58, 64)
_rightFrame.BorderSizePixel = 0
_rightFrame.Parent = _frame
UIConfig.CreateCorner(_rightFrame, UDim.new(0, 10))

-- 右侧内容区域
local _rightContent = Instance.new("Frame")
_rightContent.Name = "RightContent"
_rightContent.Size = UDim2.new(1, -20, 1, -55)
_rightContent.Position = UDim2.new(0, 10, 0, 0)
_rightContent.BackgroundTransparency = 1
_rightContent.Parent = _rightFrame

-- 当前选中的岛屿
local _selectedIsland = nil
local _selectedIslandData = nil
local updateIslandDetails = nil
local refreshIslandData = nil

local function selectIsland(islandItem, islandData)
    -- 重置所有按钮颜色
    for _, child in pairs(_islandList:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        end
    end
    
    -- 高亮选中的按钮
    islandItem.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
    
    -- 设置选中的岛屿
    _selectedIsland = islandData.id
    _selectedIslandData = islandData
    
    -- 更新右侧详情
    updateIslandDetails(islandData)
end

-- 创建岛屿列表项
local function createIslandItem(islandData)
    local islandItem = Instance.new("TextButton")
    islandItem.Name = "IslandItem_" .. islandData.id
    islandItem.Size = UDim2.new(1, -5, 0, 50)
    islandItem.BackgroundColor3 = Color3.fromRGB(73, 80, 87)
    islandItem.Text = islandData.name
    islandItem.TextColor3 = Color3.fromRGB(255, 255, 255)
    islandItem.TextSize = 16
    islandItem.Font = UIConfig.Font
    islandItem.Parent = _islandList
    UIConfig.CreateCorner(islandItem, UDim.new(0, 8))
    
    -- 点击事件
    islandItem.MouseButton1Click:Connect(function()
        selectIsland(islandItem, islandData)
    end)
    
    return islandItem
end

-- 刷新岛屿数据
refreshIslandData = function()
    if _selectedIsland and _selectedIslandData then
        -- 重新获取岛屿数据
        Knit.GetService('IslandManageService'):GetIslandData(_selectedIsland):andThen(function(islandData)
            if islandData then
                _selectedIslandData = islandData
                updateIslandDetails(islandData)
            end
        end)
    end
end

local function createTowerInfo(islandData, maxTowers)
    -- 箭塔信息区域
    local towerInfoFrame = Instance.new("Frame")
    towerInfoFrame.Name = "TowerInfoFrame"
    towerInfoFrame.Size = UDim2.new(1, 0, 0, 90)
    towerInfoFrame.Position = UDim2.new(0, 0, 0, 0)
    towerInfoFrame.BackgroundColor3 = Color3.fromRGB(73, 80, 87)
    towerInfoFrame.Parent = _rightContent
    UIConfig.CreateCorner(towerInfoFrame, UDim.new(0, 10))
    
    -- 箭塔数量标签
    local towerCountLabel = Instance.new("TextLabel")
    towerCountLabel.Name = "TowerCountLabel"
    towerCountLabel.Size = UDim2.new(0.5, -15, 0, 35)
    towerCountLabel.Position = UDim2.new(0, 15, 0, 15)
    towerCountLabel.BackgroundTransparency = 1
    towerCountLabel.Text = string.format("箭塔数量: %d/%d", #islandData.towerData or 0, maxTowers)
    towerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    towerCountLabel.TextSize = 18
    towerCountLabel.Font = UIConfig.Font
    towerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    towerCountLabel.Parent = towerInfoFrame
    
    -- 总收益
    local dailyIncome = 1000
    local incomeLabel = Instance.new("TextLabel")
    incomeLabel.Name = "IncomeLabel"
    incomeLabel.Size = UDim2.new(0.5, -15, 0, 35)
    incomeLabel.Position = UDim2.new(0, 15, 0, 40)
    incomeLabel.BackgroundTransparency = 1
    incomeLabel.Text = string.format("总收益: %d", dailyIncome)
    incomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    incomeLabel.TextSize = 18
    incomeLabel.Font = UIConfig.Font
    incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    incomeLabel.Parent = towerInfoFrame
    
    -- 当日收益
    local netIncome = 100
    local netIncomeLabel = Instance.new("TextLabel")
    netIncomeLabel.Name = "NetIncomeLabel"
    netIncomeLabel.Size = UDim2.new(0.5, -15, 0, 35)
    netIncomeLabel.Position = UDim2.new(0.5, 0, 0, 40)
    netIncomeLabel.BackgroundTransparency = 1
    netIncomeLabel.Text = string.format("今日收益: %d", netIncome)
    netIncomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    netIncomeLabel.Font = UIConfig.Font
    netIncomeLabel.TextSize = 18
    netIncomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    netIncomeLabel.Parent = towerInfoFrame
end

local function createTowerPosition(islandData, maxTowers)
    -- 箭塔位置管理区域
    local towerPositionFrame = Instance.new("Frame")
    towerPositionFrame.Name = "TowerPositionFrame"
    towerPositionFrame.Size = UDim2.new(1, 0, 0, 280)
    towerPositionFrame.Position = UDim2.new(0, 0, 0, 100)
    towerPositionFrame.BackgroundColor3 = Color3.fromRGB(73, 80, 87)
    towerPositionFrame.Parent = _rightContent
    UIConfig.CreateCorner(towerPositionFrame, UDim.new(0, 10))
    
    -- 箭塔位置标题
    local towerPositionTitle = Instance.new("TextLabel")
    towerPositionTitle.Name = "TowerPositionTitle"
    towerPositionTitle.Size = UDim2.new(1, 0, 0, 30)
    towerPositionTitle.Position = UDim2.new(0, 0, 0, 0)
    towerPositionTitle.BackgroundTransparency = 1
    towerPositionTitle.Text = "箭塔管理"
    towerPositionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    towerPositionTitle.TextSize = 18
    towerPositionTitle.Font = UIConfig.Font
    towerPositionTitle.Parent = towerPositionFrame
    
    -- 箭塔位置滚动区域
    local positionScrollFrame = Instance.new("ScrollingFrame")
    positionScrollFrame.Name = "PositionScrollFrame"
    positionScrollFrame.Size = UDim2.new(1, -15, 1, -40)
    positionScrollFrame.Position = UDim2.new(0, 8, 0, 35)
    positionScrollFrame.BackgroundTransparency = 1
    positionScrollFrame.BorderSizePixel = 0
    positionScrollFrame.ScrollBarThickness = 6
    positionScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(74, 144, 226)
    positionScrollFrame.ScrollBarImageTransparency = 0.5
    positionScrollFrame.Parent = towerPositionFrame
    
    -- 网格布局
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.23, 0, 0, 80)
    gridLayout.CellPadding = UDim2.new(0.02, 0, 0, 10)
    gridLayout.FillDirectionMaxCells = 4
    gridLayout.Parent = positionScrollFrame
    
    -- 创建箭塔位置槽位模板
    local positionTemplate = Instance.new("TextButton")
    positionTemplate.Name = "PositionTemplate"
    positionTemplate.Size = UDim2.new(0.23, 0, 0, 80)
    positionTemplate.BackgroundColor3 = Color3.fromRGB(68, 75, 82)
    positionTemplate.Text = ""
    positionTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
    positionTemplate.TextSize = 16
    positionTemplate.Font = UIConfig.Font
    positionTemplate.Visible = false
    positionTemplate.Parent = positionScrollFrame
    UIConfig.CreateCorner(positionTemplate, UDim.new(0, 8))
    
    -- 价格/状态标签
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -10, 0, 18)
    statusLabel.Position = UDim2.new(0, 5, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    statusLabel.TextSize = 16
    statusLabel.Font = UIConfig.Font
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = positionTemplate
    
    -- 创建4个箭塔位置槽位（固定显示4个）
    for i = 1, 4 do
        local positionSlot = positionTemplate:Clone()
        positionSlot.Name = "PositionSlot_" .. i
        positionSlot.Visible = true
        positionSlot.Parent = positionScrollFrame
        
        local statusLbl = positionSlot:FindFirstChild("StatusLabel")
        
        -- 检查该位置是否已有箭塔
        local hasTower = false
        local towerInfo = nil
        if islandData.towerData then
            for _, tower in ipairs(islandData.towerData) do
                if tower.index == i then
                    hasTower = true
                    towerInfo = tower
                    break
                end
            end
        end
        
        -- 检查该位置是否超出岛屿允许的箭塔数量
         if i > maxTowers then
             -- 超出岛屿允许的箭塔数量，显示为空位置
             positionSlot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
             positionSlot.Text = "不可用"
             positionSlot.Active = false
             statusLbl.Text = "此岛屿不支持"
             statusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        elseif hasTower and towerInfo then
            positionSlot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            positionSlot.Text = towerInfo.towerType
            positionSlot.Active = false
            local config = TowerConfig[towerInfo.towerType]
            if config then
                statusLbl.Text = string.format("伤害:%d", config.Damage)
            else
                statusLbl.Text = ""
            end
            statusLbl.TextColor3 = Color3.fromRGB(144, 238, 144)
            
            -- 购买箭塔点击事件
            positionSlot.MouseButton1Click:Connect(function()
                Knit.GetController('UIController').ShowMessageBox:Fire({Content = "你是否要拆除此箭塔？", OnConfirm = function()
                    Knit.GetService('IslandManageService'):RemoveTower(_selectedIsland, i):andThen(function(success, tipId)
                        Knit.GetController('UIController').ShowTip:Fire(tipId)
                        if success then
                            refreshIslandData()
                        end
                    end)
                end})
            end)
        else
            -- 没有箭塔，显示购买选项
            positionSlot.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            positionSlot.Text = "购买箭塔"
            positionSlot.TextColor3 = Color3.fromRGB(104, 48, 207)
            positionSlot.Active = true
            statusLbl.Text = ""
            
            -- 购买箭塔点击事件
            positionSlot.MouseButton1Click:Connect(function()
                Knit.GetController('UIController').ShowTowerSelectUI:Fire(_selectedIsland, i, refreshIslandData)
            end)
        end
    end
    
    -- 设置滚动框内容大小（固定为1行4个）
    positionScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 90)
end

-- 更新岛屿详情显示
updateIslandDetails = function(islandData)
    -- 清除现有内容
    for _, child in pairs(_rightContent:GetChildren()) do
        child:Destroy()
    end
    
    -- 获取岛屿配置
    local islandConfig = GameConfig.FindIsLand(islandData.name)
    local maxTowers = islandConfig and islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
    createTowerInfo(islandData, maxTowers)
    createTowerPosition(islandData, maxTowers)
end

-- 加载玩家拥有的岛屿
local function loadPlayerIslands()
    -- 清除现有列表
    for _, child in pairs(_islandList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- 获取玩家拥有的岛屿
    Knit.GetService('IslandManageService'):GetPlayerIslands():andThen(function(islands)
        if islands and #islands > 0 then
            for index, islandData in ipairs(islands) do
                local islandItem = createIslandItem(islandData)
                if index == 1 then
                    selectIsland(islandItem, islandData)
                end
            end
            
            -- 更新滚动框大小
            local contentSize = #islands * 45
            _islandList.CanvasSize = UDim2.new(0, 0, 0, contentSize)
        else
            -- 没有岛屿时显示提示
            local noIslandLabel = Instance.new("TextLabel")
            noIslandLabel.Name = "NoIslandLabel"
            noIslandLabel.Size = UDim2.new(1, -10, 0, 40)
            noIslandLabel.BackgroundTransparency = 1
            noIslandLabel.Text = "您还没有拥有任何岛屿"
            noIslandLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            noIslandLabel.TextScaled = true
            noIslandLabel.Font = UIConfig.Font
            noIslandLabel.Parent = _islandList
        end
    end):catch(function(err)
        warn("加载岛屿数据失败:", err)
    end)
end

-- 等待Knit启动
Knit.OnStart():andThen(function()
    -- 监听显示岛屿管理UI事件
    Knit.GetController('UIController').ShowIslandManageUI:Connect(function()
        _screenGui.Enabled = true
        loadPlayerIslands()
    end)
end):catch(warn)