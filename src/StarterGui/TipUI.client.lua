-- 消息队列和UI容器
local TweenService = game:GetService("TweenService")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'TipUI_GUI'
_screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
_screenGui.DisplayOrder = 999
_screenGui.Parent = PlayerGui

-- 飘窗UI模板
local _tipTemplate = Instance.new("Frame")
_tipTemplate.Name = "TipTemplate"
_tipTemplate.Size = UDim2.new(0.4, 0, 0.08, 0)
_tipTemplate.BackgroundTransparency = 1
_tipTemplate.Visible = false
_tipTemplate.ZIndex = 1000

local _textLabel = Instance.new("TextLabel")
_textLabel.Size = UDim2.new(1, 0, 1, 0)
_textLabel.TextColor3 = Color3.fromRGB(255,0,0)
_textLabel.Font = UIConfig.Font
_textLabel.TextSize = 20
_textLabel.BackgroundTransparency = 1
_textLabel.ZIndex = 1001
_textLabel.Parent = _tipTemplate

-- 创建消息容器
local _messageContainer = Instance.new("Frame")
_messageContainer.Name = "MessageContainer"
_messageContainer.Size = UDim2.new(1, 0, 1, 0)
_messageContainer.BackgroundTransparency = 1
_messageContainer.Parent = _screenGui

-- 飘窗显示函数
local function showMessage(message)
    if not message then
        return
    end
    if type(message) == 'number' then
        message = LanguageConfig.Get(message)
    end
    if not message or message == "" then
        return
    end
    local tip = _tipTemplate:Clone()
    tip.Visible = true
    
    tip.Position = UDim2.new(0.3, 0, 0.6, 0)
    
    tip.TextLabel.Text = message
    tip.Parent = _messageContainer
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

Knit:OnStart():andThen(function()
    local SystemService = Knit.GetService('SystemService')
    SystemService.Tip:Connect(function(tipId, ...)
        local tip = string.format(LanguageConfig.Get(tipId), ...)
        showMessage(tip)
    end)
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowTip:Connect(showMessage)
end)