local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local LanguageConfig = require(ConfigFolder:WaitForChild("LanguageConfig"))

local UIConfig = {}
-- 定义UI元素
UIConfig.Font = Enum.Font.Arimo
UIConfig.CloseButtonSize = UDim2.new(0, 50, 0, 50)

UIConfig.CreateCloseButton = function(callfunc)
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

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(callfunc)

    return closeBtn
end

UIConfig.CreateConfirmButton = function(callfunc)
    local _confirmButton = Instance.new('TextButton')
    _confirmButton.Name = 'ConfirmButton'
    _confirmButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    _confirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
    _confirmButton.Text = LanguageConfig:Get(10002)
    _confirmButton.Font = UIConfig.Font
    _confirmButton.TextSize = 18
    _confirmButton.TextColor3 = Color3.new(1, 1, 1)
    _confirmButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)

    _confirmButton.MouseButton1Click:Connect(callfunc)

    return _confirmButton
end

UIConfig.CreateCancelButton = function(callfunc)
    local _cancelButton = Instance.new('TextButton')
    _cancelButton.Name = 'CancelButton'
    _cancelButton.Size = UDim2.new(0.3, 0, 0.2, 0)
    _cancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
    _cancelButton.Text = LanguageConfig:Get(10003)
    _cancelButton.Font = UIConfig.Font
    _cancelButton.TextSize = 18
    _cancelButton.TextColor3 = Color3.new(1, 1, 1)
    _cancelButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)

    _cancelButton.MouseButton1Click:Connect(callfunc)

    return _cancelButton
end

return UIConfig