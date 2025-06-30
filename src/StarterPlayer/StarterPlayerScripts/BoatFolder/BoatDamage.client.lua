--[[
模块功能：船只伤害数值飘出效果
版本：1.0.0
作者：Trea
修改记录：
2024-02-20 创建船只伤害数值飘出功能
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))

-- 存储上次船只血量，用于计算伤害值
local _lastBoatHealth = {}

-- 创建伤害数值飘出效果
-- @param boatModel 船只模型
-- @param damageValue 伤害值
local function CreateDamageNumber(boatModel, damageValue)
    if not boatModel or not boatModel.PrimaryPart then return end
    
    -- 创建ScreenGui用于显示伤害数值
    local damageGui = Instance.new("BillboardGui")
    damageGui.Name = "DamageNumber"
    damageGui.Size = UDim2.new(0, 100, 0, 50)
    damageGui.StudsOffset = Vector3.new(
        math.random(-3, 3), -- 随机X偏移
        math.random(2, 4),  -- 随机Y偏移
        math.random(-1, 1)  -- 随机Z偏移
    )
    damageGui.LightInfluence = 0
    damageGui.Adornee = boatModel.PrimaryPart
    
    -- 创建伤害数值标签
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Name = "DamageLabel"
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "-" .. tostring(damageValue)
    damageLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- 淡红色
    damageLabel.TextScaled = true
    damageLabel.Font = Enum.Font.SourceSansBold
    damageLabel.TextStrokeTransparency = 0
    damageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    damageLabel.TextXAlignment = Enum.TextXAlignment.Center
    damageLabel.TextYAlignment = Enum.TextYAlignment.Center
    damageLabel.Parent = damageGui
    
    -- 添加到工作区
    damageGui.Parent = boatModel
    
    -- 创建飘出动画
    local tweenInfo = TweenInfo.new(
        1.5, -- 持续时间1.5秒
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    -- 向上飘出并逐渐透明
    local upwardTween = TweenService:Create(damageGui, tweenInfo, {
        StudsOffset = damageGui.StudsOffset + Vector3.new(0, 6, 0)
    })
    
    local fadeTween = TweenService:Create(damageLabel, tweenInfo, {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    
    -- 播放动画
    upwardTween:Play()
    fadeTween:Play()
    
    -- 动画完成后销毁GUI
    fadeTween.Completed:Connect(function()
        damageGui:Destroy()
    end)
end

-- 监听船只血量变化
local function MonitorBoatHealth()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end
    
    local boatName = "PlayerBoat_" .. localPlayer.UserId
    local boat = workspace:FindFirstChild(boatName)
    
    if boat then
        -- 获取当前血量
        local currentHealth = boat:GetAttribute("Health") or 0
        local lastHealth = _lastBoatHealth[boatName] or currentHealth
        
        -- 如果血量减少，计算伤害值并显示
        if currentHealth < lastHealth then
            local damageValue = lastHealth - currentHealth
            if damageValue > 0 then
                CreateDamageNumber(boat, damageValue)
            end
        end
        
        -- 更新上次血量记录
        _lastBoatHealth[boatName] = currentHealth
        
        -- 监听血量属性变化
        if not boat:GetAttribute("HealthMonitored") then
            boat:SetAttribute("HealthMonitored", true)
            
            boat:GetAttributeChangedSignal("Health"):Connect(function()
                local newHealth = boat:GetAttribute("Health") or 0
                local oldHealth = _lastBoatHealth[boatName] or newHealth
                
                if newHealth < oldHealth then
                    local damage = oldHealth - newHealth
                    if damage > 0 then
                        CreateDamageNumber(boat, damage)
                    end
                end
                
                _lastBoatHealth[boatName] = newHealth
            end)
        end
    end
end

-- 监听工作区中船只的添加
workspace.ChildAdded:Connect(function(child)
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end
    
    local expectedBoatName = "PlayerBoat_" .. localPlayer.UserId
    if child.Name == expectedBoatName then
        -- 延迟一帧确保船只完全加载
        task.wait()
        MonitorBoatHealth()
    end
end)

-- 监听工作区中船只的移除
workspace.ChildRemoved:Connect(function(child)
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end
    
    local expectedBoatName = "PlayerBoat_" .. localPlayer.UserId
    if child.Name == expectedBoatName then
        -- 清除血量记录
        _lastBoatHealth[expectedBoatName] = nil
    end
end)

-- 监听服务端的船只受伤信号
Knit:OnStart():andThen(function()
end)