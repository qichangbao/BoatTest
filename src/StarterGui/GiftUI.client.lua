-- 新增赠送界面
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local ShareData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ShareData"))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'GiftUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

-- 主界面框架
local _frame = Instance.new('Frame')
_frame.Size = UDim2.new(0.35, 0, 0.45, 0)
_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_frame.AnchorPoint = Vector2.new(0.5, 0.5)
_frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
_frame.BackgroundTransparency = 0.1
_frame.Parent = _screenGui

-- 标题栏
local _titleBar = Instance.new('Frame')
_titleBar.Size = UDim2.new(1, 0, 0.1, 0)
_titleBar.Position = UDim2.new(0, 0, 0, 0)
_titleBar.BackgroundColor3 = Color3.fromRGB(103, 80, 164)
_titleBar.Parent = _frame

local _titleLabel = Instance.new('TextLabel')
_titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
_titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
_titleLabel.Text = LanguageConfig:Get(10027)
_titleLabel.Font = UIConfig.Font
_titleLabel.TextSize = 20
_titleLabel.TextColor3 = Color3.new(1, 1, 1)
_titleLabel.BackgroundTransparency = 1
_titleLabel.Parent = _titleBar

-- 关闭按钮
local _closeButton = Instance.new('TextButton')
_closeButton.Name = 'CloseButton'
_closeButton.Size = UDim2.new(0.1, 0, 1, 0)
_closeButton.Position = UDim2.new(0.9, 0, 0, 0)
_closeButton.Text = 'X'
_closeButton.Font = UIConfig.Font
_closeButton.TextSize = 24
_closeButton.TextColor3 = Color3.new(1, 1, 1)
_closeButton.BackgroundTransparency = 1
_closeButton.Parent = _titleBar
_closeButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
    Knit.GetController('UIController').GiftUIClose:Fire()
end)

-- 功能按钮
local _confirmButton = Instance.new('TextButton')
_confirmButton.Text = LanguageConfig:Get(10002)
_confirmButton.Size = UDim2.new(0.25, 0, 0.1, 0)
_confirmButton.Position = UDim2.new(0.7, 0, 0.85, 0)
_confirmButton.Font = UIConfig.Font
_confirmButton.TextSize = 18
_confirmButton.TextColor3 = Color3.new(1, 1, 1)
_confirmButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
_confirmButton.Parent = _frame
_confirmButton.MouseButton1Click:Connect(function()
    _screenGui.Enabled = false
    Knit.GetController('UIController').GiftUIClose:Fire()
end)

-- 物品选择列表
local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
_scrollFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.Parent = _frame

-- 网格布局
local _gridLayout = Instance.new("UIGridLayout")
_gridLayout.CellSize = UDim2.new(0.2, 0, 0.2, 0)
_gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
_gridLayout.FillDirectionMaxCells = 4
_gridLayout.Parent = _scrollFrame

-- 创建物品模板
local _itemTemplate = Instance.new("ImageButton")
_itemTemplate.Name = "ItemTemplate"
_itemTemplate.Size = UDim2.new(0.2, 0, 0.2, 0)
_itemTemplate.BackgroundColor3 = Color3.fromRGB(255, 251, 251)
_itemTemplate.BackgroundTransparency = 0.7
_itemTemplate.Visible = false

-- 添加勾选框
local _checkBox = Instance.new("ImageLabel")
_checkBox.Name = "CheckBox"
_checkBox.Size = UDim2.new(0.2, 0, 0.2, 0)
_checkBox.Position = UDim2.new(0.8, 0, 0, 0)
_checkBox.BackgroundTransparency = 1
_checkBox.Image = "rbxassetid://3570695787" -- 默认未选中图标
_checkBox.Parent = _itemTemplate

-- 物品名称
local _nameText = Instance.new("TextLabel")
_nameText.Name = "NameText"
_nameText.Text = "物品名称"
_nameText.Size = UDim2.new(0.9, 0, 0.2, 0)
_nameText.Position = UDim2.new(0.05, 0, 0.05, 0)
_nameText.TextColor3 = Color3.new(1, 1, 1)
_nameText.Font = UIConfig.Font
_nameText.TextSize = 12
_nameText.TextXAlignment = Enum.TextXAlignment.Center
_nameText.BackgroundTransparency = 1
_nameText.Parent = _itemTemplate

local _hpText = Instance.new("TextLabel")
_hpText.Name = "HpText"
_hpText.Text = "HP: 0"
_hpText.Size = UDim2.new(0.9, 0, 0.2, 0)
_hpText.Position = UDim2.new(0.05, 0, 0.35, 0)
_hpText.TextColor3 = Color3.new(0.5, 1, 0.2)
_hpText.TextXAlignment = Enum.TextXAlignment.Left
_hpText.TextSize = 10
_hpText.Parent = _itemTemplate

local _speedText = Instance.new("TextLabel")
_speedText.Name = "SpeedText"
_speedText.Text = "SPEED: 0"
_speedText.Size = UDim2.new(0.9, 0, 0.2, 0)
_speedText.Position = UDim2.new(0.05, 0, 0.6, 0)
_speedText.TextColor3 = Color3.new(0.2, 0.6, 1)
_speedText.TextXAlignment = Enum.TextXAlignment.Left
_speedText.TextSize = 10
_speedText.Parent = _itemTemplate

-- 物品数量
local _countText = Instance.new("TextLabel")
_countText.Name = "CountText"
_countText.Text = "X0"
_countText.Size = UDim2.new(0.3, 0, 0.2, 0)
_countText.Position = UDim2.new(0.7, 0, 0.8, 0)
_countText.TextColor3 = Color3.new(1, 1, 1)
_countText.Font = UIConfig.Font
_countText.TextSize = 14
_countText.BackgroundTransparency = 1
_countText.Parent = _itemTemplate

local function UpdateGiftUI()
    _screenGui.Enabled = true
    for itemId, itemData in pairs(ShareData.InventoryItems) do
        -- 数据校验：确保必需字段存在
        if type(itemData) ~= 'table' or not itemData.num then
            warn("无效的物品数据:", itemId, itemData)
            continue
        end

        local model = BoatConfig.GetBoatConfig(itemData.modelName)
        if not model or not model[itemData.itemName] then
            continue
        end

        -- 克隆物品模板并初始化
        local newItem = _itemTemplate:Clone()
        newItem.Name = 'Item_'..itemId  -- 按物品ID命名实例

        local partConfig = model[itemData.itemName]
        -- 初始化物品信息
        newItem:FindFirstChild("NameText").Text = itemData.itemName
        newItem:FindFirstChild("HpText").Text = "HP: " .. partConfig.HP
        newItem:FindFirstChild("SpeedText").Text = "Speed: " .. partConfig.speed
        newItem:FindFirstChild('CountText').Text = "X" .. tostring(itemData.num)
        newItem.Visible = true
        newItem.Parent = _scrollFrame
    
        local checkBox = newItem:FindFirstChild("CheckBox")
        -- 点击切换选中状态
        newItem.MouseButton1Click:Connect(function()
            local isChecked = checkBox.Image == "rbxassetid://3570695787"
            checkBox.Image = isChecked and "rbxassetid://6026568195" or "rbxassetid://3570695787"
            newItem.BackgroundColor3 = isChecked and Color3.fromRGB(200, 230, 255) or Color3.fromRGB(255, 251, 251)
        end)
    end
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').ShowGiftUI:Connect(function()
        UpdateGiftUI()
    end)
end):catch(warn)