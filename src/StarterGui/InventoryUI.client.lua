print('InventoryUI.client.lua loaded')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)

local localPlayer = Players.LocalPlayer

-- 创建原生UI元素
local gui = Instance.new("ScreenGui")
gui.Name = "InventoryUI"
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.Size = UDim2.new(0.8, 0, 0.3, 0)
inventoryFrame.Position = UDim2.new(0.1, 0, 0.65, 0)
inventoryFrame.BackgroundTransparency = 0.7
inventoryFrame.Parent = gui

-- 创建物品模板
-- 创建原生物品模板
local itemTemplate = Instance.new("ImageButton")
itemTemplate.Name = "ItemTemplate"
itemTemplate.Size = UDim2.new(0.15, 0, 0.8, 0)
itemTemplate.BackgroundTransparency = 0.5
itemTemplate.Visible = false

local countText = Instance.new("TextLabel")
countText.Name = "CountText"
countText.Text = "0"
countText.Size = UDim2.new(0.3,0,0.3,0)
countText.Position = UDim2.new(0.7,0,0.7,0)
countText.TextColor3 = Color3.new(1,1,1)
countText.Parent = itemTemplate

--[[
模块名称：库存界面系统
功能：管理玩家背包UI的显示与交互，包括物品展示
作者：Trea AI
版本：1.2.0
最后修改：2024-05-20
]]

--[[
更新库存UI
@param inventoryData 物品数据表，需包含id/icon/quantity/isSelected字段
数据有效性要求：
1. itemId必须为有效字符串
2. itemData必须为table类型
3. icon字段需指向有效图片地址
4. quantity必须为大于0的整数
]]
local function UpdateInventoryUI(inventoryData)
    -- 有效性检查：确保传入数据为table
    assert(type(inventoryData) == "table", "无效的库存数据格式")

    -- 清空现有物品槽（保留模板）
    for _, child in ipairs(inventoryFrame:GetChildren()) do
        if child:IsA('ImageButton') and child ~= itemTemplate then
            child:Destroy()
        end
    end

    -- 创建UIGridLayout自动排列
    if not inventoryFrame:FindFirstChild('GridLayout') then
        local gridLayout = Instance.new('UIGridLayout')
        gridLayout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
        gridLayout.CellSize = UDim2.new(0.15, 0, 0.8, 0)
        gridLayout.FillDirectionMaxCells = 5
        gridLayout.Parent = inventoryFrame
    end

    -- 遍历物品数据创建新槽位
    for itemId, itemData in pairs(inventoryData) do
        -- 数据校验：确保必需字段存在
        if type(itemData) ~= 'table' or not itemData.icon or not itemData.quantity then
            warn("无效的物品数据:", itemId, itemData)
            continue
        end
        -- 克隆物品模板并初始化
        local newItem = itemTemplate:Clone()
        newItem.Name = 'Item_'..itemId  -- 按物品ID命名实例
        newItem.Image = itemData.icon
        newItem.Visible = true

        -- 数量文本
        local text = newItem:FindFirstChild('CountText') or Instance.new('TextLabel')
        text.Text = tostring(itemData.quantity)
        text.Size = UDim2.new(0.3,0,0.3,0)
        text.Position = UDim2.new(0.7,0,0.7,0)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.new(1,1,1)
        text.Parent = newItem

        newItem.Parent = inventoryFrame
    end
end

Knit:OnStart():andThen(function()
    -- 事件监听：处理库存更新事件（Update/Add/Remove等操作）
    local InventoryService = Knit.GetService('InventoryService')
    InventoryService.UpdateInventory:Connect(function(inventoryData)
        UpdateInventoryUI(inventoryData)
    end)

    local function RefreshUI()
        -- 刷新UI元素
        inventoryFrame.Visible = true
        InventoryService:GetInventory(Players.LocalPlayer):andThen(function(inventoryData)
            UpdateInventoryUI(inventoryData)
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