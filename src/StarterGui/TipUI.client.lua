-- 消息队列和UI容器
local TweenService = game:GetService("TweenService")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

-- TIP队列管理
local tipQueue = {}
local isShowingTip = false
local TIP_INTERVAL = 0.5 -- TIP之间的间隔时间（秒）

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

-- 显示单个TIP（前置声明）
local showSingleTip
local processQueue

-- 添加TIP到队列
local function addTipToQueue(message)
    if not message then
        return
    end
    if type(message) == 'number' then
        message = LanguageConfig.Get(message)
    end
    if not message or message == "" then
        return
    end
    
    table.insert(tipQueue, message)
    processQueue()
end

-- 处理队列
processQueue = function()
    if isShowingTip or #tipQueue == 0 then
        return
    end
    
    isShowingTip = true
    local message = table.remove(tipQueue, 1)
    showSingleTip(message)
                
    -- TIP显示完成，等待间隔时间后处理下一个
    task.wait(TIP_INTERVAL)
    isShowingTip = false
    processQueue()
end

-- 显示单个TIP（实际定义）
showSingleTip = function(message)
    local tip = _tipTemplate:Clone()
    tip.Visible = true
    
    tip.Position = UDim2.new(0.3, 0, 0.6, 0)
    
    tip.TextLabel.Text = message
    tip.Parent = _messageContainer
    tip.TextLabel.TextTransparency = 0
    
    local moveTween = TweenService:Create(
        tip,
        TweenInfo.new(0.7, Enum.EasingStyle.Quad), -- 持续时间0.7秒
        {
            Position = UDim2.new(0.3, 0, 0.3, 0),
        }
    )
    moveTween:Play()
    moveTween.Completed:Connect(function()
        local waitTween = TweenService:Create(
            tip.TextLabel,
            TweenInfo.new(0.5, Enum.EasingStyle.Linear), -- 持续时间0.5秒
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
        addTipToQueue(tip)
    end)
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowTip:Connect(addTipToQueue)
end)