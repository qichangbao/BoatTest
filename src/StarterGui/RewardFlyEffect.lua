--[[
模块名称：奖励飞行特效系统
功能：处理宝箱奖励从宝箱位置飞向UI按钮的特效
作者：Trea AI
版本：1.0.0
最后修改：2024-12-19
]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))

local RewardFlyEffect = {}

-- 特效配置
local EFFECT_CONFIG = {
    duration = 1.5, -- 飞行时间
    trailDuration = 0.8, -- 拖尾持续时间
    iconSize = UDim2.new(0, 40, 0, 40), -- 图标大小
    easingStyle = Enum.EasingStyle.Quart,
    easingDirection = Enum.EasingDirection.Out
}

-- 奖励类型配置
local REWARD_CONFIGS = {
    Gold = {
        targetButton = "GoldLabel",
        color = Color3.fromRGB(255, 140, 0), -- 火焰橙色
        innerColor = Color3.fromRGB(255, 215, 0), -- 内部金色
        outerColor = Color3.fromRGB(255, 69, 0) -- 外部红橙色
    },
    Item = {
        targetButton = "BackpackButton",
        color = Color3.fromRGB(100, 149, 237), -- 蓝色火焰
        innerColor = Color3.fromRGB(173, 216, 230),
        outerColor = Color3.fromRGB(25, 25, 112)
    },
    Buff = {
        targetButton = "BuffButton",
        color = Color3.fromRGB(255, 105, 180), -- 粉色火焰
        innerColor = Color3.fromRGB(255, 182, 193),
        outerColor = Color3.fromRGB(199, 21, 133)
    }
}

-- 创建金光拖尾效果
local function createGoldenTrailEffect(config, startPosition)
    -- 创建一个不可见的Part作为载体
    local emitterPart = Instance.new("Part")
    emitterPart.Size = Vector3.new(0.2, 0.2, 0.2)
    emitterPart.Position = startPosition
    emitterPart.Anchored = true
    emitterPart.CanCollide = false
    emitterPart.Transparency = 1
    emitterPart.Parent = workspace
    
    -- 创建发光球体
    local glowBall = Instance.new("Part")
    glowBall.Size = Vector3.new(0.5, 0.5, 0.5)
    glowBall.Shape = Enum.PartType.Ball
    glowBall.Material = Enum.Material.Neon
    glowBall.Color = config.color
    glowBall.Anchored = true
    glowBall.CanCollide = false
    glowBall.Parent = emitterPart
    
    -- 创建拖尾效果的附件点
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(-0.2, 0, 0)
    attachment0.Parent = glowBall
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0.2, 0, 0)
    attachment1.Parent = glowBall
    
    -- 创建金光拖尾
    local trail = Instance.new("Trail")
    trail.Parent = glowBall
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    
    -- 金光拖尾配置
    trail.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 150)), -- 亮金色
        ColorSequenceKeypoint.new(0.5, config.color), -- 中间色
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0)) -- 深金色
    }
    trail.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.7, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    trail.Lifetime = 1.0
    trail.MinLength = 0.5
    trail.FaceCamera = true
    trail.WidthScale = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.3)
    }
    
    -- 添加闪烁效果
    local pointLight = Instance.new("PointLight")
    pointLight.Parent = glowBall
    pointLight.Color = config.color
    pointLight.Brightness = 2
    pointLight.Range = 5
    
    return emitterPart, glowBall, trail, pointLight
end

-- 获取目标按钮的屏幕坐标位置
local function getTargetButtonScreenPosition(targetButtonName)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- 首先尝试查找MainUI_GUI
    local mainUI = playerGui:FindFirstChild("MainUI_GUI")
    if not mainUI then
        -- 备选：查找MainUI
        mainUI = playerGui:FindFirstChild("MainUI")
        if not mainUI then
            warn("找不到MainUI_GUI或MainUI")
            -- 打印所有可用的GUI
            for _, gui in pairs(playerGui:GetChildren()) do
                print("可用GUI:", gui.Name)
            end
            return nil
        end
    end
    
    local targetButton = mainUI:FindFirstChild(targetButtonName)
    if not targetButton then
        warn("找不到目标按钮:", targetButtonName)
        -- 打印MainUI中的所有子元素
        for _, child in pairs(mainUI:GetChildren()) do
            print("MainUI子元素:", child.Name)
        end
        return nil
    end
    
    -- 获取按钮在屏幕上的中心位置
    local screenX = targetButton.AbsolutePosition.X + targetButton.AbsoluteSize.X/2
    local screenY = targetButton.AbsolutePosition.Y + targetButton.AbsoluteSize.Y/2
    
    print("找到目标按钮:", targetButtonName, "屏幕坐标:", screenX, screenY)
    return Vector2.new(screenX, screenY)
