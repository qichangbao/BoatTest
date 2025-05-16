local UIConfig = {}
-- 定义UI元素
UIConfig.Font = Enum.Font.Arimo
UIConfig.CloseButtonSize = UDim2.new(0, 50, 0, 50)

UIConfig.CreateCloseButton = function(callfunc)
    -- 添加关闭按钮
    local closeBtn = Instance.new('TextButton')
    closeBtn.Name = 'CloseButton'
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Text = '×'
    closeBtn.TextSize = 24
    closeBtn.Font = UIConfig.Font
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.AutoButtonColor = false
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(callfunc)

    return closeBtn
end

return UIConfig