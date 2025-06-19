--[[
模块功能：船只组装控制界面
版本：1.0.0
作者：Trea
修改记录：
2024-02-20 创建基础UI框架
2024-02-25 添加远程事件通信
--]]
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local _buttonTextSize = 24
local _buttonSize = UDim2.new(0, 100, 0, 60)

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'MainUI_GUI'
_screenGui.Parent = PlayerGui

-- 启航按钮布局
local _startBoatButton = Instance.new('TextButton')
_startBoatButton.Name = 'StartBoatButton'
_startBoatButton.AnchorPoint = Vector2.new(0.5, 0.5)
_startBoatButton.Size = _buttonSize
_startBoatButton.Position = UDim2.new(0, 80, 1, -60)
_startBoatButton.Text = LanguageConfig.Get(10004)
_startBoatButton.Font = UIConfig.Font
_startBoatButton.TextSize = _buttonTextSize
_startBoatButton.BackgroundColor3 = Color3.fromRGB(0, 164, 209)  -- 海洋蓝
_startBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_startBoatButton.Parent = _screenGui
UIConfig.CreateCorner(_startBoatButton)
-- 点击事件处理：向服务端发送船只组装请求
_startBoatButton.MouseButton1Click:Connect(function()
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..Players.LocalPlayer.UserId)
    if boat then
        boat:Destroy()
    end

    Knit.GetService('BoatAssemblingService'):AssembleBoat():andThen(function(tipId)
        Knit.GetController('UIController').ShowTip:Fire(tipId)
    end)
end)

-- 止航按钮
local _stopBoatButton = Instance.new('TextButton')
_stopBoatButton.AnchorPoint = Vector2.new(0.5, 0.5)
_stopBoatButton.Name = 'StopBoatButton'
_stopBoatButton.Size = _buttonSize
_stopBoatButton.Position = UDim2.new(0, 80, 1, -60)
_stopBoatButton.Text = LanguageConfig.Get(10005)
_stopBoatButton.Font = UIConfig.Font
_stopBoatButton.TextSize = _buttonTextSize
_stopBoatButton.BackgroundColor3 = Color3.fromRGB(209, 52, 56)  -- 警示红
_stopBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_stopBoatButton.Visible = false
_stopBoatButton.Parent = _screenGui
UIConfig.CreateCorner(_stopBoatButton)
-- 止航按钮点击事件
_stopBoatButton.MouseButton1Click:Connect(function()
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..Players.LocalPlayer.UserId)
    if boat then
        boat:Destroy()
    end
    Knit.GetService('BoatAssemblingService'):StopBoat()
end)

-- 创建添加部件按钮
local _addBoatPartButton = Instance.new('TextButton')
_addBoatPartButton.AnchorPoint = Vector2.new(0.5, 0.5)
_addBoatPartButton.Name = 'AddBoatPartButton'
_addBoatPartButton.Size = _buttonSize
_addBoatPartButton.Position = UDim2.new(0, 80, 1, -140)
_addBoatPartButton.Text = LanguageConfig.Get(10006)
_addBoatPartButton.Font = UIConfig.Font
_addBoatPartButton.TextSize = _buttonTextSize
_addBoatPartButton.BackgroundColor3 = Color3.fromRGB(0, 164, 209)
_addBoatPartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_addBoatPartButton.Visible = false
_addBoatPartButton.Parent = _screenGui
UIConfig.CreateCorner(_addBoatPartButton)
-- 添加部件按钮点击事件
_addBoatPartButton.MouseButton1Click:Connect(function()
    Knit.GetService('BoatAssemblingService'):AddUnusedPartsToBoat(Players.LocalPlayer):andThen(function(tipId)
        Knit.GetController('UIController').ShowTip:Fire(tipId)
        _addBoatPartButton.Visible = false
    end)
end)
Knit.GetController('UIController').ShowAddBoatPartButton:Connect(function(isShow)
    _addBoatPartButton.Visible = isShow
end)

-- 消息框自动隐藏相关变量
local _messageHideTimer = nil
local _fadeInTween = nil
local _fadeOutTween = nil
local _fadeOutConnection = nil
local MESSAGE_DISPLAY_TIME = 5  -- 显示5秒

