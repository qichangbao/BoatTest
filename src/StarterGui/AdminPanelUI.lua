local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local AdminPanelUI = {}

function AdminPanelUI:Init()
    if not RunService:IsStudio() then return end
    
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "AdminPanelUI"
    self.gui.ResetOnSpawn = false
    self.gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.05, 0, 0.05, 0)
    closeButton.Position = UDim2.new(0.95, 0, 0.02, 0)
    closeButton.Text = "X"
    closeButton.MouseButton1Click:Connect(function()
        self.gui:Destroy()
    end)
    closeButton.Parent = self.gui

    -- 用户ID输入框
    self.userIdInput = Instance.new("TextBox")
    self.userIdInput.Size = UDim2.new(0.2, 0, 0.05, 0)
    self.userIdInput.Position = UDim2.new(0.4, 0, 0.1, 0)
    self.userIdInput.PlaceholderText = "输入用户ID"
    self.userIdInput.Parent = self.gui

    -- 数据展示框架
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
    scrollFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
    scrollFrame.Parent = self.gui

    -- 加载按钮
    local loadButton = Instance.new("TextButton")
    loadButton.Size = UDim2.new(0.1, 0, 0.05, 0)
    loadButton.Position = UDim2.new(0.61, 0, 0.1, 0)
    loadButton.Text = "加载数据"
    loadButton.MouseButton1Click:Connect(function()
        -- 初始化远程事件监听
        Knit.GetService("DBService"):AdminRequest("GetData", tonumber(self.userIdInput.Text)):andThen(function(data)
            self:UpdateDataDisplay(scrollFrame, data)
        end)
    end)
    loadButton.Parent = self.gui
end

local function CreateEntry(self, parent, key, value, indent, fullKeyPath, yOffset)
    indent = indent or 0
    fullKeyPath = fullKeyPath or {}
    
    local entryFrame = Instance.new("Frame")
    entryFrame.Size = UDim2.new(1, -indent*20, 0, 30)
    entryFrame.Position = UDim2.new(0, indent*20, 0, yOffset)
    entryFrame.BackgroundColor3 = Color3.new(0.2 + indent*0.1, 0.2, 0.2)
    entryFrame.BackgroundTransparency = 0.8
    entryFrame.Parent = parent

    -- 添加展开按钮
    local expandButton
    if type(value) == "table" then
        expandButton = Instance.new("TextButton")
        expandButton.Size = UDim2.new(0.05, 0, 1, 0)
        expandButton.Text = "+"
        expandButton.Parent = entryFrame
    end

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = expandButton and UDim2.new(0.25, 0, 1, 0) or UDim2.new(0.3, 0, 1, 0)
    keyLabel.Position = expandButton and UDim2.new(0.05, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    keyLabel.Text = key
    keyLabel.Parent = entryFrame

    -- 表格展开逻辑
    local subFrame
    local isExpanded = false
    
    if expandButton then
        expandButton.MouseButton1Click:Connect(function()
            isExpanded = not isExpanded
            expandButton.Text = isExpanded and "-" or "+"
            
            if isExpanded then
                -- 动态创建子项
                subFrame:ClearAllChildren()
                local childYOffset = 0
                for k, v in pairs(value) do
                    childYOffset = childYOffset + 30
                    CreateEntry(self, subFrame, k, v, indent + 1, {unpack(fullKeyPath)}, childYOffset)
                end
                subFrame.Size = UDim2.new(1, 0, 0, childYOffset)
                subFrame.Visible = true
            else
                subFrame.Visible = false
                subFrame.Size = UDim2.new(1, 0, 0, 0)
            end
        end)
        
        subFrame = Instance.new("Frame")
        subFrame.Size = UDim2.new(1, 0, 0, 0)
        subFrame.BackgroundTransparency = 1
        subFrame.Visible = false
        subFrame.Parent = entryFrame
    end

    if type(value) ~= "table" then
        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0.4, 0, 1, 0)
        valueBox.Position = UDim2.new(0.3, 0, 0, 0)
        valueBox.Text = tostring(value)
        valueBox.TextWrapped = true
        valueBox.TextXAlignment = Enum.TextXAlignment.Left
        valueBox.Parent = entryFrame

        local saveButton = Instance.new("TextButton")
        saveButton.Size = UDim2.new(0.2, 0, 1, 0)
        saveButton.Position = UDim2.new(0.7, 0, 0, 0)
        saveButton.Text = "保存"
        saveButton.MouseButton1Click:Connect(function()
            local keyPath = #fullKeyPath > 0 and table.concat(fullKeyPath, ".").."."..key or key
            Knit.GetService("DBService"):AdminRequest("SetData", 
                tonumber(self.userIdInput.Text), 
                keyPath, 
                valueBox.Text
            ):andThen(function(tip)
                Knit.GetController('TipController').Tip:Fire(tip)
            end)
        end)
        saveButton.Parent = entryFrame
    end
    
    return yOffset + 30
end

function AdminPanelUI:UpdateDataDisplay(frame, data)
    frame:ClearAllChildren()
    
    local yOffset = 0
    for key, value in pairs(data) do
        yOffset = CreateEntry(self, frame, key, value, 0, {}, yOffset)
    end
    
    frame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

return AdminPanelUI