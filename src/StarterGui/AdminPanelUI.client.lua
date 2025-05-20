local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local PlayerGui = game.Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

local Theme = {
    Primary = Color3.fromRGB(0, 150, 255),
    ClosePrimary = Color3.fromRGB(255, 0, 0),
    Secondary = Color3.fromRGB(0, 200, 200),
    TextPrimary = Color3.fromRGB(0, 4, 255),
    TextBoxPrimary = Color3.fromRGB(0, 0, 0),
    TextBottonPrimary = Color3.fromRGB(255, 255, 255),
    ScrollFrameBG = Color3.fromRGB(60, 60, 60),
    InputFieldBG = Color3.fromRGB(255, 255, 255),
    ButtonHoverAlpha = 0.8,
    DividerColor = Color3.fromRGB(80, 80, 80),
    BackgroundColor = Color3.fromRGB(40, 40, 40)
}

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'AdminPanelUI_GUI'
_screenGui.Enabled = false
_screenGui.IgnoreGuiInset = true
_screenGui.Parent = PlayerGui

-- 禁用背景点击
local _blocker = Instance.new("TextButton")
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

local _frame = Instance.new('Frame')
_frame.Name = 'AdminFrame'
_frame.Size = UDim2.new(0.8, 0, 0.8, 0)
_frame.AnchorPoint = Vector2.new(0.5, 0.45)
_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_frame.BackgroundTransparency = 1
_frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
_frame.Parent = _screenGui

-- 创建顶部控制栏
local _controlFrame = Instance.new('Frame')
_controlFrame.Size = UDim2.new(0.7, 0, 0, 40)
_controlFrame.AnchorPoint = Vector2.new(0.5, 1)
_controlFrame.Position = UDim2.new(0.5, 0, 0, -10)
_controlFrame.BackgroundTransparency = 1
_controlFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
_controlFrame.Parent = _frame

local _closeBtn = UIConfig.CreateCloseButton(function()
    _screenGui.Enabled = false
end)
_closeBtn.Position = UDim2.new(1, 40, 0.5, 0)
_closeBtn.Parent = _controlFrame

-- 调整滚动框架位置和尺寸
local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Size = UDim2.new(1, 0, 1, 0)
_scrollFrame.AnchorPoint = Vector2.new(0.5, 0)
_scrollFrame.Position = UDim2.new(0.5, 0, 0, 0)
_scrollFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
_scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
_scrollFrame.BackgroundColor3 = Theme.ScrollFrameBG
_scrollFrame.BackgroundTransparency = 0.2
_scrollFrame.Parent = _frame

local _userIdBox = Instance.new('TextBox')
_userIdBox.Size = UDim2.new(0.3, 0, 1, 0)
_userIdBox.AnchorPoint = Vector2.new(1, 0.5)
_userIdBox.Position = UDim2.new(0.5, -50, 0.5, 0)
_userIdBox.Text = "输入用户ID"
_userIdBox.PlaceholderText = _userIdBox.Text
_userIdBox.TextColor3 = Theme.TextBoxPrimary
_userIdBox.TextSize = 16
_userIdBox.BackgroundColor3 = Theme.InputFieldBG
_userIdBox.Parent = _controlFrame

local _fetchBtn = Instance.new('TextButton')
_fetchBtn.Size = UDim2.new(0.3, 0, 1, 0)
_fetchBtn.AnchorPoint = Vector2.new(0, 0.5)
_fetchBtn.Position = UDim2.new(0.5, 50, 0.5, 0)
_fetchBtn.Text = "获取数据"
_fetchBtn.TextSize = 16
_fetchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
_fetchBtn.TextSize = 16
_fetchBtn.BackgroundColor3 = Theme.Primary
_fetchBtn.TextColor3 = Theme.TextBottonPrimary
_fetchBtn.Parent = _controlFrame

