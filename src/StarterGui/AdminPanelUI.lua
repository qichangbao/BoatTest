local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

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

local function UpdateDataDisplay(self, parent, userIdInputText, data, depth, parentPath)
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
                    subContainer = UpdateDataDisplay(self, entryFrame, userIdInputText, value, depth + 1, currentPath)
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
            addBtn.Position = UDim2.new(1, 0, 0, 0)
            addBtn.Text = "增加"
            addBtn.TextSize = 16
            addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            addBtn.BackgroundColor3 = Theme.Secondary
            addBtn.TextColor3 = Theme.TextBottonPrimary
            addBtn.Parent = entryFrame
            addBtn.MouseButton1Click:Connect(function()
            end)
        else
            -- 调整布局比例为4:3:1
            label.Size = UDim2.new(0.4, 0, 0, 30)
            label.Position = UDim2.new(0, 0, 0, 0)
            
            local valueBox = Instance.new('TextBox')
            valueBox.Size = UDim2.new(0.4, -5, 0, 30)
            valueBox.Position = UDim2.new(0.4, 0, 0, 0)
            valueBox.Text = tostring(value)
            valueBox.PlaceholderText = valueBox.Text
            valueBox.ClearTextOnFocus = false
            valueBox.TextSize = 16
            valueBox.TextColor3 = Theme.TextBoxPrimary
            valueBox.BackgroundColor3 = Theme.InputFieldBG
            valueBox.Parent = entryFrame
            
            valueBox.FocusLost:Connect(function()
            end)
            
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

            local function FindTopParent(frame)
                while frame.Parent ~= nil and frame.Parent.Name ~= 'DataContainerTop' do
                    frame = frame.Parent
                end
                return frame
            end

            saveBtn.MouseButton1Click:Connect(function()
                local topParent = FindTopParent(entryFrame)
                local sValue = topParent:FindFirstChild('StringValue')
                local keyTest = sValue:GetAttribute('Key')
                local mergedData = HttpService:JSONDecode(sValue.Value)
                print(mergedData)
                local function findKey(tbl)
                    for k, v in pairs(tbl) do
                        if type(v) == 'table' then
                            local result = findKey(v)
                            if result then
                                return result
                            end
                        else
                            if k == label.Text then
                                tbl[k] = valueBox.Text
                                return tbl[k]
                            end
                        end
                    end
                    return nil
                end
                if type(mergedData) == 'table' then
                    local result = findKey(mergedData)
                    if result then
                        Knit.GetService("DBService"):AdminRequest("SetData",
                            userIdInputText,
                            keyTest,
                            mergedData
                        ):andThen(function(tip)
                            Knit.GetController('TipController').Tip:Fire(tip)
                        end)
                    end
                else
                    mergedData = valueBox.Text
                    Knit.GetService("DBService"):AdminRequest("SetData",
                        userIdInputText,
                        keyTest,
                        mergedData
                    ):andThen(function(tip)
                        Knit.GetController('TipController').Tip:Fire(tip)
                    end)
                end
            end)
            
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
                
                local function findKey(tbl)
                    for k, v in pairs(tbl) do
                        if type(v) == 'table' then
                            local result = findKey(v)
                            if result then
                                return result
                            end
                        else
                            if k == label.Text then
                                tbl[k] = nil
                                return true
                            end
                        end
                    end
                    return nil
                end

                if type(mergedData) == 'table' then
                    local result = findKey(mergedData)
                    if result then
                        Knit.GetService("DBService"):AdminRequest("SetData",
                            userIdInputText,
                            keyTest,
                            mergedData
                        ):andThen(function(tip)
                            Knit.GetController('TipController').Tip:Fire(tip)
                            -- 删除成功后重新获取数据
                            Knit.GetService("DBService"):AdminRequest("GetData",
                                userIdInputText
                            ):andThen(function(newData)
                                UpdateDataDisplay(self, self.scrollFrame, userIdInputText, newData)
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
                        Knit.GetController('TipController').Tip:Fire(tip)
                        -- 删除成功后重新获取数据
                        Knit.GetService("DBService"):AdminRequest("GetData",
                            userIdInputText
                        ):andThen(function(newData)
                            UpdateDataDisplay(self, self.scrollFrame, userIdInputText, newData)
                        end)
                    end)
                end
            end)
        end
    end
    
    container.Parent = parent
    return container