end

-- 世界坐标转换为屏幕坐标
local function worldToScreenPosition(worldPosition)
    local camera = Workspace.CurrentCamera
    local screenPoint, onScreen = camera:WorldToScreenPoint(worldPosition)
    
    if onScreen then
        local screenGui = PlayerGui:FindFirstChild("MainUI_GUI")
        if screenGui then
            local screenSize = screenGui.AbsoluteSize
            return UDim2.new(0, screenPoint.X, 0, screenPoint.Y)
        end
    end
    
    -- 如果转换失败，返回屏幕中心
    return UDim2.new(0.5, 0, 0.5, 0)
end

-- 播放飞行特效
function RewardFlyEffect.PlayEffect(rewardType, chestPosition)
    print("开始播放特效 - 奖励类型:", rewardType, "宝箱位置:", chestPosition)
    
    local config = REWARD_CONFIGS[rewardType]
    if not config then
        warn("未知的奖励类型: " .. tostring(rewardType))
        return
    end
    
    -- 获取目标按钮的屏幕坐标位置
    local targetScreenPos = getTargetButtonScreenPosition(config.targetButton)
    if not targetScreenPos then
        warn("无法找到目标按钮: " .. config.targetButton)
        return
    end
    
    -- 将宝箱的世界坐标转换为屏幕坐标
    local camera = workspace.CurrentCamera
    local chestScreenPoint, onScreen = camera:WorldToScreenPoint(chestPosition)
    
    if not onScreen then
        warn("宝箱不在屏幕范围内")
        return
    end
    
    -- 创建屏幕GUI来显示特效
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RewardFlyEffect"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- 创建火焰主体Frame
    local flameFrame = Instance.new("Frame")
    flameFrame.Name = "FlameCore"
    flameFrame.Size = UDim2.new(0, 24, 0, 32) -- 火焰形状：宽24高32
    flameFrame.Position = UDim2.new(0, chestScreenPoint.X - 12, 0, chestScreenPoint.Y - 16)
    flameFrame.BackgroundColor3 = config.innerColor
    flameFrame.BorderSizePixel = 0
    flameFrame.Parent = screenGui
    
    -- 火焰形状的圆角（顶部更圆，底部较尖）
    local flameCorner = Instance.new("UICorner")
    flameCorner.CornerRadius = UDim.new(0, 12)
    flameCorner.Parent = flameFrame
    
    -- 外层火焰效果
    local outerFlame = Instance.new("Frame")
    outerFlame.Name = "OuterFlame"
    outerFlame.Size = UDim2.new(1.4, 0, 1.3, 0)
    outerFlame.Position = UDim2.new(-0.2, 0, -0.15, 0)
    outerFlame.BackgroundColor3 = config.outerColor
    outerFlame.BackgroundTransparency = 0.4
    outerFlame.BorderSizePixel = 0
    outerFlame.Parent = flameFrame
    
    local outerCorner = Instance.new("UICorner")
    outerCorner.CornerRadius = UDim.new(0, 15)
    outerCorner.Parent = outerFlame
    
    -- 内层火焰核心
    local innerFlame = Instance.new("Frame")
    innerFlame.Name = "InnerFlame"
    innerFlame.Size = UDim2.new(0.6, 0, 0.7, 0)
    innerFlame.Position = UDim2.new(0.2, 0, 0.2, 0)
    innerFlame.BackgroundColor3 = Color3.fromRGB(255, 255, 200) -- 白热化核心
    innerFlame.BackgroundTransparency = 0.3
    innerFlame.BorderSizePixel = 0
    innerFlame.Parent = flameFrame
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 8)
    innerCorner.Parent = innerFlame
    
    -- 火花效果1
    local spark1 = Instance.new("Frame")
    spark1.Name = "Spark1"
    spark1.Size = UDim2.new(0, 4, 0, 4)
    spark1.Position = UDim2.new(1.1, 0, 0.3, 0)
    spark1.BackgroundColor3 = config.color
    spark1.BorderSizePixel = 0
    spark1.Parent = flameFrame
    
    local spark1Corner = Instance.new("UICorner")
    spark1Corner.CornerRadius = UDim.new(0.5, 0)
    spark1Corner.Parent = spark1
    
    -- 火花效果2
    local spark2 = Instance.new("Frame")
    spark2.Name = "Spark2"
    spark2.Size = UDim2.new(0, 3, 0, 3)
    spark2.Position = UDim2.new(-0.2, 0, 0.5, 0)
    spark2.BackgroundColor3 = config.color
    spark2.BorderSizePixel = 0
    spark2.Parent = flameFrame
    
    local spark2Corner = Instance.new("UICorner")
    spark2Corner.CornerRadius = UDim.new(0.5, 0)
    spark2Corner.Parent = spark2
    
    -- 创建飞行动画
    local tweenInfo = TweenInfo.new(
        EFFECT_CONFIG.duration,
        EFFECT_CONFIG.easingStyle,
        EFFECT_CONFIG.easingDirection,
        0,
        false,
        0
    )
    
    -- 移动到目标位置
    local targetPosition = UDim2.new(0, targetScreenPos.X - 12, 0, targetScreenPos.Y - 16)
    local moveTween = TweenService:Create(flameFrame, tweenInfo, {Position = targetPosition})
    
    -- 火焰摇摆效果
    local swayTween = TweenService:Create(flameFrame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 5})
    
    -- 外层火焰闪烁效果
    local flickerTween = TweenService:Create(outerFlame, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1.5, 0, 1.4, 0)
    })
    
    -- 内层火焰脉冲
    local pulseTween = TweenService:Create(innerFlame, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0.7, 0, 0.8, 0)
    })
    
    -- 火花飞舞动画
    local spark1Tween = TweenService:Create(spark1, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Position = UDim2.new(1.3, 0, 0.1, 0),
        BackgroundTransparency = 0.8
    })
    
    local spark2Tween = TweenService:Create(spark2, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Position = UDim2.new(-0.3, 0, 0.3, 0),
        BackgroundTransparency = 0.9
    })
    
    -- 播放动画
    moveTween:Play()
    swayTween:Play()
    flickerTween:Play()
    pulseTween:Play()
    spark1Tween:Play()
    spark2Tween:Play()
    
    -- 动画完成后的处理
    moveTween.Completed:Connect(function()
        -- 停止所有循环动画
        swayTween:Cancel()
        flickerTween:Cancel()
        pulseTween:Cancel()
        spark1Tween:Cancel()
        spark2Tween:Cancel()
        
        -- 创建火焰爆炸效果
        local explosion = Instance.new("Frame")
        explosion.Name = "FlameExplosion"
        explosion.Size = UDim2.new(0, 30, 0, 30)
        explosion.Position = UDim2.new(0, targetScreenPos.X - 15, 0, targetScreenPos.Y - 15)
        explosion.BackgroundColor3 = config.innerColor
        explosion.BackgroundTransparency = 0.3
        explosion.BorderSizePixel = 0
        explosion.Parent = screenGui
        
        local explosionCorner = Instance.new("UICorner")
        explosionCorner.CornerRadius = UDim.new(0.5, 0)
        explosionCorner.Parent = explosion
        
        -- 外层爆炸环
        local explosionRing = Instance.new("Frame")
        explosionRing.Name = "ExplosionRing"
        explosionRing.Size = UDim2.new(1.5, 0, 1.5, 0)
        explosionRing.Position = UDim2.new(-0.25, 0, -0.25, 0)
        explosionRing.BackgroundColor3 = config.outerColor
        explosionRing.BackgroundTransparency = 0.6
        explosionRing.BorderSizePixel = 0
        explosionRing.Parent = explosion
        
        local ringCorner = Instance.new("UICorner")
        ringCorner.CornerRadius = UDim.new(0.5, 0)
        ringCorner.Parent = explosionRing
        
        -- 爆炸动画
        local explosionTween = TweenService:Create(explosion, TweenInfo.new(0.4), {
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0, targetScreenPos.X - 40, 0, targetScreenPos.Y - 40),
            BackgroundTransparency = 1
        })
        
        local ringTween = TweenService:Create(explosionRing, TweenInfo.new(0.4), {
            Size = UDim2.new(2.5, 0, 2.5, 0),
            Position = UDim2.new(-0.75, 0, -0.75, 0),
            BackgroundTransparency = 1
        })
        
        explosionTween:Play()
        ringTween:Play()
        
        explosionTween.Completed:Connect(function()
            -- 清理所有特效对象
            if screenGui then
                screenGui:Destroy()
            end
        end)
    end)
end

return RewardFlyEffect