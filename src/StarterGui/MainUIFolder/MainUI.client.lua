--[[
模块功能：船只组装控制界面
版本：1.0.0
作者：Trea
修改记录：
2024-02-20 创建基础UI框架
2024-02-25 添加远程事件通信
--]]
print("MainUI.client.lua loaded")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BoatAssemblingService = Knit.GetService('BoatAssemblingService')
local PlayerDataService = Knit.GetService('PlayerDataService')

local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Name = 'MainUI'
ScreenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

-- 启航按钮布局
local StartButton = Instance.new('TextButton')
StartButton.Name = 'StartButton'
StartButton.Size = UDim2.new(0.2, 0, 0.1, 0)
StartButton.Position = UDim2.new(0.05, 0, 0.45, 0)
StartButton.Text = '启航'
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 24
StartButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
StartButton.Parent = ScreenGui

-- 止航按钮
local StopButton = Instance.new('TextButton')
StopButton.Name = 'StopButton'
StopButton.Size = UDim2.new(0.2, 0, 0.1, 0)
StopButton.Position = UDim2.new(0.05, 0, 0.45, 0)  -- 原启航按钮Y轴位置调整为0.35
StopButton.Text = '止航'
StopButton.Font = Enum.Font.SourceSansBold
StopButton.TextSize = 24
StopButton.BackgroundColor3 = Color3.fromRGB(215, 0, 0)
StopButton.Visible = false  -- 初始隐藏止航按钮
StopButton.Parent = ScreenGui

-- 点击事件处理：向服务端发送船只组装请求
StartButton.MouseButton1Click:Connect(function()
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..Players.LocalPlayer.UserId)
    if boat then
        boat:Destroy()
    end

    BoatAssemblingService:AssembleBoat():andThen(function(tip)
        print(tip)
        local inventoryUI = Players.LocalPlayer:WaitForChild('PlayerGui'):FindFirstChild('InventoryUI')
        if inventoryUI then
            local inventoryFrame = inventoryUI:FindFirstChild('InventoryFrame')
            if inventoryFrame then
                inventoryFrame.Visible = false
            end
        end
    end)
end)

-- 止航按钮点击事件
StopButton.MouseButton1Click:Connect(function()
    --stopEventBE:Fire()
    BoatAssemblingService:StopBoat():andThen(function(tip)
        print(tip)
        local inventoryUI = Players.LocalPlayer:WaitForChild('PlayerGui'):FindFirstChild('InventoryUI')
        if inventoryUI then
            local inventoryFrame = inventoryUI:FindFirstChild('InventoryFrame')
            if inventoryFrame then
                inventoryFrame.Visible = true
            end
        end
    end)
end)

BoatAssemblingService.UpdateMainUI:Connect(function(data)
    StartButton.Visible = not data.explore
    StopButton.Visible = data.explore
end)

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

-- 宝箱选择弹窗
local LootPopup = Instance.new('Frame')
LootPopup.Name = 'LootPopup'
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

-- 宝箱按钮点击处理
for _, boxButton in ipairs(LootPopup:GetChildren()) do
    if boxButton:IsA('TextButton') then
        boxButton.MouseButton1Click:Connect(function()
            local price = tonumber(string.match(boxButton.Text, '%d+'))
            local LootService = Knit.GetService('LootService')
            LootService:Loot(price):andThen(function(tip)
                print(tip)
                LootPopup.Visible = false
            end)
        end)
    end
end

-- 抽奖按钮
local LootButton = Instance.new('TextButton')
LootButton.Name = 'LootButton'
LootButton.Size = UDim2.new(0.2, 0, 0.1, 0)
LootButton.Position = UDim2.new(0.75, 0, 0.45, 0) -- 右侧5%位置
LootButton.Text = '抽奖'
LootButton.Font = Enum.Font.SourceSansBold
LootButton.TextSize = 24
LootButton.BackgroundColor3 = Color3.fromRGB(215, 120, 0)
LootButton.Parent = ScreenGui

-- 抽奖按钮点击事件
LootButton.MouseButton1Click:Connect(function()
    LootPopup.Visible = true
end)

local function RefreshUI()
    -- 刷新UI元素
    StartButton.Visible = true
    StopButton.Visible = false
    LootButton.Visible = true
    LootPopup.Visible = false

    PlayerDataService:GetAttribute('Gold'):andThen(function(gold)
        GoldLabel.Text = "黄金: "..gold
    end)
end

-- 处理初始角色
if Players.LocalPlayer.Character then
    RefreshUI()
else
    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        PlayerDataService.Client:GoodChanged():Connect(function(gold)
            GoldLabel.Text = "黄金: "..gold
        end)
        RefreshUI()
    end)
end