end

local AdminPanelUI = {}
function AdminPanelUI:Init()
    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'AdminPanel'
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild('PlayerGui')

    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(0.8, 0, 0.9, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundTransparency = 1
    frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = screenGui

    -- 创建顶部控制栏
    local controlFrame = Instance.new('Frame')
    controlFrame.Size = UDim2.new(0.7, 0, 0, 40)
    controlFrame.AnchorPoint = Vector2.new(0.5, 1)
    controlFrame.Position = UDim2.new(0.5, 0, 0, -10)
    controlFrame.BackgroundTransparency = 1
    controlFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    controlFrame.Parent = frame

    -- 添加关闭按钮
    local closeBtn = Instance.new('TextButton')
    closeBtn.Name = 'CloseButton'
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Text = '×'
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.AutoButtonColor = false
    closeBtn.BackgroundColor3 = Theme.ClosePrimary
    closeBtn.TextColor3 = Theme.TextBottonPrimary
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.Position = UDim2.new(1, 40, 0.5, 0)
    closeBtn.Parent = controlFrame

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- 调整滚动框架位置和尺寸
    self.scrollFrame = Instance.new('ScrollingFrame')
    self.scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    self.scrollFrame.AnchorPoint = Vector2.new(0.5, 0)
    self.scrollFrame.Position = UDim2.new(0.5, 0, 0, 0)
    self.scrollFrame.CanvasSize = UDim2.new(1, 0, 0, 0)
    self.scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.scrollFrame.ScrollBarThickness = 8
    self.scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    self.scrollFrame.BackgroundColor3 = Theme.ScrollFrameBG
    self.scrollFrame.BackgroundTransparency = 0.2
    self.scrollFrame.Parent = frame

    local userIdBox = Instance.new('TextBox')
    userIdBox.Size = UDim2.new(0.3, 0, 1, 0)
    userIdBox.AnchorPoint = Vector2.new(1, 0.5)
    userIdBox.Position = UDim2.new(0.5, -50, 0.5, 0)
    userIdBox.Text = "输入用户ID"
    userIdBox.PlaceholderText = userIdBox.Text
    userIdBox.TextColor3 = Theme.TextBoxPrimary
    userIdBox.TextSize = 16
    userIdBox.BackgroundColor3 = Theme.InputFieldBG
    userIdBox.Parent = controlFrame

    local fetchBtn = Instance.new('TextButton')
    fetchBtn.Size = UDim2.new(0.3, 0, 1, 0)
    fetchBtn.AnchorPoint = Vector2.new(0, 0.5)
    fetchBtn.Position = UDim2.new(0.5, 50, 0.5, 0)
    fetchBtn.Text = "获取数据"
    fetchBtn.TextSize = 16
    fetchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fetchBtn.TextSize = 16
    fetchBtn.BackgroundColor3 = Theme.Primary
    fetchBtn.TextColor3 = Theme.TextBottonPrimary
    fetchBtn.Parent = controlFrame
    fetchBtn.MouseButton1Click:Connect(function()
        -- 初始化远程事件监听
        Knit.GetService("DBService"):AdminRequest("GetData", tonumber(userIdBox.Text)):andThen(function(data)
            if type(data) == "table" then
                UpdateDataDisplay(self, self.scrollFrame, tonumber(userIdBox.Text), data)
                return
            elseif type(data) == "string" then
                Knit.GetController('TipController').Tip:Fire(data)
                return
            end
        end)
    end)
end

return AdminPanelUI