-- 船只购买UI界面
-- 显示可购买的船只商品并处理购买逻辑

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local PurchaseConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("PurchaseConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 创建主界面
local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'PurchaseUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = playerGui

UIConfig.CreateBlock(_screenGui)
local _frame = UIConfig.CreateMiddleFrame(_screenGui, LanguageConfig.Get(10092))

-- 船只列表滚动框
local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Name = 'ScrollFrame'
_scrollFrame.Size = UDim2.new(1, -40, 1, -20)
_scrollFrame.Position = UDim2.new(0, 20, 0, 10)
_scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
_scrollFrame.BorderSizePixel = 0
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.Parent = _frame

local _scrollCorner = Instance.new('UICorner')
_scrollCorner.CornerRadius = UDim.new(0, 8)
_scrollCorner.Parent = _scrollFrame

-- 网格布局
local _gridLayout = Instance.new('UIGridLayout')
_gridLayout.CellSize = UDim2.new(0.22, 0, 0.6, 0)
_gridLayout.CellPadding = UDim2.new(0.04, 0, 0.03, 0)
_gridLayout.FillDirectionMaxCells = 4
_gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
_gridLayout.Parent = _scrollFrame

-- 监听网格布局变化，自动调整滚动框大小
_gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentSize = _gridLayout.AbsoluteContentSize
    -- 确保画布高度足够显示所有内容，并添加额外空间防止最后一行被截断
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + _gridLayout.CellPadding.Y.Scale * _scrollFrame.AbsoluteSize.Y + 20)
end)

-- 创建船只商品卡片
-- @param boatData table 船只数据
-- @param index number 索引
local function createBoatCard(boatData, index)
    local _card = Instance.new('Frame')
    _card.Name = 'Card_' .. boatData.id
    _card.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    _card.BorderSizePixel = 0
    _card.Parent = _scrollFrame
    
    local _cardCorner = Instance.new('UICorner')
    _cardCorner.CornerRadius = UDim.new(0, 8)
    _cardCorner.Parent = _card
    
    -- 船只名称
    local _nameLabel = Instance.new('TextLabel')
    _nameLabel.Name = 'NameLabel'
    _nameLabel.Size = UDim2.new(1, -20, 0, 25)
    _nameLabel.Position = UDim2.new(0.5, 0, 0, 20)
    _nameLabel.BackgroundTransparency = 1
    _nameLabel.Text = boatData.name
    _nameLabel.Font = UIConfig.Font
    _nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    _nameLabel.TextScaled = true
    _nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    _nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    _nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    _nameLabel.Parent = _card
    
    -- 价格标签
    local _priceLabel = Instance.new('TextLabel')
    _priceLabel.Name = 'PriceLabel'
    _priceLabel.Size = UDim2.new(1, -20, 0, 20)
    _priceLabel.Position = UDim2.new(0.5, 0, 0, 110)
    _priceLabel.BackgroundTransparency = 1
    _priceLabel.Text = boatData.price .. " Robux"
    _priceLabel.Font = UIConfig.Font
    _priceLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    _priceLabel.TextScaled = true
    _priceLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
    _priceLabel.TextXAlignment = Enum.TextXAlignment.Center
    _priceLabel.Parent = _card
    
    -- 购买按钮
    local _buyButton = Instance.new('TextButton')
    _buyButton.Name = 'BuyButton'
    _buyButton.Size = UDim2.new(1, -20, 0, 35)
    _buyButton.Position = UDim2.new(0, 10, 1, -45)
    _buyButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    _buyButton.BorderSizePixel = 0
    _buyButton.Text = LanguageConfig.Get(10093)
    _buyButton.Font = UIConfig.Font
    _buyButton.TextScaled = true
    _buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    _buyButton.Parent = _card
    
    local _buyCorner = Instance.new('UICorner')
    _buyCorner.CornerRadius = UDim.new(0, 6)
    _buyCorner.Parent = _buyButton
    
    -- 购买按钮点击事件
    _buyButton.MouseButton1Click:Connect(function()
        -- 发起购买
        Knit.GetService("PurchaseService"):PurchaseBoat(boatData.id)
    end)
end

-- 刷新船只列表
local function refreshBoatList()
    -- 清空现有内容
    for _, child in ipairs(_scrollFrame:GetChildren()) do
        if child:IsA('Frame') and child.Name:find('BoatCard_') then
            child:Destroy()
        end
    end
    
    local boats = PurchaseConfig:GetProductsByType(PurchaseConfig.ProductType.BOAT)
    for index, boat in ipairs(boats) do
        createBoatCard(boat, index)
    end
    
    -- 手动触发一次画布大小更新，确保初始加载时画布大小正确
    local contentSize = _gridLayout.AbsoluteContentSize
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + _gridLayout.CellPadding.Y.Scale * _scrollFrame.AbsoluteSize.Y + 20)
end

refreshBoatList()

-- 等待Knit启动
Knit.OnStart():andThen(function()
    -- 连接Knit信号
    Knit.GetController("UIController").ShowPurchaseUI:Connect(function()
        _screenGui.Enabled = true
    end)
    
    -- 监听购买完成事件
    Knit.GetService("PurchaseService").PurchaseCompleted:Connect(function(productConfig)
        -- 显示购买成功提示
        Knit.GetController("UIController").ShowTip:Fire("成功购买船只: " .. productConfig.name)
        -- 刷新列表
        refreshBoatList()
    end)
    
    -- 监听购买失败事件
    Knit.GetService("PurchaseService").PurchaseFailed:Connect(function(productConfig, errorMessage)
        local message = "购买失败"
        if productConfig then
            message = "购买 " .. productConfig.name .. " 失败"
        end
        if errorMessage then
            message = message .. ": " .. errorMessage
        end
        Knit.GetController("UIController").ShowTip:Fire(message)
    end)
    
    print("船只购买UI已初始化")
end)