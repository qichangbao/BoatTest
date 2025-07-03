--[[
模块名称：库存界面系统
功能：管理玩家背包UI的显示与交互，包括物品展示
作者：Trea AI
版本：1.2.0
最后修改：2024-05-20
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))
local localPlayer = Players.LocalPlayer

local _screenGui = Instance.new("ScreenGui")
_screenGui.Name = "InventoryUI_GUI"
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateBigFrame(_screenGui, LanguageConfig.Get(10025))

-- 物品滚动区域
local _scrollFrame = Instance.new("ScrollingFrame")
_scrollFrame.Size = UDim2.new(1, -20, 1, -20) -- 调整高度，考虑标题栏占用的空间
_scrollFrame.Position = UDim2.new(0, 10, 0, 10) -- 调整位置，避开标题栏
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- 初始化画布大小，将在更新UI时动态调整
_scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- 启用自动画布大小调整
_scrollFrame.Parent = _frame

-- 添加内边距容器，确保边框完全显示
local _paddingFrame = Instance.new("UIPadding")
_paddingFrame.PaddingLeft = UDim.new(0, 5) -- 左侧内边距
_paddingFrame.PaddingRight = UDim.new(0, 5) -- 右侧内边距
_paddingFrame.PaddingTop = UDim.new(0, 5) -- 顶部内边距
_paddingFrame.PaddingBottom = UDim.new(0, 5) -- 底部内边距
_paddingFrame.Parent = _scrollFrame

-- 网格布局
local _gridLayout = Instance.new("UIGridLayout")
_gridLayout.CellSize = UDim2.new(0.18, 0, 0.3, 0)
_gridLayout.CellPadding = UDim2.new(0.025, 0, 0.04, 0)
_gridLayout.FillDirectionMaxCells = 5
_gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
_gridLayout.Parent = _scrollFrame

-- 监听网格布局变化，自动调整滚动框大小
_gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentSize = _gridLayout.AbsoluteContentSize
    -- 确保画布高度足够显示所有内容，并添加额外空间防止最后一行被截断
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + _gridLayout.CellPadding.Y.Scale * _scrollFrame.AbsoluteSize.Y + 20)
end)

-- 创建物品模板
local _itemTemplate = Instance.new("ImageButton")
_itemTemplate.Name = "ItemTemplate"
_itemTemplate.Size = UDim2.new(0.18, 0, 0.3, 0)
_itemTemplate.BackgroundColor3 = Color3.fromRGB(45, 49, 66) -- 深蓝灰色背景
_itemTemplate.BackgroundTransparency = 0.2 -- 降低透明度使其更明显
_itemTemplate.BorderSizePixel = 0 -- 移除默认边框
_itemTemplate.Visible = false
UIConfig.CreateCorner(_itemTemplate, UDim.new(0, 12)) -- 增大圆角

-- 添加边框效果
local _stroke = Instance.new("UIStroke")
_stroke.Color = Color3.fromRGB(86, 92, 120) -- 浅蓝灰色边框
_stroke.Thickness = 2
_stroke.Parent = _itemTemplate

-- 物品名称背景
local _nameBg = Instance.new("Frame")
_nameBg.Name = "NameBackground"
_nameBg.Size = UDim2.new(1, 0, 0.3, 0)
_nameBg.Position = UDim2.new(0, 0, 0, 0)
_nameBg.BackgroundColor3 = Color3.fromRGB(59, 63, 83) -- 稍微亮一点的背景
_nameBg.BackgroundTransparency = 0.2
_nameBg.BorderSizePixel = 0
_nameBg.Parent = _itemTemplate

-- 只给顶部圆角
local _nameCorner = Instance.new("UICorner")
_nameCorner.CornerRadius = UDim.new(0, 12)
_nameCorner.Parent = _nameBg

-- 物品名称
local _nameText = Instance.new("TextLabel")
_nameText.Name = "NameText"
_nameText.Text = "ItemName"
_nameText.Size = UDim2.new(1, -10, 1, 0)
_nameText.Position = UDim2.new(0, 5, 0, 0)
_nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
_nameText.Font = UIConfig.Font -- 使用粗体字体
_nameText.TextScaled = true
_nameText.TextXAlignment = Enum.TextXAlignment.Center
_nameText.BackgroundTransparency = 1
_nameText.TextTruncate = Enum.TextTruncate.AtEnd -- 文本过长时显示省略号
_nameText.Parent = _nameBg

-- 属性容器
local _statsContainer = Instance.new("Frame")
_statsContainer.Name = "StatsContainer"
_statsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
_statsContainer.Size = UDim2.new(1, -20, 0.4, 0)
_statsContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
_statsContainer.BackgroundTransparency = 1
_statsContainer.Parent = _itemTemplate

-- HP属性图标
local _hpIcon = Instance.new("Frame")
_hpIcon.Name = "HpIcon"
_hpIcon.AnchorPoint = Vector2.new(0, 0.5)
_hpIcon.Size = UDim2.new(0, 16, 0, 16)
_hpIcon.Position = UDim2.new(0, 0, 0.2, 0)
_hpIcon.BackgroundColor3 = Color3.fromRGB(76, 209, 55) -- 绿色
_hpIcon.BorderSizePixel = 0
_hpIcon.Parent = _statsContainer
UIConfig.CreateCorner(_hpIcon, UDim.new(0, 4))