local function UpdateDataDisplay(parent, userIdInputText, data, depth, parentPath)
    -- 清空现有显示内容
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA('Frame') and (child.Name == 'DataContainerTop' or child.Name == 'DataContainer') then
            child:Destroy()
        end
    end
    depth = depth or 0
    parentPath = parentPath or {}
    
    local container = Instance.new('Frame')
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.LayoutOrder = depth
    if depth == 0 then
        container.Name = 'DataContainerTop'
    else
        container.Name = 'DataContainer'
    end
    
    local layout = Instance.new('UIListLayout')
    layout.Parent = container
    
    local padding = Instance.new('UIPadding')
    padding.PaddingLeft = UDim.new(0, depth * 15)
    padding.Parent = container

    local function FindTopParent(_frame)
        while _frame.Parent ~= nil and _frame.Parent.Name ~= 'DataContainerTop' do
            _frame = _frame.Parent
        end
        return _frame
    end
    
    for key, value in pairs(data) do
        local currentPath = table.clone(parentPath)
        table.insert(currentPath, key)
        local entryFrame = Instance.new('Frame')
        entryFrame.Name = 'EntryFrame'
        entryFrame.BackgroundTransparency = 0
        entryFrame.BackgroundColor3 = Theme.BackgroundColor
        entryFrame.Size = UDim2.new(1, 0, 0, 30)
        entryFrame.AutomaticSize = Enum.AutomaticSize.Y
        entryFrame.ClipsDescendants = true
        entryFrame.Parent = container
        if depth == 0 then
            local jsonString = game:GetService('HttpService'):JSONEncode(value)
            local stringValue = Instance.new("StringValue", entryFrame)
            stringValue.Value = jsonString
            stringValue.Name = 'StringValue'
            stringValue:SetAttribute('Key', key)
        end

        -- 添加底部边框
        local divider = Instance.new('Frame')
        divider.Size = UDim2.new(1, 0, 0, 1)
        divider.Position = UDim2.new(0, 0, 1, -1)
        divider.BorderSizePixel = 0
        divider.BackgroundColor3 = Theme.DividerColor
        divider.Parent = entryFrame
        
        local label = Instance.new('TextLabel')
        label.Size = UDim2.new(0.6, -30, 0, 30)
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.TextColor3 = Theme.TextPrimary
        label.Position = UDim2.new(0, 0, 0, 0)
        label.Text = tostring(key)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = entryFrame
        label.TextSize = 16
        
        if type(value) == 'table' then
            local toggleButton = Instance.new('TextButton')
            toggleButton.Size = UDim2.new(0, 30, 0, 30)
            toggleButton.Position = UDim2.new(0, 0, 0, 0)
            toggleButton.Text = '▶'
            toggleButton.Parent = entryFrame
            
            local subContainer
            toggleButton.MouseButton1Click:Connect(function()
                if not subContainer then
                    subContainer = UpdateDataDisplay(entryFrame, userIdInputText, value, depth + 1, currentPath)
                    subContainer.Position = UDim2.new(0, 0, 0, 30)
                    subContainer.Visible = false
                end
                subContainer.Visible = not subContainer.Visible
                toggleButton.Text = subContainer.Visible and '▼' or '▶'
            end)
            
            local keyLabel = Instance.new('TextLabel')
            keyLabel.Size = UDim2.new(1, -30, 0, 30)
            keyLabel.Position = UDim2.new(0, 30, 0, 0)
            keyLabel.TextColor3 = Theme.TextPrimary
            keyLabel.Text = tostring(key)
            keyLabel.TextXAlignment = Enum.TextXAlignment.Left
            keyLabel.Parent = entryFrame
            keyLabel.TextSize = 16

            -- 添加增加按钮
            local addBtn = Instance.new('TextButton')
            addBtn.Size = UDim2.new(0.1, 0, 0, 30)
            addBtn.AnchorPoint = Vector2.new(1, 0)
            addBtn.Position = UDim2.new(0.9, 0, 0, 0)
            addBtn.Text = "增加"
            addBtn.TextSize = 16
            addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            addBtn.BackgroundColor3 = Theme.Secondary
            addBtn.TextColor3 = Theme.TextBottonPrimary
            addBtn.Parent = entryFrame
            addBtn.MouseButton1Click:Connect(function()
                local popupFrame = Instance.new('Frame')
                popupFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
                popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                popupFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                popupFrame.BackgroundColor3 = Theme.BackgroundColor
                popupFrame.Parent = _screenGui
                
                local keyInput = Instance.new('TextBox')
                keyInput.Size = UDim2.new(0.8, 0, 0.2, 0)
                keyInput.Position = UDim2.new(0.1, 0, 0.1, 0)
                keyInput.Text = '输入Key'
                keyInput.PlaceholderText = '输入Key'
                keyInput.BackgroundColor3 = Theme.InputFieldBG
                keyInput.Parent = popupFrame
                
                local valueInput = Instance.new('TextBox')
                valueInput.Size = UDim2.new(0.8, 0, 0.2, 0)
                valueInput.Position = UDim2.new(0.1, 0, 0.4, 0)
                valueInput.Text = '输入Value'
                valueInput.PlaceholderText = '输入Value'
                valueInput.BackgroundColor3 = Theme.InputFieldBG
                valueInput.Parent = popupFrame
                
                local confirmBtn = Instance.new('TextButton')
                confirmBtn.Size = UDim2.new(0.3, 0, 0.2, 0)
                confirmBtn.Position = UDim2.new(0.7, 0, 0.8, 0)
                confirmBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                confirmBtn.Text = '确认'
                confirmBtn.BackgroundColor3 = Theme.Primary
                confirmBtn.TextColor3 = Theme.TextBottonPrimary
                confirmBtn.Parent = popupFrame
                
                local _closeBtn = Instance.new('TextButton')
                _closeBtn.Size = UDim2.new(0.3, 0, 0.2, 0)
                _closeBtn.Position = UDim2.new(0.3, 0, 0.8, 0)
                _closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                _closeBtn.Text = '关闭'
                _closeBtn.BackgroundColor3 = Theme.ClosePrimary
                _closeBtn.TextColor3 = Theme.TextBottonPrimary
                _closeBtn.Parent = popupFrame
                
                _closeBtn.MouseButton1Click:Connect(function()
                    popupFrame:Destroy()
                end)
                
                confirmBtn.MouseButton1Click:Connect(function()
                    if keyInput.Text == '' or valueInput.Text == '' then
                        Knit.GetController('UIController').ShowTip:Fire('Key/Value不能为空')
                        return
                    end
                    
                    local topParent = FindTopParent(entryFrame)
                    local sValue = topParent:FindFirstChild('StringValue')
                    local keyTest = sValue:GetAttribute('Key')
                    local mergedData = HttpService:JSONDecode(sValue.Value)
                    
                    local function insertData(tbl, path, key1, value1)
                        local current = tbl
                        for i = 2, #path do
                            current = current[path[i]]
                        end
                        current[tostring(key1)] = value1
                    end
                    
                    if type(mergedData) == 'table' then
                        insertData(mergedData, currentPath, keyInput.Text, valueInput.Text)
                        Knit.GetService("DBService"):AdminRequest("SetData",
                            userIdInputText,
                            keyTest,
                            mergedData
                        ):andThen(function(tip)
                            Knit.GetController('UIController').ShowTip:Fire(tip)
                            popupFrame:Destroy()
                            Knit.GetService("DBService"):AdminRequest("GetData",
                                userIdInputText
                            ):andThen(function(newData)
                                UpdateDataDisplay(_scrollFrame, userIdInputText, newData)
                            end)
                        end)
                    end
                end)
            end)
        else
            -- 调整布局比例为4:3:1
            label.Size = UDim2.new(0.4, 0, 0, 30)
            label.Position = UDim2.new(0, 0, 0, 0)
            
            local valueBox = Instance.new('TextBox')
            valueBox.Size = UDim2.new(0.4, 0, 0, 30)
            valueBox.Position = UDim2.new(0.4, 0, 0, 0)
            valueBox.Text = tostring(value)
            valueBox.PlaceholderText = valueBox.Text
            valueBox.ClearTextOnFocus = false
            valueBox.TextSize = 16
            valueBox.TextColor3 = Theme.TextBoxPrimary
            valueBox.BackgroundColor3 = Theme.InputFieldBG
            valueBox.TextXAlignment = Enum.TextXAlignment.Left
            valueBox.Parent = entryFrame
            
            -- 添加保存按钮
            local saveBtn = Instance.new('TextButton')
            saveBtn.Size = UDim2.new(0.1, 0, 0, 30)
            saveBtn.AnchorPoint = Vector2.new(1, 0)
            saveBtn.Position = UDim2.new(0.9, 0, 0, 0)
            saveBtn.Text = "保存"
            saveBtn.TextSize = 16
            saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            saveBtn.BackgroundColor3 = Theme.Secondary
            saveBtn.TextColor3 = Theme.TextBottonPrimary
            saveBtn.Parent = entryFrame

            saveBtn.MouseButton1Click:Connect(function()
                local topParent = FindTopParent(entryFrame)
                local sValue = topParent:FindFirstChild('StringValue')
                local keyTest = sValue:GetAttribute('Key')
                local mergedData = HttpService:JSONDecode(sValue.Value)

                local function findKey(tbl, delKey, parentKey)
                    for k, v in pairs(tbl) do
                        if k == label.Text and parentKey == delKey then
                            tbl[k] = valueBox.Text
                            return true
                        elseif type(v) == 'table' then
                            local result = findKey(v, delKey, k)
                            if result then
                                return result
                            end
                        end
                    end
                    return nil
                end
                if type(mergedData) == 'table' then
                    local result = findKey(mergedData, currentPath[depth] or {}, currentPath[1])
                    if result then
                        Knit.GetService("DBService"):AdminRequest("SetData",
                            userIdInputText,
                            keyTest,
                            mergedData
                        ):andThen(function(tip)
                            Knit.GetController('UIController').ShowTip:Fire(tip)
                        end)
                    end
                else
                    mergedData = valueBox.Text
                    Knit.GetService("DBService"):AdminRequest("SetData",
                        userIdInputText,
                        keyTest,
                        mergedData
                    ):andThen(function(tip)
                        Knit.GetController('UIController').ShowTip:Fire(tip)
                    end)
                end
            end)
        end
            
        -- 添加删除按钮
        local deleteBtn = Instance.new('TextButton')
        deleteBtn.Size = UDim2.new(0.1, 0, 0, 30)
        deleteBtn.AnchorPoint = Vector2.new(1, 0)
        deleteBtn.Position = UDim2.new(1, 0, 0, 0)
        deleteBtn.Text = "删除"
        deleteBtn.TextSize = 16
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        deleteBtn.Parent = entryFrame

        deleteBtn.MouseButton1Click:Connect(function()
            local topParent = FindTopParent(entryFrame)
            local sValue = topParent:FindFirstChild('StringValue')
            local keyTest = sValue:GetAttribute('Key')
            local mergedData = HttpService:JSONDecode(sValue.Value)
            local function findKey(tbl, delKey, parentKey)
                for k, v in pairs(tbl) do
                    if k == label.Text and parentKey == delKey then
                        tbl[k] = nil
                        return true
                    elseif type(v) == 'table' then
                        local result = findKey(v, delKey, k)
                        if result then
                            return result
                        end
                    end
                end
                return nil
            end

            if type(mergedData) == 'table' then
                local result
                if depth == 0 then
                    mergedData = nil
                    result = true
                else
                    result = findKey(mergedData, currentPath[depth] or {}, currentPath[1])
                end
                if result then
                    Knit.GetService("DBService"):AdminRequest("SetData",
                        userIdInputText,
                        keyTest,
                        mergedData
                    ):andThen(function(tip)
                        Knit.GetController('UIController').ShowTip:Fire(tip)
                        -- 删除成功后重新获取数据
                        Knit.GetService("DBService"):AdminRequest("GetData",
                            userIdInputText
                        ):andThen(function(newData)
                            UpdateDataDisplay(_scrollFrame, userIdInputText, newData)
                        end)
                    end)
                end
            else
                mergedData = nil
                Knit.GetService("DBService"):AdminRequest("SetData",
                    userIdInputText,
                    keyTest,
                    mergedData
                ):andThen(function(tip)
                    Knit.GetController('UIController').ShowTip:Fire(tip)
                    -- 删除成功后重新获取数据
                    Knit.GetService("DBService"):AdminRequest("GetData",
                        userIdInputText
                    ):andThen(function(newData)
                        UpdateDataDisplay(_scrollFrame, userIdInputText, newData)
                    end)
                end)
            end
        end)
    end
    
    container.Parent = parent
    return container
end

_fetchBtn.MouseButton1Click:Connect(function()
    -- 初始化远程事件监听
    Knit.GetService("DBService"):AdminRequest("GetData", tonumber(_userIdBox.Text)):andThen(function(data)
        if type(data) == "table" then
            UpdateDataDisplay(_scrollFrame, tonumber(_userIdBox.Text), data)
            return
        elseif type(data) == "string" then
            Knit.GetController('UIController').ShowTip:Fire(data)
            return
        end
    end)
end)

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowAdminUI:Connect(function()
        _screenGui.Enabled = true
    end)
end)