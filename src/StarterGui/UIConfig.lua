local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))

local UIConfig = {}
-- 定义UI元素
UIConfig.Font = Enum.Font.SourceSansBold
UIConfig.CloseButtonSize = UDim2.new(0, 50, 0, 50)

UIConfig.CreateCorner = function(parent, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = radius or UDim.new(1, 0)
    corner.Parent = parent
    
    return corner
end

UIConfig.CreateBlock = function(parent)
    -- 禁用背景点击
    local blocker = Instance.new("TextButton")
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.BackgroundTransparency = 1
    blocker.Text = ""
    blocker.Parent = parent
    
    -- 新增模态背景
    local modalFrame = Instance.new("Frame")
    modalFrame.Size = UDim2.new(1, 0, 1, 0)
    modalFrame.BackgroundTransparency = 0.5
    modalFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    modalFrame.Parent = parent
end

UIConfig.CreateFrame = function(parent)
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(0.8, 0, 0.8, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 1
    frame.Parent = parent

    return frame
end

UIConfig.CreateCloseButton = function(parent, callfunc)
    -- 添加关闭按钮
    local closeBtn = Instance.new('TextButton')
    closeBtn.Name = 'closeBtn'
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    closeBtn.Text = '×'
    closeBtn.Font = UIConfig.Font
    closeBtn.TextSize = 24
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.Parent = parent

    UIConfig.CreateCorner(closeBtn)

    closeBtn.MouseButton1Click:Connect(callfunc)

    return closeBtn
end

UIConfig.CreateConfirmButton = function(parent, callfunc)
    local confirmButton = Instance.new('TextButton')
    confirmButton.Name = 'confirmButton'
    confirmButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    confirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
    confirmButton.Text = LanguageConfig.Get(10002)
    confirmButton.Font = UIConfig.Font
    confirmButton.TextSize = 18
    confirmButton.TextColor3 = Color3.new(1, 1, 1)
    confirmButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    confirmButton.Parent = parent
    UIConfig.CreateCorner(confirmButton)

    confirmButton.MouseButton1Click:Connect(callfunc)

    return confirmButton
end

UIConfig.CreateCancelButton = function(parent, callfunc)
    local cancelButton = Instance.new('TextButton')
    cancelButton.Name = 'cancelButton'
    cancelButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    cancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
    cancelButton.Text = LanguageConfig.Get(10003)
    cancelButton.Font = UIConfig.Font
    cancelButton.TextSize = 18
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    cancelButton.Parent = parent
    UIConfig.CreateCorner(cancelButton)

    cancelButton.MouseButton1Click:Connect(callfunc)

    return cancelButton
end

local function CreateFrame(parent, title, frameSize)
    local frame = UIConfig.CreateFrame(parent)
    frame.Size = frameSize
    UIConfig.CreateCorner(frame, UDim.new(0, 8))
    
    -- 标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0.5, 0, 0, 0)
    titleBar.AnchorPoint = Vector2.new(0.5, 1)
    titleBar.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
    titleBar.Parent = frame
    UIConfig.CreateCorner(titleBar, UDim.new(0, 8))
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(0.3, 0, 1, 0)
    titleText.Position = UDim2.new(0.5, 0, 0, 0)
    titleText.AnchorPoint = Vector2.new(0.5, 0)
    titleText.Text = title
    titleText.Font = UIConfig.Font
    titleText.TextSize = 20
    titleText.TextColor3 = Color3.new(1, 1, 1)
    titleText.BackgroundTransparency = 1
    titleText.TextXAlignment = Enum.TextXAlignment.Center
    titleText.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = UIConfig.CreateCloseButton(titleBar, function()
        parent.Enabled = false
    end)
    closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0.5, 0)

    return frame
end

UIConfig.CreateBigFrame = function(parent, title)
    return CreateFrame(parent, title, UDim2.new(0, 700, 0, 400))
end

return UIConfig