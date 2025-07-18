-- 赠送界面
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')

local _playerUserId = 0

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'GiftUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateSmallFrame(_screenGui, LanguageConfig.Get(10027), function()
    _playerUserId = 0
    Knit.GetController('UIController').GiftUIClose:Fire()
end)

-- 物品选择列表
local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Size = UDim2.new(1, -20, 1, -20)
_scrollFrame.Position = UDim2.new(0, 10, 0, 10)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.Parent = _frame

-- 确认按钮
local _confirmButton = UIConfig.CreateConfirmButton(_frame, function()
    _screenGui.Enabled = false
    if _playerUserId == 0 then
        return
    end
    Knit.GetController('UIController').GiftUIClose:Fire()

    local chooseItems = {}
    for _, v in pairs(_scrollFrame:GetChildren()) do
        if v:IsA('ImageButton') then
            local checkBox = v:FindFirstChild('CheckBox')
            if checkBox and checkBox.Image == "rbxassetid://6026568195" then
                local modelName = checkBox:GetAttribute("ModelName")
                local num = checkBox:GetAttribute("ItemNum")
                table.insert(chooseItems, {itemName = v:FindFirstChild("NameText").Text, itemNum = num, modelName = modelName})
            end
        end
    end

    if #chooseItems > 0 then
        Knit.GetService("GiftService"):RequestSendGift(_playerUserId, chooseItems):andThen(function(tipId)
            Knit.GetController('UIController').ShowTip:Fire(tipId)
        end):catch(warn)
    end
end)
_confirmButton.Position = UDim2.new(0.5, 0, 0.85, 0)

-- 网格布局
local _gridLayout = Instance.new("UIGridLayout")
_gridLayout.CellSize = UDim2.new(0.22, 0, 0.22, 0)
_gridLayout.CellPadding = UDim2.new(0.03, 0, 0.03, 0)
_gridLayout.FillDirectionMaxCells = 4
_gridLayout.Parent = _scrollFrame

-- 创建物品模板
local _itemTemplate = Instance.new("ImageButton")
_itemTemplate.Name = "ItemTemplate"
_itemTemplate.Size = UDim2.new(0.22, 0, 0.22, 0)
_itemTemplate.BackgroundColor3 = Color3.fromRGB(255, 251, 251)
_itemTemplate.BackgroundTransparency = 0.7
_itemTemplate.Visible = false
UIConfig.CreateCorner(_itemTemplate, UDim.new(0, 8))

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
_nameText.TextScaled = true
_nameText.TextXAlignment = Enum.TextXAlignment.Center
_nameText.BackgroundTransparency = 1
_nameText.Parent = _itemTemplate
UIConfig.CreateCorner(_nameText, UDim.new(0, 8))

local _hpText = Instance.new("TextLabel")
_hpText.Name = "HpText"
_hpText.Text = "HP: 0"
_hpText.Size = UDim2.new(0.9, 0, 0.2, 0)
_hpText.Position = UDim2.new(0.05, 0, 0.35, 0)
_hpText.TextColor3 = Color3.new(0.5, 1, 0.2)
_hpText.TextXAlignment = Enum.TextXAlignment.Left
_hpText.TextScaled = true
_hpText.Parent = _itemTemplate
UIConfig.CreateCorner(_hpText, UDim.new(0, 8))

local _speedText = Instance.new("TextLabel")
_speedText.Name = "SpeedText"
_speedText.Text = "SPEED: 0"
_speedText.Size = UDim2.new(0.9, 0, 0.2, 0)
_speedText.Position = UDim2.new(0.05, 0, 0.6, 0)
_speedText.TextColor3 = Color3.new(0.2, 0.6, 1)
_speedText.TextXAlignment = Enum.TextXAlignment.Left
_speedText.TextScaled = true
_speedText.Parent = _itemTemplate
UIConfig.CreateCorner(_speedText, UDim.new(0, 8))

-- 物品数量
local _countText = Instance.new("TextLabel")
_countText.Name = "CountText"
_countText.Text = "X0"
_countText.Size = UDim2.new(0.3, 0, 0.2, 0)
_countText.Position = UDim2.new(0.7, 0, 0.8, 0)
_countText.TextColor3 = Color3.new(1, 1, 1)
_countText.Font = UIConfig.Font
_countText.TextScaled = true
_countText.BackgroundTransparency = 1
_countText.Parent = _itemTemplate

local function UpdateGiftUI(userId)
    _screenGui.Enabled = true
    _playerUserId = userId
    -- 清空现有物品槽（保留模板）
    for _, child in ipairs(_scrollFrame:GetChildren()) do
        if child:IsA('ImageButton') and child ~= _itemTemplate then
            child:Destroy()
        end
    end
    
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
    
        local checkBox = newItem:FindFirstChild("CheckBox")
        checkBox:SetAttribute("ModelName", itemData.modelName)
        -- 点击切换选中状态
        newItem.MouseButton1Click:Connect(function()
            local isChecked = checkBox.Image == "rbxassetid://3570695787"
            checkBox.Image = isChecked and "rbxassetid://6026568195" or "rbxassetid://3570695787"
            newItem.BackgroundColor3 = isChecked and Color3.fromRGB(200, 230, 255) or Color3.fromRGB(255, 251, 251)
            if isChecked then
                if itemData.num == 1 then
                    checkBox:SetAttribute("ItemNum", 1)
                else
                    Knit.GetController('UIController').ShowChooseNumUI:Fire(itemData.num, function(num)
                        checkBox:SetAttribute("ItemNum", num)
                    end)
                end
            else
                checkBox:SetAttribute("ItemNum", 0)
            end
        end)
    end
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowGiftUI:Connect(function(userId)
        UpdateGiftUI(userId)
    end)
end):catch(warn)