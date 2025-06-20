local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local function CreateLoadingUI()
    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'LoadingUI_Gui'
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10

    -- 背景遮罩
    local background = Instance.new('Frame', screenGui)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.Size = UDim2.new(1, 0, 1, 0)
    background.AnchorPoint = Vector2.new(0.5, 0.5)
    background.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    -- 进度条容器
    local progressContainer = Instance.new('Frame', screenGui)
    progressContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    progressContainer.Position = UDim2.new(0.5, 0, 0.7, 0)
    progressContainer.Size = UDim2.new(0.3, 0, 0.05, 0)
    progressContainer.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)

    -- 动态进度条
    local progressBar = Instance.new('Frame', progressContainer)
    progressBar.AnchorPoint = Vector2.new(0, 0.5)
    progressBar.Position = UDim2.new(0, 0, 0.5, 0)
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.new(0, 0.6, 1)

    -- 百分比文本
    local percentageText = Instance.new('TextLabel', screenGui)
    percentageText.AnchorPoint = Vector2.new(0.5, 0.5)
    percentageText.Position = UDim2.new(0.5, 0, 0.6, 0)
    percentageText.Text = '0%'
    percentageText.TextColor3 = Color3.new(1, 1, 1)
    percentageText.Font = Enum.Font.SourceSansBold
    percentageText.TextSize = 30
    
    return {
        Show = function(duration)
            screenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')
            
            local tweenInfo = TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.InOut
            )
            
            local tween = TweenService:Create(
                progressBar,
                tweenInfo,
                {Size = UDim2.new(1, 0, 1, 0)}
            )

            tween:Play()
            local startTime = tick()
            while tick() - startTime < duration do
                local progress = (tick() - startTime) / duration
                percentageText.Text = string.format("%d%%", math.floor(progress * 100))
                task.wait()
            end
            percentageText.Text = "100%"
            screenGui:Destroy()
        end
    }
end

return CreateLoadingUI()