local _messageFrame = Instance.new('Frame')
_messageFrame.Name = 'MessageFrame'
_messageFrame.AnchorPoint = Vector2.new(0, 0)
_messageFrame.Size = UDim2.new(0, 200, 0, 150)
_messageFrame.Position = UDim2.new(0, 0, 0, 0)
_messageFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
_messageFrame.BackgroundTransparency = 1  -- 初始完全透明
_messageFrame.BorderSizePixel = 0
_messageFrame.Visible = false  -- 初始隐藏
_messageFrame.Parent = _screenGui
UIConfig.CreateCorner(_messageFrame, UDim.new(0, 8))

-- 滚动框
local _scrollingFrame = Instance.new('ScrollingFrame')
_scrollingFrame.Name = 'MessageScrollingFrame'
_scrollingFrame.AnchorPoint = Vector2.new(0, 0)
_scrollingFrame.Size = UDim2.new(0, _messageFrame.Size.X.Offset - 4, 0, _messageFrame.Size.Y.Offset - 4)
_scrollingFrame.Position = UDim2.new(0, 2, 0, 2)
_scrollingFrame.BackgroundTransparency = 1
_scrollingFrame.ScrollBarThickness = 8
_scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
_scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
_scrollingFrame.Parent = _messageFrame

-- 消息列表布局
local _yOffset = 2
local _messageListLayout = Instance.new('UIListLayout')
_messageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
_messageListLayout.Padding = UDim.new(0, _yOffset)  -- 消息间距2像素
_messageListLayout.Parent = _scrollingFrame

-- 消息数据存储
local _messages = {}
local _maxMessages = 50

-- 消息类型颜色配置
local _messageColors = {
    ['info'] = Color3.fromRGB(100, 200, 255),     -- 蓝色 - 信息
    ['success'] = Color3.fromRGB(100, 255, 100), -- 绿色 - 成功
    ['warning'] = Color3.fromRGB(255, 200, 100), -- 橙色 - 警告
    ['error'] = Color3.fromRGB(255, 100, 100),   -- 红色 - 错误
    ['system'] = Color3.fromRGB(200, 200, 200),  -- 灰色 - 系统
}

-- 隐藏消息框（渐出效果）
local function hideMessageFrame()
    -- 取消之前的动画
    if _fadeInTween then
        _fadeInTween:Cancel()
    end
    if _fadeOutTween then
        _fadeOutTween:Cancel()
    end
    
    -- 断开之前的连接
    if _fadeOutConnection then
        _fadeOutConnection:Disconnect()
        _fadeOutConnection = nil
    end
    
    -- 创建渐出动画
    local tweenInfo = TweenInfo.new(
        0.3,  -- 持续时间
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    _fadeOutTween = TweenService:Create(_messageFrame, tweenInfo, {
        BackgroundTransparency = 1
    })
    
    _fadeOutTween:Play()
    
    -- 动画完成后隐藏
    _fadeOutConnection = _fadeOutTween.Completed:Connect(function()
        _messageFrame.Visible = false
        if _fadeOutConnection then
            _fadeOutConnection:Disconnect()
            _fadeOutConnection = nil
        end
    end)
end

-- 显示消息框（渐入效果）
local function showMessageFrame()
    -- 取消之前的动画
    if _fadeInTween then
        _fadeInTween:Cancel()
    end
    if _fadeOutTween then
        _fadeOutTween:Cancel()
    end
    
    -- 重置隐藏计时器
    if _messageHideTimer then
        pcall(task.cancel, _messageHideTimer)
        _messageHideTimer = nil
    end
    
    -- 显示消息框
    _messageFrame.Visible = true
    
    -- 如果消息框已经显示（透明度小于1），直接重置计时器
    if _messageFrame.BackgroundTransparency < 1 then
        _messageHideTimer = task.delay(MESSAGE_DISPLAY_TIME, function()
            hideMessageFrame()
        end)
        return
    end
    
    -- 创建渐入动画（仅在消息框完全透明时）
    local tweenInfo = TweenInfo.new(
        0.3,  -- 持续时间
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    _fadeInTween = TweenService:Create(_messageFrame, tweenInfo, {
        BackgroundTransparency = 0.2
    })
    
    _fadeInTween:Play()
    
    -- 设置隐藏计时器
    _messageHideTimer = task.delay(MESSAGE_DISPLAY_TIME, function()
        hideMessageFrame()
    end)
end

-- 添加消息函数
local function addMessage(messageType, messageText)
    -- 显示消息框
    showMessageFrame()
    
    -- 如果消息数量超过最大值，删除最旧的消息
    if #_messages >= _maxMessages then
        local oldestMessage = _messages[1]
        if oldestMessage and oldestMessage.Parent then
            oldestMessage:Destroy()
        end
        table.remove(_messages, 1)
    end
    
    -- 创建新消息标签
    local messageLabel = Instance.new('TextLabel')
    messageLabel.Position = UDim2.new(0, 5, 0, 0)  -- 左边5像素间距
    messageLabel.Text = messageText
    messageLabel.Font = UIConfig.Font
    messageLabel.TextSize = 16
    messageLabel.TextColor3 = _messageColors[messageType] or _messageColors['info']
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.LayoutOrder = #_messages + 1
    
    -- 计算文本高度（使用固定宽度190像素，这是滚动框宽度200减去间距）
    local textService = game:GetService('TextService')
    local textSize = textService:GetTextSize(
        messageText,
        16,  -- 使用正确的字体大小
        UIConfig.Font,
        Vector2.new(190, math.huge)
    )
    
    -- 设置正确的尺寸并添加到父级
    messageLabel.Size = UDim2.new(1, -10, 0, math.max(20, textSize.Y + _yOffset))
    messageLabel.Parent = _scrollingFrame
    -- 添加到消息列表
    table.insert(_messages, messageLabel)
    
    -- 重新计算滚动框大小
    local totalHeight = 0
    for _, msg in ipairs(_messages) do
        totalHeight = totalHeight + msg.Size.Y.Offset + _yOffset
    end
    _scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    _scrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, totalHeight - _scrollingFrame.AbsoluteSize.Y))
