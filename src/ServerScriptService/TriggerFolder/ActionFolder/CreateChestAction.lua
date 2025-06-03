print("加载CreateChestAction")
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))

local CreateChestAction = {}
setmetatable(CreateChestAction, ActionBase)
CreateChestAction.__index = CreateChestAction

function CreateChestAction.new(config, condition)
    local self = setmetatable(ActionBase.new(config, condition), CreateChestAction)
    self.destroyToResetCondition = config.DestroyToResetCondition or false
    self.ResetConditionDelayTime = config.ResetConditionDelayTime or {0, 0}
    self.isTouched = false
    return self
end

function CreateChestAction:CreateAnchor()
    -- 创建一个不可见的锚点
    self.anchor = Instance.new("Part")
    self.anchor.Anchored = true
    self.anchor.CanCollide = false
    self.anchor.Transparency = 1
    self.anchor.Size = Vector3.new(1, 1, 1)
    self.anchor.Position = self.chest.PrimaryPart.Position
    self.anchor.Parent = workspace

    -- 创建 Attachment
    local chestAttachment = Instance.new("Attachment")
    chestAttachment.Parent = self.chest.PrimaryPart

    local anchorAttachment = Instance.new("Attachment")
    anchorAttachment.Parent = self.anchor

    -- 位置对齐（只限制Y轴）
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Attachment0 = chestAttachment
    alignPosition.Attachment1 = anchorAttachment
    alignPosition.MaxForce = 4000
    alignPosition.Responsiveness = 10
    alignPosition.RigidityEnabled = false
    alignPosition.Parent = self.chest.PrimaryPart

    -- 方向对齐（防止翻滚）
    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Attachment0 = chestAttachment
    alignOrientation.Attachment1 = anchorAttachment
    alignOrientation.MaxTorque = 4000
    alignOrientation.Responsiveness = 10
    alignOrientation.RigidityEnabled = true
    alignOrientation.Parent = self.chest.PrimaryPart
end

local function PlayOpenChestAni(chest, callback)
    local TweenService = game:GetService("TweenService")
    local chestTop = chest:FindFirstChild("ChestTop")
    
    if not chestTop then
        warn("找不到箱盖模型，请确保箱子中有名为 'ChestTop' 的模型")
        return
    end
    
    -- 确保chestTop有PrimaryPart
    if not chestTop.PrimaryPart then
        warn("ChestTop模型没有设置PrimaryPart，请在Studio中设置")
        return
    end
    
    -- 获取当前位置和目标位置
    local currentCFrame = chestTop:GetPivot()
    local targetCFrame = currentCFrame * CFrame.Angles(0, 0, math.rad(-90))
    
    -- 创建动画
    local tweenInfo = TweenInfo.new(
        1.5, -- 持续时间
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    -- 创建一个NumberValue用于动画进度
    local animationProgress = Instance.new("NumberValue")
    animationProgress.Value = 0
    
    -- 创建Tween
    local tween = TweenService:Create(animationProgress, tweenInfo, {Value = 1})
    
    -- 监听动画进度
    animationProgress.Changed:Connect(function(alpha)
        local lerpedCFrame = currentCFrame:Lerp(targetCFrame, alpha)
        chestTop:PivotTo(lerpedCFrame)
    end)
    
    -- 播放动画
    tween:Play()
    
    -- 清理
    tween.Completed:Connect(function()
        animationProgress:Destroy()
        callback()
    end)
end

function CreateChestAction:Execute()
    ActionBase.Execute(self)

    print("执行CreateChestAction")

    local function ChestTouched()
        self.isTouched = true
        self.chest.PrimaryPart.CanCollide = false
        
        PlayOpenChestAni(self.chest, function()
            -- 遍历宝箱中的所有WeldConstraint并移除
            for _, descendant in pairs(self.chest:GetDescendants()) do
                if descendant:IsA("WeldConstraint") then
                    descendant:Destroy()
                end
            end
            
            task.delay(3, function()
                self.chest:Destroy()
                if self.anchor then
                    self.anchor:Destroy()
                end
            end)
    
            if self.destroyToResetCondition then
                if self.ResetConditionDelayTime[1] > 0 and self.ResetConditionDelayTime[2] > 0 then
                    local delay = math.random(self.ResetConditionDelayTime[1], self.ResetConditionDelayTime[2])
                    task.delay(delay, function()
                        self.condition:Reset()
                    end)
                end
            end
        end)
    end

    self.chest = game.ServerStorage:WaitForChild("Chest"):Clone()
    self.chest:PivotTo(CFrame.new(self.position))
    self.chest.Parent = workspace
    self.chest.PrimaryPart.CanCollide = true
    self:CreateAnchor()
    self.isTouched = false
    
    -- 如果Model设置了PrimaryPart
    if self.chest.PrimaryPart then
        self.chest.PrimaryPart.Touched:Connect(function(hit)
            if self.isTouched then return end
            -- 检测玩家碰撞
            local model = hit:FindFirstAncestorOfClass("Model")
            if not model then return end

            -- 检测船只碰撞
           if  model.Name:match("^PlayerBoat_") then
               local userIdStr = model.Name:match("^PlayerBoat_(%d+)$")
               if userIdStr then
                   local userId = tonumber(userIdStr)
                   local boatOwner = game.Players:GetPlayerByUserId(userId)
                   if boatOwner then
                       print("船只触发宝箱:", boatOwner.Name, "的船")
                       ChestTouched()
                       return
                   end
               end
           end

            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid then
                local player = game.Players:GetPlayerFromCharacter(model)
                if player then
                    print("玩家触发宝箱:", player.Name)
                    ChestTouched()
                    return
                end
            end
        end)
    end
end

function CreateChestAction:Destroy()
    ActionBase.Destroy(self)
    
    if self.chest then
        self.chest:Destroy()
    end
    if self.anchor then
        self.anchor:Destroy()
    end
end

return CreateChestAction