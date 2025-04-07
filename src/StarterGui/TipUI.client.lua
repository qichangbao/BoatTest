
local TweenService = game:GetService("TweenService")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local TipController = Knit.GetController('TipController')

local ScreenGui = Instance.new('ScreenGui')
ScreenGui.Name = 'TipUI'
ScreenGui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

-- 消息队列和UI容器

-- 飘窗UI模板
local tipTemplate = Instance.new("Frame")
tipTemplate.Name = "TipTemplate"
tipTemplate.Size = UDim2.new(0.4, 0, 0.08, 0)
tipTemplate.BackgroundTransparency = 1 -- 隐藏底框
tipTemplate.Visible = false

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.TextColor3 = Color3.fromRGB(255,0,0) -- 红色字体
textLabel.Font = Enum.Font.SourceSansSemibold
textLabel.TextSize = 20
textLabel.BackgroundTransparency = 1
textLabel.Parent = tipTemplate

-- 创建消息容器
local messageContainer = Instance.new("Frame")
messageContainer.Name = "MessageContainer"
messageContainer.Size = UDim2.new(1, 0, 1, 0)
messageContainer.BackgroundTransparency = 1
messageContainer.Parent = ScreenGui

-- 飘窗显示函数
local function showMessage(message)
    local tip = tipTemplate:Clone()
    tip.Visible = true
    
    tip.Position = UDim2.new(0.3, 0, 0.6, 0)
    
    tip.TextLabel.Text = message
    tip.Parent = messageContainer
    tip.TextLabel.TextTransparency = 0
    
    local moveTween = TweenService:Create(
        tip,
        TweenInfo.new(0.7, Enum.EasingStyle.Quad), -- 持续时间1秒
        {
            Position = UDim2.new(0.3, 0, 0.3, 0),
        }
    )
    moveTween:Play()
    moveTween.Completed:Connect(function()
        local waitTween = TweenService:Create(
            tip.TextLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Linear), -- 持续时间1秒
            {
                TextTransparency = 1
            }
        )
        waitTween:Play()
        waitTween.Completed:Connect(function()
            local fadeTween = TweenService:Create(
                tip.TextLabel,
                TweenInfo.new(0.3, Enum.EasingStyle.Linear),
                {
                    TextTransparency = 1
                }
            )
            
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                tip:Destroy()
            end)
        end)
    end)
end

TipController.Tip:Connect(showMessage)