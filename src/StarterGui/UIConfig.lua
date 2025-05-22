local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))

local UIConfig = {}
-- 定义UI元素
UIConfig.Font = Enum.Font.Arimo
UIConfig.CloseButtonSize = UDim2.new(0, 50, 0, 50)

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
    closeBtn.Name = 'CloseButton'
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    closeBtn.Text = '×'
    closeBtn.Font = UIConfig.Font
    closeBtn.TextSize = 24
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.Parent = parent

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(callfunc)

    return closeBtn
end

UIConfig.CreateConfirmButton = function(parent, callfunc)
    local _confirmButton = Instance.new('TextButton')
    _confirmButton.Name = 'ConfirmButton'
    _confirmButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    _confirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
    _confirmButton.Text = LanguageConfig:Get(10002)
    _confirmButton.Font = UIConfig.Font
    _confirmButton.TextSize = 18
    _confirmButton.TextColor3 = Color3.new(1, 1, 1)
    _confirmButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    _confirmButton.Parent = parent

    _confirmButton.MouseButton1Click:Connect(callfunc)

    return _confirmButton
end

UIConfig.CreateCancelButton = function(parent, callfunc)
    local _cancelButton = Instance.new('TextButton')
    _cancelButton.Name = 'CancelButton'
    _cancelButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    _cancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
    _cancelButton.Text = LanguageConfig:Get(10003)
    _cancelButton.Font = UIConfig.Font
    _cancelButton.TextSize = 18
    _cancelButton.TextColor3 = Color3.new(1, 1, 1)
    _cancelButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    _cancelButton.Parent = parent

    _cancelButton.MouseButton1Click:Connect(callfunc)

    return _cancelButton
end

return UIConfig