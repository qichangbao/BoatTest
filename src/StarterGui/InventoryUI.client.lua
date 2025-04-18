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
local localPlayer = Players.LocalPlayer

local _inventoryItems = {}
-- 创建原生UI元素
local _gui = Instance.new("ScreenGui")
_gui.Name = "InventoryUI"
_gui.Parent = localPlayer:WaitForChild("PlayerGui")

local _inventoryFrame = Instance.new("Frame")
_inventoryFrame.Name = "InventoryFrame"
_inventoryFrame.Size = UDim2.new(0.8, 0, 0.3, 0)
_inventoryFrame.Position = UDim2.new(0.1, 0, 0.65, 0)
_inventoryFrame.BackgroundTransparency = 0.7
_inventoryFrame.Parent = _gui

-- 创建物品模板
-- 创建原生物品模板
local _itemTemplate = Instance.new("ImageButton")
_itemTemplate.Name = "ItemTemplate"
_itemTemplate.Size = UDim2.new(0.15, 0, 0.8, 0)
_itemTemplate.BackgroundTransparency = 0.5
_itemTemplate.Visible = false

local _countText = Instance.new("TextLabel")
_countText.Name = "CountText"
_countText.Text = "0"
_countText.Size = UDim2.new(0.3,0,0.3,0)
_countText.Position = UDim2.new(0.7,0,0.7,0)
_countText.TextColor3 = Color3.new(1,1,1)
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
        for _, itemData in pairs(_inventoryItems) do
            if itemData.modelName == modelName and not itemData.isUsed then
                isShowAddButton = true
                break
            end
        end
    end

    Knit.GetController('UIController').ShowAddBoatPartButton:Fire(isShowAddButton)

    -- 清空现有物品槽（保留模板）
    for _, child in ipairs(_inventoryFrame:GetChildren()) do
        if child:IsA('ImageButton') and child ~= _itemTemplate then
            child:Destroy()
        end
    end

    -- 创建UIGridLayout自动排列
    if not _inventoryFrame:FindFirstChild('GridLayout') then
        local gridLayout = Instance.new('UIGridLayout')
        gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
        gridLayout.CellSize = UDim2.new(0.15, 0, 0.8, 0)
        gridLayout.FillDirectionMaxCells = 5
        gridLayout.Parent = _inventoryFrame
    end

    -- 遍历物品数据创建新槽位
    for itemId, itemData in pairs(_inventoryItems) do
        -- 数据校验：确保必需字段存在
        if type(itemData) ~= 'table' or not itemData.icon or not itemData.num then
            warn("无效的物品数据:", itemId, itemData)
            continue
        end
        -- 克隆物品模板并初始化
        local newItem = _itemTemplate:Clone()
        newItem.Name = 'Item_'..itemId  -- 按物品ID命名实例
        newItem.Image = itemData.icon
        newItem.Visible = true

        -- 数量文本
        local text = newItem:FindFirstChild('CountText') or Instance.new('TextLabel')
        text.Text = tostring(itemData.num)
        text.Size = UDim2.new(0.3,0,0.3,0)
        text.Position = UDim2.new(0.7,0,0.7,0)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.new(1,1,1)
        text.Parent = newItem

        newItem.Parent = _inventoryFrame
    end
end

local function AddItemToInventory(itemData)
    local isExist = false
    for _, item in pairs(_inventoryItems) do
        if item.itemName == itemData.itemName and item.modelName == itemData.modelName then
            item.num = itemData.num
            isExist = true
            break
        end
    end

    if not isExist then
        table.insert(_inventoryItems, itemData)
    end
    UpdateInventoryUI()
end

local function RemoveItemToInventory(itemData)
    local isExist = false
    for index, item in pairs(_inventoryItems) do
        if item.itemName == itemData.itemName and item.modelName == itemData.modelName then
            table.remove(_inventoryItems, index)
            isExist = true
            break
        end
    end

    if isExist then
        UpdateInventoryUI()
    end
end

Knit:OnStart():andThen(function()
    -- 事件监听：处理库存更新事件（Update/Add/Remove等操作）
    local InventoryService = Knit.GetService('InventoryService')
    InventoryService.AddItem:Connect(function(itemData)
        Knit.GetController('TipController').Tip:Fire('恭喜您获得了: '.. itemData.itemName)
        AddItemToInventory(itemData)
    end)
    InventoryService.RemoveItem:Connect(function(itemData)
        Knit.GetController('TipController').Tip:Fire('您失去了: '.. itemData.itemName)
        RemoveItemToInventory(itemData)
    end)

    Knit.GetService('BoatAssemblingService').UpdateInventory:Connect(function(modelName)
        for _, item in pairs(_inventoryItems) do
            if item.modelName == modelName then
                item.isUsed = true
            end
        end
        UpdateInventoryUI()
    end)

    local function RefreshUI()
        -- 刷新UI元素
        _inventoryFrame.Visible = true
        InventoryService:GetInventory(Players.LocalPlayer):andThen(function(inventoryData)
            _inventoryItems = inventoryData
            UpdateInventoryUI()
        end)
    end
    
    -- 处理初始角色
    if Players.LocalPlayer.Character then
        RefreshUI()
    else
        Players.LocalPlayer.CharacterAdded:Connect(function(character)
            RefreshUI()
        end)
    end
end):catch(warn)