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

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'MainUI'
_screenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

-- 启航按钮布局
local _startBoatButton = Instance.new('TextButton')
_startBoatButton.Name = 'StartBoatButton'
_startBoatButton.Size = UDim2.new(0.2, 0, 0.1, 0)
_startBoatButton.Position = UDim2.new(0.05, 0, 0.45, 0)
_startBoatButton.Text = LanguageConfig:Get(10004)
_startBoatButton.Font = Enum.Font.SourceSansBold
_startBoatButton.TextSize = 24
_startBoatButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
_startBoatButton.Parent = _screenGui
-- 点击事件处理：向服务端发送船只组装请求
_startBoatButton.MouseButton1Click:Connect(function()
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..Players.LocalPlayer.UserId)
    if boat then
        boat:Destroy()
    end

    local BoatAssemblingService = Knit.GetService('BoatAssemblingService')
    BoatAssemblingService:AssembleBoat():andThen(function(tipId)
        Knit.GetController('UIController').ShowTip:Fire(tipId)

        local inventoryUI = Players.LocalPlayer:WaitForChild('PlayerGui'):FindFirstChild('InventoryUI')
        if inventoryUI then
            local inventoryFrame = inventoryUI:FindFirstChild('InventoryFrame')
            if inventoryFrame then
                inventoryFrame.Visible = false
            end
        end
    end)
end)

-- 止航按钮
local _stopBoatButton = Instance.new('TextButton')
_stopBoatButton.Name = 'StopBoatButton'
_stopBoatButton.Size = UDim2.new(0.2, 0, 0.1, 0)
_stopBoatButton.Position = UDim2.new(0.05, 0, 0.45, 0)  -- 原启航按钮Y轴位置调整为0.35
_stopBoatButton.Text = LanguageConfig:Get(10005)
_stopBoatButton.Font = Enum.Font.SourceSansBold
_stopBoatButton.TextSize = 24
_stopBoatButton.BackgroundColor3 = Color3.fromRGB(215, 0, 0)
_stopBoatButton.Visible = false  -- 初始隐藏止航按钮
_stopBoatButton.Parent = _screenGui
-- 止航按钮点击事件
_stopBoatButton.MouseButton1Click:Connect(function()
    --stopEventBE:Fire()
    local BoatAssemblingService = Knit.GetService('BoatAssemblingService')
    BoatAssemblingService:StopBoat():andThen(function()
        local inventoryUI = Players.LocalPlayer:WaitForChild('PlayerGui'):FindFirstChild('InventoryUI')
        if inventoryUI then
            local inventoryFrame = inventoryUI:FindFirstChild('InventoryFrame')
            if inventoryFrame then
                inventoryFrame.Visible = true
            end
        end
    end)
end)

-- 创建添加部件按钮
local _addBoatPartButton = Instance.new('TextButton')
_addBoatPartButton.Name = 'AddPartButton'
_addBoatPartButton.Size = UDim2.new(0.2, 0, 0.1, 0)
_addBoatPartButton.Position = UDim2.new(0.05, 0, 0.35, 0)
_addBoatPartButton.Text = LanguageConfig:Get(10006)
_addBoatPartButton.Font = Enum.Font.SourceSansBold
_addBoatPartButton.TextSize = 24
_addBoatPartButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
_addBoatPartButton.Visible = false
_addBoatPartButton.Parent = _screenGui
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
_goldLabel.Size = UDim2.new(0.25, 0, 0.08, 0)
_goldLabel.Position = UDim2.new(0.7, 0, 0.85, 0)
_goldLabel.Text = LanguageConfig:Get(10007) .. ": 0"
_goldLabel.Font = Enum.Font.SourceSansSemibold
_goldLabel.TextSize = 20
_goldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
_goldLabel.BackgroundTransparency = 1
_goldLabel.Parent = _screenGui

-- 抽奖按钮
local _lootButton = Instance.new('TextButton')
_lootButton.Name = '_lootButton'
_lootButton.Size = UDim2.new(0.2, 0, 0.1, 0)
_lootButton.Position = UDim2.new(0.75, 0, 0.45, 0)
_lootButton.Text = LanguageConfig:Get(10008)
_lootButton.Font = Enum.Font.SourceSansBold
_lootButton.TextSize = 24
_lootButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
_lootButton.Parent = _screenGui
_lootButton.Active = false
_lootButton.AutoButtonColor = false
_lootButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

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
RunService.Heartbeat:Connect(function(dt)
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
    LootService:Loot():andThen(function(tipId)
        Knit.GetController('UIController').ShowTip:Fire(tipId)
    end)
end)

Knit:OnStart():andThen(function()
    local PlayerAttributeService = Knit.GetService('PlayerAttributeService')
    PlayerAttributeService.ChangeGold:Connect(function(gold)
        _goldLabel.Text = LanguageConfig:Get(10007) .. ": " .. gold
    end)
    PlayerAttributeService:IsAdmin():andThen(function(isAdmin)
        if isAdmin then
            -- 用户控制按钮
            local _adminButton = Instance.new('TextButton')
            _adminButton.Name = '_adminButton'
            _adminButton.Size = UDim2.new(0.1, 0, 0.1, 0)
            _adminButton.Position = UDim2.new(0.75, 0, 0.15, 0) -- 右侧5%位置
            _adminButton.Text = '数据库'
            _adminButton.Font = Enum.Font.SourceSansBold
            _adminButton.TextSize = 24
            _adminButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
            _adminButton.Parent = _screenGui
            
            -- 用户控制按钮点击事件
            _adminButton.MouseButton1Click:Connect(function()
                Knit.GetController('UIController').ShowAdminUI:Fire()
            end)
        end
    end)

    local BoatAssemblingService = Knit.GetService('BoatAssemblingService')
    BoatAssemblingService.UpdateMainUI:Connect(function(data)
        _startBoatButton.Visible = not data.explore
        _stopBoatButton.Visible = data.explore
    end)
end):catch(warn)