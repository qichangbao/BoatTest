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

-- 初始化远程事件通信通道（客户端->服务端）
local ASSEMBLE_BOAT_RE_NAME = 'AssembleBoatEvent'
local assembleEvent = ReplicatedStorage:FindFirstChild(ASSEMBLE_BOAT_RE_NAME) or Instance.new('RemoteEvent')
assembleEvent.Name = ASSEMBLE_BOAT_RE_NAME
assembleEvent.Parent = ReplicatedStorage

-- 初始化更新UI事件
local UPDATE_MAINUI_RE_NAME = 'UpdateMainUIEvent'
local updateMainUIEvent = ReplicatedStorage:FindFirstChild(UPDATE_MAINUI_RE_NAME) or Instance.new('RemoteEvent')
updateMainUIEvent.Name = UPDATE_MAINUI_RE_NAME
updateMainUIEvent.Parent = ReplicatedStorage

-- 初始化库存界面远程事件
local INVENTORY_BE_NAME = 'InventoryEvent'
local inventoryEvent = ReplicatedStorage:FindFirstChild(INVENTORY_BE_NAME) or Instance.new('BindableEvent')
inventoryEvent.Name = INVENTORY_BE_NAME
inventoryEvent.Parent = ReplicatedStorage

local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Name = 'BoatControlUI'
ScreenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

local StartButton = Instance.new('TextButton')
-- 启航按钮布局
StartButton.Size = UDim2.new(0.2, 0, 0.1, 0)
StartButton.Position = UDim2.new(0.05, 0, 0.45, 0)
StartButton.Text = '启航'
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 24
StartButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
StartButton.Parent = ScreenGui

-- 止航按钮
local StopButton = Instance.new('TextButton')
StopButton.Size = UDim2.new(0.2, 0, 0.1, 0)
StopButton.Position = UDim2.new(0.05, 0, 0.45, 0)  -- 原启航按钮Y轴位置调整为0.35
StopButton.Text = '止航'
StopButton.Font = Enum.Font.SourceSansBold
StopButton.TextSize = 24
StopButton.BackgroundColor3 = Color3.fromRGB(215, 0, 0)
StopButton.Visible = false  -- 初始隐藏止航按钮
StopButton.Parent = ScreenGui

-- 抽奖按钮
local LootButton = Instance.new('TextButton')
LootButton.Size = UDim2.new(0.2, 0, 0.1, 0)
LootButton.Position = UDim2.new(0.75, 0, 0.45, 0) -- 右侧5%位置
LootButton.Text = '抽奖'
LootButton.Font = Enum.Font.SourceSansBold
LootButton.TextSize = 24
LootButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
LootButton.Parent = ScreenGui

-- 宝箱选择弹窗
local LootPopup = Instance.new('Frame')
LootPopup.Size = UDim2.new(0.6, 0, 0.4, 0)
LootPopup.Position = UDim2.new(0.2, 0, 0.3, 0)
LootPopup.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LootPopup.Visible = false
LootPopup.Parent = ScreenGui

-- 创建4个宝箱按钮
local boxPrices = {5, 15, 50, 100}
for i = 1, 4 do
    local BoxButton = Instance.new('TextButton')
    BoxButton.Size = UDim2.new(0.2, 0, 0.8, 0)
    BoxButton.Position = UDim2.new(0.05 + (i-1)*0.25, 0, 0.1, 0)
    BoxButton.Text = boxPrices[i]..'黄金'
    BoxButton.Font = Enum.Font.SourceSans
    BoxButton.TextSize = 18
    BoxButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    BoxButton.Parent = LootPopup
end

-- 点击事件处理：向服务端发送船只组装请求
StartButton.MouseButton1Click:Connect(function()
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..Players.LocalPlayer.UserId)
    if boat then
        return
    end
    assembleEvent:FireServer()
end)

-- 初始化止航远程事件
local STOP_BOAT_RE_NAME = 'StopBoatEvent'
local stopEvent = ReplicatedStorage:FindFirstChild(STOP_BOAT_RE_NAME) or Instance.new('RemoteEvent')
stopEvent.Name = STOP_BOAT_RE_NAME
stopEvent.Parent = ReplicatedStorage

local STOP_BOAT_BE_NAME = 'StopBoatEventBE'
local stopEventBE = ReplicatedStorage:FindFirstChild(STOP_BOAT_BE_NAME) or Instance.new('BindableEvent')
stopEventBE.Name = STOP_BOAT_BE_NAME
stopEventBE.Parent = ReplicatedStorage

-- 止航按钮点击事件
StopButton.MouseButton1Click:Connect(function()
    stopEventBE:Fire()
    stopEvent:FireServer()
end)

updateMainUIEvent.OnClientEvent:Connect(function(data)
    StartButton.Visible = not data.explore
    StopButton.Visible = data.explore
    -- 通过事件通知隐藏库存界面
    inventoryEvent:Fire(not data.explore)
end)

-- 初始化抽奖远程事件
local LOOT_EVENT_NAME = 'LootEvent'
local lootEvent = ReplicatedStorage:FindFirstChild(LOOT_EVENT_NAME)

-- 抽奖按钮点击事件
LootButton.MouseButton1Click:Connect(function()
    LootPopup.Visible = true
end)

-- 宝箱按钮点击处理
for _, boxButton in ipairs(LootPopup:GetChildren()) do
    if boxButton:IsA('TextButton') then
        boxButton.MouseButton1Click:Connect(function()
            local price = tonumber(string.match(boxButton.Text, '%d+'))
            lootEvent:FireServer(price)
            LootPopup.Visible = false
        end)
    end
end

-- 金币显示标签
local GoldLabel = Instance.new('TextLabel')
GoldLabel.Size = UDim2.new(0.25, 0, 0.08, 0)
GoldLabel.Position = UDim2.new(0.7, 0, 0.85, 0)
GoldLabel.Text = "黄金: 0"
GoldLabel.Font = Enum.Font.SourceSansSemibold
GoldLabel.TextSize = 20
GoldLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
GoldLabel.BackgroundTransparency = 1
GoldLabel.Parent = ScreenGui

-- 初始化金币更新远程事件
local GOLD_UPDATE_RE_NAME = 'GoldUpdateEvent'
local goldEvent = ReplicatedStorage:FindFirstChild(GOLD_UPDATE_RE_NAME) or Instance.new('RemoteEvent')
goldEvent.Name = GOLD_UPDATE_RE_NAME
goldEvent.Parent = ReplicatedStorage

-- 金币更新处理方法
local function updateGoldDisplay(newAmount)
    GoldLabel.Text = string.format("黄金: %d", newAmount)
end

-- 监听金币更新事件
goldEvent.OnClientEvent:Connect(updateGoldDisplay)

-- 创建关闭按钮
local CloseButton = Instance.new('TextButton')
CloseButton.Size = UDim2.new(0.1, 0, 0.1, 0)
CloseButton.Position = UDim2.new(0.9, 0, 0.05, 0)
CloseButton.Text = '×'
CloseButton.Font = Enum.Font.GothamBlack
CloseButton.TextSize = 28
CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
CloseButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
CloseButton.Parent = LootPopup

-- 添加按钮点击动画
CloseButton.MouseButton1Click:Connect(function()
    LootPopup.Visible = false
end)

CloseButton.MouseButton1Down:Connect(function()
    CloseButton.Size = UDim2.new(0.09, 0, 0.09, 0)
    wait(0.1)
    CloseButton.Size = UDim2.new(0.1, 0, 0.1, 0)
end)