end

local _messageInputFrame = Instance.new('Frame')
_messageInputFrame.AnchorPoint = _messageFrame.AnchorPoint
_messageInputFrame.Size = _messageFrame.Size
_messageInputFrame.Position = _messageFrame.Position
_messageInputFrame.BackgroundTransparency = 1  -- 初始完全透明
_messageInputFrame.Visible = true  -- 初始隐藏
_messageInputFrame.Parent = _screenGui

_messageInputFrame.MouseEnter:Connect(function()
    showMessageFrame()
end)

-- 金币显示标签
local _goldLabel = Instance.new('TextLabel')
_goldLabel.Name = 'GoldLabel'
_goldLabel.AnchorPoint = Vector2.new(1, 1)
_goldLabel.Position = UDim2.new(1, -20, 1, -20)
_goldLabel.Text = LanguageConfig.Get(10007) .. ": 0"
_goldLabel.Font = UIConfig.Font
_goldLabel.TextSize = 20
_goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
_goldLabel.BackgroundTransparency = 1
_goldLabel.TextXAlignment = Enum.TextXAlignment.Right
_goldLabel.Parent = _screenGui

-- 玩家按钮
local _playersButton = Instance.new('TextButton')
_playersButton.Name = 'PlayersButton'
_playersButton.AnchorPoint = Vector2.new(0.5, 0.5)
_playersButton.Size = _buttonSize
_playersButton.Position = UDim2.new(1, -60, 1, -240)
_playersButton.Text = LanguageConfig.Get(10026)
_playersButton.Font = UIConfig.Font
_playersButton.TextSize = _buttonTextSize
_playersButton.BackgroundColor3 = Color3.fromRGB(103, 80, 164)  -- 深紫罗兰色
_playersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_playersButton.Parent = _screenGui
-- 玩家按钮点击事件
_playersButton.MouseButton1Click:Connect(function()
    Knit.GetController('UIController').ShowPlayersUI:Fire()
end)

UIConfig.CreateCorner(_playersButton)

-- Buff按钮
local _buffButton = Instance.new('TextButton')
_buffButton.Name = 'BuffButton'
_buffButton.AnchorPoint = Vector2.new(0.5, 0.5)
_buffButton.Size = _buttonSize
_buffButton.Position = UDim2.new(1, -60, 1, -320)
_buffButton.Text = "BUFF"
_buffButton.Font = UIConfig.Font
_buffButton.TextSize = _buttonTextSize
_buffButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)  -- 橙色
_buffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_buffButton.Parent = _screenGui
-- Buff按钮点击事件
_buffButton.MouseButton1Click:Connect(function()
    Knit.GetController('UIController').ShowBuffUI:Fire()
end)
UIConfig.CreateCorner(_buffButton)

