--[[
模块功能：船只组装控制界面
版本：1.0.0
作者：Trea
修改记录：
2024-02-20 创建基础UI框架
2024-02-25 添加远程事件通信
--]]
print("MainUI.lua loaded")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local _buttonTextSize = 24
local _buttonSize = UDim2.new(0, 100, 0, 60)

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'MainUI_GUI'
_screenGui.Parent = PlayerGui

-- 玩家按钮
local _playersButton = Instance.new('TextButton')
_playersButton.Name = '_playersButton'
_playersButton.AnchorPoint = Vector2.new(0.5, 0.5)
_playersButton.Size = _buttonSize
_playersButton.Position = UDim2.new(0, 80, 0, 60)
_playersButton.Text = LanguageConfig:Get(10026)
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

-- 启航按钮布局
local _startBoatButton = Instance.new('TextButton')
_startBoatButton.Name = '_startBoatButton'
_startBoatButton.AnchorPoint = Vector2.new(0.5, 0.5)
_startBoatButton.Size = _buttonSize
_startBoatButton.Position = UDim2.new(0, 80, 1, -60)
_startBoatButton.Text = LanguageConfig:Get(10004)
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
_stopBoatButton.Name = '_stopBoatButton'
_stopBoatButton.Size = _buttonSize
_stopBoatButton.Position = UDim2.new(0, 80, 1, -60)
_stopBoatButton.Text = LanguageConfig:Get(10005)
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
_addBoatPartButton.Name = '_addBoatPartButton'
_addBoatPartButton.Size = _buttonSize
_addBoatPartButton.Position = UDim2.new(0, 80, 1, -140)
_addBoatPartButton.Text = LanguageConfig:Get(10006)
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

-- 金币显示标签
local _goldLabel = Instance.new('TextLabel')
_goldLabel.Name = 'GoldLabel'
_goldLabel.AnchorPoint = Vector2.new(1, 1)
_goldLabel.Position = UDim2.new(1, -20, 1, -20)
_goldLabel.Text = LanguageConfig:Get(10007) .. ": 0"
_goldLabel.Font = UIConfig.Font
_goldLabel.TextSize = 20
_goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
_goldLabel.BackgroundTransparency = 1
_goldLabel.TextXAlignment = Enum.TextXAlignment.Right
_goldLabel.Parent = _screenGui

-- 抽奖按钮
local _lootButton = Instance.new('TextButton')
_lootButton.Name = '_lootButton'
_lootButton.AnchorPoint = Vector2.new(0.5, 0.5)
_lootButton.Size = _buttonSize
_lootButton.Position = UDim2.new(1, -60, 1, -160)
_lootButton.Text = LanguageConfig:Get(10008)
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
local _renderSteppedConnection = RunService.RenderStepped:Connect(function(dt)
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
            local str = string.format(LanguageConfig:Get(tipId), itemName)
            Knit.GetController('UIController').ShowTip:Fire(str)
        else
            Knit.GetController('UIController').ShowTip:Fire(tipId)
        end
    end)
end)
UIConfig.CreateCorner(_lootButton)

-- 背包按钮
local _backpackButton = Instance.new('TextButton')
_backpackButton.Name = '_backpackButton'
_backpackButton.AnchorPoint = Vector2.new(0.5, 0.5)
_backpackButton.Size = _buttonSize
_backpackButton.Position = UDim2.new(1, -60, 1, -80)
_backpackButton.Text = LanguageConfig:Get(10025)
_backpackButton.Font = UIConfig.Font
_backpackButton.TextSize = _buttonTextSize
_backpackButton.BackgroundColor3 = Color3.fromRGB(147, 51, 234)  -- 柔和紫罗兰色
_backpackButton.Parent = _screenGui
-- 背包按钮点击事件
_backpackButton.MouseButton1Click:Connect(function()
    Knit.GetController('UIController').ShowInventoryUI:Fire()
end)
UIConfig.CreateCorner(_backpackButton)

local function Destroy()
    print("MainUI Destroy")
    if _renderSteppedConnection then
        _renderSteppedConnection:Disconnect()
        _renderSteppedConnection = nil
    end
end

Knit:OnStart():andThen(function()
    local BoatAssemblingService = Knit.GetService('BoatAssemblingService')
    BoatAssemblingService.UpdateMainUI:Connect(function(data)
        _startBoatButton.Visible = not data.explore
        _stopBoatButton.Visible = data.explore
    end)
    
    Knit.GetController('UIController').AddUI:Fire(_screenGui, Destroy)
    Knit.GetController('UIController').UpdateGoldUI:Connect(function()
        if not ClientData.Gold then
            warn("ClientData.Gold is nil")
            return
        end
        _goldLabel.Text = LanguageConfig:Get(10007) .. ": " .. ClientData.Gold
    end)
    Knit.GetController('UIController').IsAdmin:Connect(function()
        if ClientData.IsAdmin then
            -- 用户控制按钮
            local _adminButton = Instance.new('TextButton')
            _adminButton.Name = '_adminButton'
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
end):catch(warn)