-- HP属性文本
local _hpText = Instance.new("TextLabel")
_hpText.Name = "HpText"
_hpText.AnchorPoint = Vector2.new(0, 0.5)
_hpText.Text = "HP: 0"
_hpText.Size = UDim2.new(1, -25, 0, 20)
_hpText.Position = UDim2.new(0, 25, 0.2, 0)
_hpText.TextColor3 = Color3.fromRGB(76, 209, 55) -- 绿色
_hpText.Font = UIConfig.Font
_hpText.TextXAlignment = Enum.TextXAlignment.Left
_hpText.TextScaled = true
_hpText.BackgroundTransparency = 1
_hpText.Parent = _statsContainer

-- 分隔线
local _divider = Instance.new("Frame")
_divider.Name = "Divider"
_divider.Size = UDim2.new(1, 0, 0, 1)
_divider.Position = UDim2.new(0, 0, 0.5, 0)
_divider.BackgroundColor3 = Color3.fromRGB(86, 92, 120) -- 浅蓝灰色
_divider.BackgroundTransparency = 0.7
_divider.BorderSizePixel = 0
_divider.Parent = _statsContainer

-- Speed属性图标
local _speedIcon = Instance.new("Frame")
_speedIcon.Name = "SpeedIcon"
_speedIcon.AnchorPoint = Vector2.new(0, 0.5)
_speedIcon.Size = UDim2.new(0, 16, 0, 16)
_speedIcon.Position = UDim2.new(0, 0, 0.8, 0)
_speedIcon.BackgroundColor3 = Color3.fromRGB(41, 171, 226) -- 蓝色
_speedIcon.BorderSizePixel = 0
_speedIcon.Parent = _statsContainer
UIConfig.CreateCorner(_speedIcon, UDim.new(0, 4))

-- Speed属性文本
local _speedText = Instance.new("TextLabel")
_speedText.Name = "SpeedText"
_speedText.AnchorPoint = Vector2.new(0, 0.5)
_speedText.Text = "SPEED: 0"
_speedText.Size = UDim2.new(1, -25, 0, 20)
_speedText.Position = UDim2.new(0, 25, 0.8, 0)
_speedText.TextColor3 = Color3.fromRGB(41, 171, 226) -- 蓝色
_speedText.Font = UIConfig.Font
_speedText.TextXAlignment = Enum.TextXAlignment.Left
_speedText.TextScaled = true
_speedText.BackgroundTransparency = 1
_speedText.Parent = _statsContainer

-- 物品数量
local _countText = Instance.new("TextLabel")
_countText.Name = "CountText"
_countText.Text = "X0"
_countText.Size = UDim2.new(0, 30, 0, 30)
_countText.Position = UDim2.new(1, -30, 1, -30)
_countText.TextColor3 = Color3.new(1, 1, 1)
_countText.Font = UIConfig.Font
_countText.TextScaled = true
_countText.BackgroundTransparency = 1
_countText.TextXAlignment = Enum.TextXAlignment.Center
_countText.Parent = _itemTemplate

-- 添加悬停效果
local _hoverEffect = Instance.new("UIScale")
_hoverEffect.Scale = 1
_hoverEffect.Parent = _itemTemplate

_itemTemplate.MouseEnter:Connect(function()
    -- 鼠标悬停时放大效果
    game:GetService("TweenService"):Create(_hoverEffect, TweenInfo.new(0.2), {Scale = 1.05}):Play()
    -- 边框颜色变亮
    game:GetService("TweenService"):Create(_stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(120, 130, 160)}):Play()
end)

_itemTemplate.MouseLeave:Connect(function()
    -- 鼠标离开时恢复原状
    game:GetService("TweenService"):Create(_hoverEffect, TweenInfo.new(0.2), {Scale = 1}):Play()
    -- 边框颜色恢复
    game:GetService("TweenService"):Create(_stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(86, 92, 120)}):Play()
end)

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

    -- 遍历物品数据创建新槽位
    local itemCount = 0
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
        newItem.LayoutOrder = itemCount -- 设置布局顺序，确保物品按顺序排列
        itemCount = itemCount + 1

        local partConfig = model[itemData.itemName]
        -- 初始化物品信息
        newItem:FindFirstChild('NameBackground'):FindFirstChild('NameText').Text = itemData.itemName
        newItem:FindFirstChild('StatsContainer'):FindFirstChild('HpText').Text = "HP: " .. partConfig.HP
        newItem:FindFirstChild('StatsContainer'):FindFirstChild('SpeedText').Text = "Speed: " .. partConfig.speed
        -- 更新物品数量 - 现在CountText在CountBackground内部
        newItem:FindFirstChild('CountText').Text = "X" .. tostring(itemData.num)
        newItem.Visible = true
        newItem.Parent = _scrollFrame
    end
    
    -- 手动触发一次画布大小更新，确保初始加载时画布大小正确
    local contentSize = _gridLayout.AbsoluteContentSize
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + _gridLayout.CellPadding.Y.Scale * _scrollFrame.AbsoluteSize.Y + 20)
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