-- 抽奖按钮
local _lootButton = Instance.new('TextButton')
_lootButton.Name = 'LootButton'
_lootButton.AnchorPoint = Vector2.new(0.5, 0.5)
_lootButton.Size = _buttonSize
_lootButton.Position = UDim2.new(1, -60, 1, -160)
_lootButton.Text = LanguageConfig.Get(10008)
_lootButton.Font = UIConfig.Font
_lootButton.TextSize = _buttonTextSize
_lootButton.Active = false
_lootButton.AutoButtonColor = false
_lootButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
_lootButton.Parent = _screenGui

local LOOT_TIME_COOLDOWN = 3.6
-- 倒计时标签
local _cooldownLabel = Instance.new('TextLabel')
_cooldownLabel.Size = UDim2.new(1, 0, 1, 0)
_cooldownLabel.Text = tostring(LOOT_TIME_COOLDOWN)
_cooldownLabel.TextColor3 = Color3.new(0.925490, 0.231372, 0.231372)
_cooldownLabel.TextSize = 32
_cooldownLabel.BackgroundTransparency = 0.7
_cooldownLabel.BackgroundColor3 = Color3.new(0,0,0)
_cooldownLabel.Visible = false
_cooldownLabel.Parent = _lootButton
UIConfig.CreateCorner(_cooldownLabel)

local _remainingTime = LOOT_TIME_COOLDOWN

local function updateCooldown()
    if _remainingTime > 0 then
        _cooldownLabel.Text = string.format("%.1f", _remainingTime)
        _cooldownLabel.Visible = true
        _lootButton.Active = false
    else
        _cooldownLabel.Visible = false
        _lootButton.Active = true
        _lootButton.AutoButtonColor = true
        _lootButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
    end
end

-- 初始化冷却计时器
local _renderSteppedConnection = RunService.Heartbeat:Connect(function(dt)
    if _remainingTime > 0 then
        _remainingTime = math.max(0, _remainingTime - dt)
        updateCooldown()
    end
end)

-- 抽奖按钮点击事件
_lootButton.MouseButton1Click:Connect(function()
    if not _lootButton.Active then
        return
    end
    _remainingTime = LOOT_TIME_COOLDOWN
    _lootButton.Active = false
    _lootButton.AutoButtonColor = false
    _lootButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local LootService = Knit.GetService('LootService')
    LootService:Loot():andThen(function(tipId, itemName)
        if itemName then
            local str = string.format(LanguageConfig.Get(tipId), itemName)
            Knit.GetController('UIController').ShowTip:Fire(str)
        else
            Knit.GetController('UIController').ShowTip:Fire(tipId)
        end
    end)
end)
UIConfig.CreateCorner(_lootButton)

-- 背包按钮
local _backpackButton = Instance.new('TextButton')
_backpackButton.Name = 'BackpackButton'
_backpackButton.AnchorPoint = Vector2.new(0.5, 0.5)
_backpackButton.Size = _buttonSize
_backpackButton.Position = UDim2.new(1, -60, 1, -80)
_backpackButton.Text = LanguageConfig.Get(10025)
_backpackButton.Font = UIConfig.Font
_backpackButton.TextSize = _buttonTextSize
_backpackButton.BackgroundColor3 = Color3.fromRGB(147, 51, 234)  -- 柔和紫罗兰色
_backpackButton.Parent = _screenGui
-- 背包按钮点击事件
_backpackButton.MouseButton1Click:Connect(function()
    Knit.GetController('UIController').ShowInventoryUI:Fire()
end)
UIConfig.CreateCorner(_backpackButton)

-- 岛屿管理按钮
local _islandManageButton = Instance.new('TextButton')
_islandManageButton.Name = 'IslandManageButton'
_islandManageButton.AnchorPoint = Vector2.new(0.5, 0.5)
_islandManageButton.Size = _buttonSize
_islandManageButton.Position = UDim2.new(0, 60, 1, -240)
_islandManageButton.Text = LanguageConfig.Get(10066)
_islandManageButton.Font = UIConfig.Font
_islandManageButton.TextSize = _buttonTextSize
_islandManageButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)  -- 森林绿
_islandManageButton.TextColor3 = Color3.fromRGB(255, 255, 255)
_islandManageButton.Parent = _screenGui
-- 岛屿管理按钮点击事件
_islandManageButton.MouseButton1Click:Connect(function()
    Knit.GetController('UIController').ShowIslandManageUI:Fire()
end)
UIConfig.CreateCorner(_islandManageButton)

