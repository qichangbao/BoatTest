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
_frame.Size = UDim2.new(0, 900, 0, 450)
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
leftTitleLabel.Text = "🗺️ 我的岛屿"
leftTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
leftTitleLabel.TextSize = 16
leftTitleLabel.Font = Enum.Font.SourceSansBold
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
    islandItem.Text = "🏝️ " .. islandData.name
    islandItem.TextColor3 = Color3.fromRGB(255, 255, 255)
    islandItem.TextSize = 14
    islandItem.Font = Enum.Font.SourceSans
    islandItem.Parent = _islandList
    UIConfig.CreateCorner(islandItem, UDim.new(0, 8))
    
    -- 点击事件
    islandItem.MouseButton1Click:Connect(function()
        selectIsland(islandItem, islandData)
    end)
    
    return islandItem
end

-- 刷新岛屿数据
local function refreshIslandData()
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

-- 更新岛屿详情显示
updateIslandDetails = function(islandData)
    -- 清除现有内容
    for _, child in pairs(_rightContent:GetChildren()) do
        child:Destroy()
    end
    
    -- 获取岛屿配置
    local islandConfig = GameConfig.FindIsLand(islandData.name)
    local maxTowers = islandConfig and islandConfig.TowerOffsetPos and #islandConfig.TowerOffsetPos or 0
    
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
    towerCountLabel.Text = string.format("🗼 箭塔数量: %d/%d", islandData.towerCount or 0, maxTowers)
    towerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    towerCountLabel.TextSize = 14
    towerCountLabel.Font = Enum.Font.SourceSansBold
    towerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    towerCountLabel.Parent = towerInfoFrame
    
    -- 箭数量标签
    local arrowCountLabel = Instance.new("TextLabel")
    arrowCountLabel.Name = "ArrowCountLabel"
    arrowCountLabel.Size = UDim2.new(0.5, -15, 0, 35)
    arrowCountLabel.Position = UDim2.new(0.5, 0, 0, 15)
    arrowCountLabel.BackgroundTransparency = 1
    local maxArrows = (islandData.towerCount or 0) * 100
    arrowCountLabel.Text = string.format("🏹 箭数量: %d/%d", islandData.arrowCount or 0, maxArrows)
    arrowCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    arrowCountLabel.TextSize = 14
    arrowCountLabel.Font = Enum.Font.SourceSansBold
    arrowCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    arrowCountLabel.Parent = towerInfoFrame
    
    -- 箭塔位置管理区域
    local towerPositionFrame = Instance.new("Frame")
    towerPositionFrame.Name = "TowerPositionFrame"
    towerPositionFrame.Size = UDim2.new(1, 0, 0, 200)
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
    towerPositionTitle.Text = "🏰 箭塔位置管理"
    towerPositionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    towerPositionTitle.TextSize = 16
    towerPositionTitle.Font = Enum.Font.SourceSansBold
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
    gridLayout.CellPadding = UDim2.new(0.01, 0, 0, 10)
    gridLayout.FillDirectionMaxCells = 4
    gridLayout.Parent = positionScrollFrame
    
    -- 创建箭塔位置槽位模板
    local positionTemplate = Instance.new("Frame")
    positionTemplate.Name = "PositionTemplate"
    positionTemplate.Size = UDim2.new(0.23, 0, 0, 80)
    positionTemplate.BackgroundColor3 = Color3.fromRGB(68, 75, 82)
    positionTemplate.Visible = false
    positionTemplate.Parent = positionScrollFrame
    UIConfig.CreateCorner(positionTemplate, UDim.new(0, 8))
    
    -- 操作按钮
    local actionButton = Instance.new("TextButton")
    actionButton.Name = "ActionButton"
    actionButton.Size = UDim2.new(1, -10, 0, 35)
    actionButton.Position = UDim2.new(0, 5, 0, 25)
    actionButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    actionButton.Text = "🛒 购买箭塔"
    actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionButton.TextSize = 11
    actionButton.Font = Enum.Font.SourceSansBold
    actionButton.Parent = positionTemplate
    UIConfig.CreateCorner(actionButton, UDim.new(0, 6))
    
    -- 价格/状态标签
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -10, 0, 15)
    statusLabel.Position = UDim2.new(0, 5, 0, 62)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "💰 100金币"
    statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = positionTemplate
    
    -- 创建4个箭塔位置槽位（固定显示4个）
    for i = 1, 4 do
        local positionSlot = positionTemplate:Clone()
        positionSlot.Name = "PositionSlot_" .. i
        positionSlot.Visible = true
        positionSlot.Parent = positionScrollFrame
        
        local actionBtn = positionSlot:FindFirstChild("ActionButton")
        local statusLbl = positionSlot:FindFirstChild("StatusLabel")
        
        -- 检查该位置是否已有箭塔
        local hasTower = false
        local towerInfo = nil
        if islandData.towers then
            for _, tower in ipairs(islandData.towers) do
                if tower.position == i then
                    hasTower = true
                    towerInfo = tower
                    break
                end
            end
        end
        
        -- 检查该位置是否超出岛屿允许的箭塔数量
         if i > maxTowers then
             -- 超出岛屿允许的箭塔数量，显示为空位置
             actionBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
             actionBtn.Text = "❌ 不可用"
             actionBtn.Active = false
             statusLbl.Text = "此岛屿不支持"
             statusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        elseif hasTower and towerInfo then
            -- 已有箭塔，显示补充箭矢
            local towerData = TowerConfig[towerInfo.type]
            if towerData then
                local currentArrows = (islandData.towerArrows and islandData.towerArrows[i]) or 0
                if currentArrows >= towerData.MaxArrow then
                    actionBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    actionBtn.Text = "✅ 箭矢已满"
                    actionBtn.Active = false
                    statusLbl.Text = string.format("🏹 %d/%d", currentArrows, towerData.MaxArrow)
                    statusLbl.TextColor3 = Color3.fromRGB(144, 238, 144)
                elseif (ClientData.Gold or 0) < 10 then
                    actionBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
                    actionBtn.Text = "💸 金币不足"
                    actionBtn.Active = false
                    statusLbl.Text = "需要10金币"
                    statusLbl.TextColor3 = Color3.fromRGB(255, 99, 71)
                else
                    actionBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
                    actionBtn.Text = "🏹 补充箭矢"
                    actionBtn.Active = true
                    statusLbl.Text = string.format("🏹 %d/%d (10金币/100支)", currentArrows, towerData.MaxArrow)
                    statusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                end
                
                -- 补充箭矢点击事件
                actionBtn.MouseButton1Click:Connect(function()
                    if currentArrows < towerData.MaxArrow and (ClientData.Gold or 0) >= 10 then
                        Knit.GetService('IslandManageService'):BuyArrows(_selectedIsland, i, 100):andThen(function(success)
                            if success then
                                Knit.GetController('UIController').ShowTip:Fire(10019) -- 购买成功
                                refreshIslandData()
                            else
                                Knit.GetController('UIController').ShowTip:Fire(10044) -- 金币不够
                            end
                        end)
                    end
                end)
            end
        else
            -- 没有箭塔，显示购买选项
            if (ClientData.Gold or 0) < 100 then
                actionBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
                actionBtn.Text = "💸 金币不足"
                actionBtn.Active = false
                statusLbl.Text = "需要100金币"
                statusLbl.TextColor3 = Color3.fromRGB(255, 99, 71)
            else
                actionBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
                actionBtn.Text = "🛒 购买箭塔"
                actionBtn.Active = true
                statusLbl.Text = "💰 100金币"
                statusLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
            end
            
            -- 购买箭塔点击事件（这里可以弹出箭塔类型选择）
            actionBtn.MouseButton1Click:Connect(function()
                if (ClientData.Gold or 0) >= 100 then
                    -- 默认购买第一种箭塔类型，或者可以添加选择界面
                    local firstTowerType = next(TowerConfig)
                    if firstTowerType then
                        Knit.GetService('IslandManageService'):BuyTower(_selectedIsland, firstTowerType, i):andThen(function(success)
                            if success then
                                Knit.GetController('UIController').ShowTip:Fire(10019) -- 购买成功
                                refreshIslandData()
                            else
                                Knit.GetController('UIController').ShowTip:Fire(10044) -- 金币不够
                            end
                        end)
                    end
                end
            end)
        end
    end
    
    -- 设置滚动框内容大小（固定为1行4个）
    positionScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 90)
    
    -- 已购买箭塔管理区域
    local towerManageFrame = Instance.new("Frame")
    towerManageFrame.Name = "TowerManageFrame"
    towerManageFrame.Size = UDim2.new(1, 0, 0, 200)
    towerManageFrame.Position = UDim2.new(0, 0, 0, 410)
    towerManageFrame.BackgroundColor3 = Color3.fromRGB(73, 80, 87)
    towerManageFrame.Parent = _rightContent
    UIConfig.CreateCorner(towerManageFrame, UDim.new(0, 10))
    
    -- 箭塔管理标题
    local towerManageTitle = Instance.new("TextLabel")
    towerManageTitle.Name = "TowerManageTitle"
    towerManageTitle.Size = UDim2.new(1, 0, 0, 35)
    towerManageTitle.Position = UDim2.new(0, 0, 0, 0)
    towerManageTitle.BackgroundTransparency = 1
    towerManageTitle.Text = "🏰 箭塔管理"
    towerManageTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    towerManageTitle.TextSize = 16
    towerManageTitle.Font = Enum.Font.SourceSansBold
    towerManageTitle.Parent = towerManageFrame
    
    -- 显示已购买的箭塔
    if islandData.towers and #islandData.towers > 0 then
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "TowerScrollFrame"
        scrollFrame.Size = UDim2.new(1, -15, 1, -45)
        scrollFrame.Position = UDim2.new(0, 8, 0, 40)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(74, 144, 226)
        scrollFrame.ScrollBarImageTransparency = 0.3
        scrollFrame.Parent = towerManageFrame
        
        local yPos = 0
        for i, towerInfo in ipairs(islandData.towers) do
            local towerData = TowerConfig[towerInfo.type]
            if towerData then
                -- 箭塔项目框架
                local towerItemFrame = Instance.new("Frame")
                towerItemFrame.Name = "TowerItem" .. i
                towerItemFrame.Size = UDim2.new(1, -5, 0, 90)
                towerItemFrame.Position = UDim2.new(0, 0, 0, yPos)
                towerItemFrame.BackgroundColor3 = Color3.fromRGB(68, 75, 82)
                towerItemFrame.Parent = scrollFrame
                UIConfig.CreateCorner(towerItemFrame, UDim.new(0, 8))
                
                -- 添加项目渐变
                local itemGradient = Instance.new("UIGradient")
                itemGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 75, 82)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 65, 72))
                }
                itemGradient.Rotation = 45
                itemGradient.Parent = towerItemFrame
                
                -- 箭塔信息
                local towerInfoLabel = Instance.new("TextLabel")
                towerInfoLabel.Name = "TowerInfoLabel"
                towerInfoLabel.Size = UDim2.new(0.6, 0, 0, 30)
                towerInfoLabel.Position = UDim2.new(0, 15, 0, 8)
                towerInfoLabel.BackgroundTransparency = 1
                towerInfoLabel.Text = string.format("🗼 箭塔 #%d: %s (⚔️ 伤害:%d)", i, towerData.Name, towerData.Damage)
                towerInfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                towerInfoLabel.TextSize = 13
                towerInfoLabel.Font = Enum.Font.SourceSansBold
                towerInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
                towerInfoLabel.Parent = towerItemFrame
                
                -- 箭矢数量信息
                local currentArrows = (islandData.towerArrows and islandData.towerArrows[i]) or 0
                local arrowInfoLabel = Instance.new("TextLabel")
                arrowInfoLabel.Name = "ArrowInfoLabel"
                arrowInfoLabel.Size = UDim2.new(0.6, 0, 0, 25)
                arrowInfoLabel.Position = UDim2.new(0, 15, 0, 35)
                arrowInfoLabel.BackgroundTransparency = 1
                arrowInfoLabel.Text = string.format("🏹 箭矢: %d/%d", currentArrows, towerData.MaxArrow)
                arrowInfoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                arrowInfoLabel.TextSize = 12
                arrowInfoLabel.Font = Enum.Font.SourceSans
                arrowInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
                arrowInfoLabel.Parent = towerItemFrame
                
                -- 购买箭矢按钮
                local buyArrowBtn = Instance.new("TextButton")
                buyArrowBtn.Name = "BuyArrowBtn"
                buyArrowBtn.Size = UDim2.new(0.35, -15, 0, 35)
                buyArrowBtn.Position = UDim2.new(0.65, 0, 0, 8)
                buyArrowBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
                buyArrowBtn.Text = "💰 购买箭矢"
                buyArrowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                buyArrowBtn.TextSize = 12
                buyArrowBtn.Font = Enum.Font.SourceSansBold
                buyArrowBtn.Parent = towerItemFrame
                UIConfig.CreateCorner(buyArrowBtn, UDim.new(0, 8))
                
                -- 价格标签
                local priceLabel = Instance.new("TextLabel")
                priceLabel.Name = "PriceLabel"
                priceLabel.Size = UDim2.new(0.35, -15, 0, 25)
                priceLabel.Position = UDim2.new(0.65, 0, 0, 45)
                priceLabel.BackgroundTransparency = 1
                priceLabel.Text = "💰 10金币/100支"
                priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                priceLabel.TextSize = 11
                priceLabel.Font = Enum.Font.SourceSans
                priceLabel.TextXAlignment = Enum.TextXAlignment.Center
                priceLabel.Parent = towerItemFrame
                
                -- 检查是否可以购买箭矢
                if currentArrows >= towerData.MaxArrow then
                    buyArrowBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    buyArrowBtn.Text = "箭矢已满"
                    buyArrowBtn.Active = false
                    priceLabel.Text = "已满"
                elseif (ClientData.Gold or 0) < 10 then
                    buyArrowBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
                    buyArrowBtn.Text = "金币不足"
                    buyArrowBtn.Active = false
                end
                
                -- 购买箭矢点击事件
                buyArrowBtn.MouseButton1Click:Connect(function()
                    if currentArrows < towerData.MaxArrow and (ClientData.Gold or 0) >= 10 then
                        Knit.GetService('IslandManageService'):BuyArrows(_selectedIsland, i, 100):andThen(function(success)
                            if success then
                                Knit.GetController('UIController').ShowTip:Fire(10019) -- 购买成功
                                refreshIslandData()
                            else
                                Knit.GetController('UIController').ShowTip:Fire(10044) -- 金币不够
                            end
                        end)
                    end
                end)
                
                yPos = yPos + 100
            end
        end
        
        -- 设置滚动框内容大小
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    else
        -- 没有箭塔时显示提示
        local noTowerLabel = Instance.new("TextLabel")
        noTowerLabel.Name = "NoTowerLabel"
        noTowerLabel.Size = UDim2.new(1, -20, 1, -45)
        noTowerLabel.Position = UDim2.new(0, 10, 0, 40)
        noTowerLabel.BackgroundTransparency = 1
        noTowerLabel.Text = "🏗️ 还没有购买任何箭塔\n\n请在上方选择箭塔类型"
        noTowerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        noTowerLabel.TextSize = 14
        noTowerLabel.Font = Enum.Font.SourceSans
        noTowerLabel.Parent = towerManageFrame
    end
    
    -- 岛屿统计信息
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, 0, 0, 200)
    statsFrame.Position = UDim2.new(0, 0, 0, 560)
    statsFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    statsFrame.Parent = _rightContent
    UIConfig.CreateCorner(statsFrame, UDim.new(0, 6))
    
    -- 统计标题
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Name = "StatsTitle"
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.Position = UDim2.new(0, 0, 0, 0)
    statsTitle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    statsTitle.Text = "岛屿统计"
    statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsTitle.TextScaled = true
    statsTitle.Font = UIConfig.Font
    statsTitle.Parent = statsFrame
    UIConfig.CreateCorner(statsTitle, UDim.new(0, 6))
    
    -- 防御等级
    local defenseLevel = math.min(math.floor((islandData.towerCount or 0) / maxTowers * 5) + 1, 5)
    local defenseLevelLabel = Instance.new("TextLabel")
    defenseLevelLabel.Name = "DefenseLevelLabel"
    defenseLevelLabel.Size = UDim2.new(1, -20, 0, 25)
    defenseLevelLabel.Position = UDim2.new(0, 10, 0, 40)
    defenseLevelLabel.BackgroundTransparency = 1
    defenseLevelLabel.Text = string.format("防御等级: %d/5", defenseLevel)
    defenseLevelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    defenseLevelLabel.TextScaled = true
    defenseLevelLabel.Font = UIConfig.Font
    defenseLevelLabel.TextXAlignment = Enum.TextXAlignment.Left
    defenseLevelLabel.Parent = statsFrame
    
    -- 维护费用
    local maintenanceCost = (islandData.towerCount or 0) * 5 + math.floor((islandData.arrowCount or 0) / 100) * 2
    local maintenanceLabel = Instance.new("TextLabel")
    maintenanceLabel.Name = "MaintenanceLabel"
    maintenanceLabel.Size = UDim2.new(1, -20, 0, 25)
    maintenanceLabel.Position = UDim2.new(0, 10, 0, 70)
    maintenanceLabel.BackgroundTransparency = 1
    maintenanceLabel.Text = string.format("每日维护费用: %d金币", maintenanceCost)
    maintenanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    maintenanceLabel.TextScaled = true
    maintenanceLabel.Font = UIConfig.Font
    maintenanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    maintenanceLabel.Parent = statsFrame
    
    -- 预计收益
    local dailyIncome = (islandData.towerCount or 0) * 20 + defenseLevel * 10
    local incomeLabel = Instance.new("TextLabel")
    incomeLabel.Name = "IncomeLabel"
    incomeLabel.Size = UDim2.new(1, -20, 0, 25)
    incomeLabel.Position = UDim2.new(0, 10, 0, 100)
    incomeLabel.BackgroundTransparency = 1
    incomeLabel.Text = string.format("预计每日收益: %d金币", dailyIncome)
    incomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    incomeLabel.TextScaled = true
    incomeLabel.Font = UIConfig.Font
    incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    incomeLabel.Parent = statsFrame
    
    -- 净收益
    local netIncome = dailyIncome - maintenanceCost
    local netIncomeLabel = Instance.new("TextLabel")
    netIncomeLabel.Name = "NetIncomeLabel"
    netIncomeLabel.Size = UDim2.new(1, -20, 0, 25)
    netIncomeLabel.Position = UDim2.new(0, 10, 0, 130)
    netIncomeLabel.BackgroundTransparency = 1
    netIncomeLabel.Text = string.format("净收益: %d金币/天", netIncome)
    if netIncome > 0 then
        netIncomeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif netIncome < 0 then
        netIncomeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        netIncomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    netIncomeLabel.TextScaled = true
    netIncomeLabel.Font = UIConfig.Font
    netIncomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    netIncomeLabel.Parent = statsFrame
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
    local UIController = Knit.GetController('UIController')
    
    -- 监听显示岛屿管理UI事件
    UIController.ShowIslandManageUI:Connect(function()
        _screenGui.Enabled = true
        loadPlayerIslands()
    end)
    
    -- 监听金币更新事件
    UIController.UpdateGoldUI:Connect(function()
        -- 如果当前有选中的岛屿，刷新详情显示
        if _selectedIsland and _selectedIslandData then
            updateIslandDetails(_selectedIslandData)
        end
    end)
end):catch(warn)