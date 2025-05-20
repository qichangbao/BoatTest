--[[
模块名称：库存界面系统
功能：管理玩家背包UI的显示与交互，包括物品展示
作者：Trea AI
版本：1.2.0
最后修改：2024-05-20
]]
print('InventoryUI.lua loaded')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))
local localPlayer = Players.LocalPlayer

local _screenGui = Instance.new("ScreenGui")
_screenGui.Name = "InventoryUI_GUI"
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

-- 禁用背景点击
local _blocker = Instance.new('TextButton')
_blocker.Size = UDim2.new(1, 0, 1, 0)
_blocker.BackgroundTransparency = 1
_blocker.Text = ""
_blocker.Parent = _screenGui

-- 新增模态背景
local _modalFrame = Instance.new("Frame")
_modalFrame.Size = UDim2.new(1, 0, 1, 0)
_modalFrame.BackgroundTransparency = 0.5
_modalFrame.BackgroundColor3 = Color3.new(0, 0, 0)
_modalFrame.Parent = _screenGui

local _inventoryFrame = Instance.new("Frame")
_inventoryFrame.Name = "InventoryFrame"
_inventoryFrame.Size = UDim2.new(0, 600, 0, 300)
_inventoryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
_inventoryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
_inventoryFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
_inventoryFrame.BackgroundTransparency = 0.3
_inventoryFrame.Parent = _screenGui

-- 标题栏
local _titleBar = Instance.new("Frame")
_titleBar.Name = "TitleBar"
_titleBar.Size = UDim2.new(1, 0, 0.1, 0)
_titleBar.Position = UDim2.new(0.5, 0, 0, 0)
_titleBar.AnchorPoint = Vector2.new(0.5, 1)
_titleBar.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
_titleBar.Parent = _inventoryFrame

local _titleText = Instance.new("TextLabel")
_titleText.Name = "TitleText"
_titleText.Size = UDim2.new(0.3, 0, 1, 0)
_titleText.Position = UDim2.new(0.5, 0, 0, 0)
_titleText.AnchorPoint = Vector2.new(0.5, 0)
_titleText.Text = "背包物品"
_titleText.Font = UIConfig.Font
_titleText.TextSize = 20
_titleText.TextColor3 = Color3.new(1, 1, 1)
_titleText.BackgroundTransparency = 1
_titleText.TextXAlignment = Enum.TextXAlignment.Center
_titleText.Parent = _titleBar

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(function()
    _screenGui.Enabled = false
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0.5, 0)
_closeButton.Parent = _titleBar

-- 物品滚动区域
local _scrollFrame = Instance.new("ScrollingFrame")
_scrollFrame.Name = "ScrollFrame"
_scrollFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
_scrollFrame.Position = UDim2.new(0.025, 0, 0.025, 0)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.Parent = _inventoryFrame

-- 网格布局
local _gridLayout = Instance.new("UIGridLayout")
_gridLayout.CellSize = UDim2.new(0.176, 0, 0.176, 0)
_gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
_gridLayout.FillDirectionMaxCells = 5
_gridLayout.Parent = _scrollFrame

-- 创建物品模板
local _itemTemplate = Instance.new("ImageButton")
_itemTemplate.Name = "ItemTemplate"
_itemTemplate.Size = UDim2.new(0.176, 0, 0.176, 0)
_itemTemplate.BackgroundColor3 = Color3.fromRGB(255, 251, 251)
_itemTemplate.BackgroundTransparency = 0.7
_itemTemplate.Visible = false

-- 物品名称
local _nameText = Instance.new("TextLabel")
_nameText.Name = "NameText"
_nameText.Text = "ItemName"
_nameText.Size = UDim2.new(0.9, 0, 0.2, 0)
_nameText.Position = UDim2.new(0.05, 0, 0.05, 0)
_nameText.TextColor3 = Color3.new(1, 1, 1)
_nameText.Font = UIConfig.Font
_nameText.TextSize = 14
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
_hpText.TextSize = 12
_hpText.Parent = _itemTemplate

local _speedText = Instance.new("TextLabel")
_speedText.Name = "SpeedText"
_speedText.Text = "SPEED: 0"
_speedText.Size = UDim2.new(0.9, 0, 0.2, 0)
_speedText.Position = UDim2.new(0.05, 0, 0.6, 0)
_speedText.TextColor3 = Color3.new(0.2, 0.6, 1)
_speedText.TextXAlignment = Enum.TextXAlignment.Left
_speedText.TextSize = 12
_speedText.Parent = _itemTemplate

-- 物品数量
local _countText = Instance.new("TextLabel")
_countText.Name = "CountText"
_countText.Text = "X0"
_countText.Size = UDim2.new(0.3, 0, 0.2, 0)
_countText.Position = UDim2.new(0.7, 0, 0.8, 0)
_countText.TextColor3 = Color3.new(1, 1, 1)
_countText.Font = UIConfig.Font
_countText.TextSize = 16
_countText.BackgroundTransparency = 1
_countText.Parent = _itemTemplate

--[[
更新库存UI
@param inventoryData 物品数据表，需包含id/icon/num/isSelected字段
数据有效性要求：
1. itemId必须为有效字符串
2. itemData必须为table类型
3. icon字段需指向有效图片地址
4. quantity必须为大于0的整数
]]
local function UpdateInventoryUI()
    local isShowAddButton = false
    local boat = game.Workspace:FindFirstChild('PlayerBoat_'..localPlayer.UserId)
    if boat then
        local modelName = boat:GetAttribute('ModelName')
        for _, itemData in pairs(ClientData.InventoryItems) do
            if itemData.modelName == modelName and itemData.isUsed == 0 then
                isShowAddButton = true
                break
            end
        end
    end

    Knit.GetController('UIController').ShowAddBoatPartButton:Fire(isShowAddButton)

    -- 清空现有物品槽（保留模板）
    for _, child in ipairs(_scrollFrame:GetChildren()) do
        if child:IsA('ImageButton') and child ~= _itemTemplate then
            child:Destroy()
        end
    end

    local yOffset = 0
    -- 遍历物品数据创建新槽位
    for itemId, itemData in pairs(ClientData.InventoryItems) do
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

        yOffset += _itemTemplate.Size.Y.Offset
    end

    --_inventoryFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset) -- 可滚动区域高度
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowInventoryUI:Connect(function()
        _screenGui.Enabled = true
    end)
    Knit.GetController('UIController').UpdateInventoryUI:Connect(function()
        UpdateInventoryUI()
    end)
end):catch(warn)