local islandOccupyConnection = nil
-- 岛屿占领进度条
local _islandOccupyProgressContainer = Instance.new("Frame")
_islandOccupyProgressContainer.Name = "IslandOccupyProgressContainer"
_islandOccupyProgressContainer.Size = UDim2.new(0.3, 0, 0.1, 0)
_islandOccupyProgressContainer.Position = UDim2.new(0.5, 0, 0.7, 0)
_islandOccupyProgressContainer.AnchorPoint = Vector2.new(0.5, 0.5)
_islandOccupyProgressContainer.BackgroundTransparency = 1
_islandOccupyProgressContainer.Visible = false
_islandOccupyProgressContainer.Parent = _screenGui

-- 添加提示文本
local _islandOccupyTipText = Instance.new("TextLabel")
_islandOccupyTipText.Name = "IslandOccupyTipText"
_islandOccupyTipText.Size = UDim2.new(1, 0, 0.3, 0)
_islandOccupyTipText.Position = UDim2.new(0, 0, 0, 0)
_islandOccupyTipText.Text = LanguageConfig.Get(10037)
_islandOccupyTipText.TextColor3 = Color3.fromRGB(255, 255, 255)
_islandOccupyTipText.BackgroundTransparency = 1
_islandOccupyTipText.Font = UIConfig.Font
_islandOccupyTipText.TextSize = 20
_islandOccupyTipText.Parent = _islandOccupyProgressContainer

-- 创建进度条背景
local _islandOccupyProgressBg = Instance.new("Frame")
_islandOccupyProgressBg.Name = "ProgressBg"
_islandOccupyProgressBg.Size = UDim2.new(1, 0, 0.3, 0)
_islandOccupyProgressBg.Position = UDim2.new(0, 0, 0.4, 0)
_islandOccupyProgressBg.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
_islandOccupyProgressBg.BorderSizePixel = 0
_islandOccupyProgressBg.Parent = _islandOccupyProgressContainer

-- 创建进度条填充
local _islandOccupyProgressFill = Instance.new("Frame")
_islandOccupyProgressFill.Name = "IslandOccupyProgressFill"
_islandOccupyProgressFill.Size = UDim2.new(0, 0, 1, 0) -- 初始宽度为0
_islandOccupyProgressFill.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- 绿色
_islandOccupyProgressFill.BorderSizePixel = 0
_islandOccupyProgressFill.Parent = _islandOccupyProgressBg

-- 倒计时文本
local _islandOccupyCountdownText = Instance.new("TextLabel")
_islandOccupyCountdownText.Name = "IslandOccupyCountdownText"
_islandOccupyCountdownText.Size = UDim2.new(1, 0, 0.3, 0)
_islandOccupyCountdownText.Position = UDim2.new(0, 0, 0.8, 0)
_islandOccupyCountdownText.Text = tostring(GameConfig.OccupyTime)
_islandOccupyCountdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
_islandOccupyCountdownText.BackgroundTransparency = 1
_islandOccupyCountdownText.Font = UIConfig.Font
_islandOccupyCountdownText.TextSize = 18
_islandOccupyCountdownText.Parent = _islandOccupyProgressContainer

local function ShowOccupingLayer(isShow)
    if islandOccupyConnection then
        islandOccupyConnection:Disconnect()
        islandOccupyConnection = nil
    end
    _islandOccupyProgressContainer.Visible = isShow
    if not _islandOccupyProgressContainer.Visible then
        return
    end
    
    _islandOccupyProgressFill.Size = UDim2.new(0, 0, 1, 0) -- 初始宽度为0
    _islandOccupyCountdownText.Text = tostring(GameConfig.OccupyTime)
    -- 使用RenderStepped实现平滑动画
    local startTime = tick()
    local totalTime = GameConfig.OccupyTime
    islandOccupyConnection = RunService.Heartbeat:Connect(function()
        local endTime = tick() - startTime
        -- 检查是否完成
        if endTime >= totalTime then
            if islandOccupyConnection then
                islandOccupyConnection:Disconnect()
                islandOccupyConnection = nil
            end
            return
        end
        local timeLeft = math.max(0, totalTime - endTime)
        local progress = math.min(1, endTime / totalTime) -- 进度从0到1
        
        -- 更新倒计时文本（取整显示）
        local secondsLeft = math.ceil(timeLeft)
        _islandOccupyCountdownText.Text = tostring(secondsLeft)
        
        -- 更新进度条（平滑过渡）
        _islandOccupyProgressFill.Size = UDim2.new(progress, 0, 1, 0)
    end)
end

local function Destroy()
    print("MainUI Destroy")
    if _renderSteppedConnection then
        _renderSteppedConnection:Disconnect()
        _renderSteppedConnection = nil
    end
    
    -- 清理消息框相关资源
    if _messageHideTimer then
        pcall(task.cancel, _messageHideTimer)
        _messageHideTimer = nil
    end
    
    if _fadeInTween then
        _fadeInTween:Cancel()
        _fadeInTween = nil
    end
    
    if _fadeOutTween then
        _fadeOutTween:Cancel()
        _fadeOutTween = nil
    end
    
    if _fadeOutConnection then
        _fadeOutConnection:Disconnect()
        _fadeOutConnection = nil
    end
end

Knit:OnStart():andThen(function()
    local BoatAssemblingService = Knit.GetService('BoatAssemblingService')
    BoatAssemblingService.UpdateMainUI:Connect(function(data)
        _startBoatButton.Visible = not data.explore
        _stopBoatButton.Visible = data.explore
        _addBoatPartButton.Visible = false
    end)
    
    Knit.GetController('UIController').AddUI:Fire(_screenGui, Destroy)
    Knit.GetController('UIController').UpdateGoldUI:Connect(function()
        if not ClientData.Gold then
            return
        end
        _goldLabel.Text = LanguageConfig.Get(10007) .. ": " .. ClientData.Gold
    end)
    Knit.GetController('UIController').IsAdmin:Connect(function()
        if ClientData.IsAdmin then
            -- 用户控制按钮
            local _adminButton = Instance.new('TextButton')
            _adminButton.Name = 'AdminButton'
            _adminButton.AnchorPoint = Vector2.new(0.5, 0.5)
            _adminButton.Size = _buttonSize
            _adminButton.Position = UDim2.new(1, -60, 0, 60) -- 右侧5%位置
            _adminButton.Text = '数据库'
            _adminButton.Font = UIConfig.Font
            _adminButton.TextSize = _buttonTextSize
            _adminButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
            _adminButton.Parent = _screenGui
            UIConfig.CreateCorner(_adminButton)
            
            -- 用户控制按钮点击事件
            _adminButton.MouseButton1Click:Connect(function()
                Knit.GetController('UIController').ShowAdminUI:Fire()
            end)
        end
    end)
    -- 注册系统消息接口
    Knit.GetController('UIController').ShowSystemMessage:Connect(function(messageText, messageType)
        addMessage(messageText, messageType)
    end)
    -- 注册显示占领中接口
    Knit.GetController('UIController').ShowOccupingUI:Connect(function(isShow)
        ShowOccupingLayer(isShow)
    end)
    -- 注册系统消息接口
    local SystemService = Knit.GetService('SystemService')
    SystemService.SystemMessage:Connect(function(messageType, tipId, ...)
        local messageText = string.format(LanguageConfig.Get(tipId), ...)
        addMessage(messageType, messageText)
    end)

    Knit.GetService("LandService").OccupyStart:Connect(function(playerName, landName)
        addMessage("info", string.format(LanguageConfig.Get(10081), playerName, landName))
    end)

    -- 注册占领成功接口
    Knit.GetService("LandService").OccupyFinish:Connect(function(userId, playerName, landName)
        if userId == Players.LocalPlayer.UserId then
            ShowOccupingLayer(false)
            Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10038), landName))
        end

        addMessage("info", string.format(LanguageConfig.Get(10080), playerName, landName))
    end)

    -- 注册占领失败接口
    Knit.GetService("LandService").OccupyFail:Connect(function(userId, playerName, landName)
        if userId == Players.LocalPlayer.UserId then
            ShowOccupingLayer(false)
            Knit.GetController('UIController').ShowTip:Fire(10065)
        end
        
        addMessage("info", string.format(LanguageConfig.Get(10079), playerName, landName))
    end)

    
    addMessage("system", LanguageConfig.Get(10050))
end):catch(warn)