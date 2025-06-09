print("加载CreateChestAction")
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))

local CreateChestAction = {}
setmetatable(CreateChestAction, ActionBase)
CreateChestAction.__index = CreateChestAction

function CreateChestAction.new(config, condition)
    local self = setmetatable(ActionBase.new(config, condition), CreateChestAction)
    self.destroyToResetCondition = config.DestroyToResetCondition or false
    self.ResetConditionDelayTime = config.ResetConditionDelayTime or {0, 0}
    self.chests = {}
    self.anchors = {}
    self.isToucheds = {}
    return self
end

function CreateChestAction:CreateAnchor(chest)
    -- 创建一个不可见的锚点
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Position = chest.PrimaryPart.Position
    anchor.Parent = workspace
    table.insert(self.anchors, anchor)

    -- 创建 Attachment
    local chestAttachment = Instance.new("Attachment")
    chestAttachment.Parent = chest.PrimaryPart

    local anchorAttachment = Instance.new("Attachment")
    anchorAttachment.Parent = anchor

    -- 位置对齐（只限制Y轴）
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Attachment0 = chestAttachment
    alignPosition.Attachment1 = anchorAttachment
    alignPosition.MaxForce = 4000
    alignPosition.Responsiveness = 10
    alignPosition.RigidityEnabled = false
    alignPosition.Parent = chest.PrimaryPart

    -- 方向对齐（防止翻滚）
    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Attachment0 = chestAttachment
    alignOrientation.Attachment1 = anchorAttachment
    alignOrientation.MaxTorque = 4000
    alignOrientation.Responsiveness = 10
    alignOrientation.RigidityEnabled = true
    alignOrientation.Parent = chest.PrimaryPart

    return anchor
end

-- local function PlayOpenChestAni(chest, callback)
--     local TweenService = game:GetService("TweenService")
--     local chestTop = chest:FindFirstChild("ChestTop")
    
--     if not chestTop then
--         warn("找不到箱盖模型，请确保箱子中有名为 'ChestTop' 的模型")
--         return
--     end
    
--     -- 确保chestTop有PrimaryPart
--     if not chestTop.PrimaryPart then
--         warn("ChestTop模型没有设置PrimaryPart，请在Studio中设置")
--         return
--     end
    
--     -- 获取当前位置和目标位置
--     local currentCFrame = chestTop:GetPivot()
--     local targetCFrame = currentCFrame * CFrame.Angles(0, 0, math.rad(-90))
    
--     -- 创建动画
--     local tweenInfo = TweenInfo.new(
--         1.5, -- 持续时间
--         Enum.EasingStyle.Quad,
--         Enum.EasingDirection.Out
--     )
    
--     -- 创建一个NumberValue用于动画进度
--     local animationProgress = Instance.new("NumberValue")
--     animationProgress.Value = 0
    
--     -- 创建Tween
--     local tween = TweenService:Create(animationProgress, tweenInfo, {Value = 1})
    
--     -- 监听动画进度
--     animationProgress.Changed:Connect(function(alpha)
--         local lerpedCFrame = currentCFrame:Lerp(targetCFrame, alpha)
--         chestTop:PivotTo(lerpedCFrame)
--     end)
    
--     -- 播放动画
--     tween:Play()
    
--     -- 清理
--     tween.Completed:Connect(function()
--         animationProgress:Destroy()
--         callback()
--     end)
-- end

function CreateChestAction:Execute(data)
    ActionBase.Execute(self)

    print("执行CreateChestAction")
    
    -- 确定宝箱生成位置
    local position = self.position
    if self.config.UsePlayerPosition and self.config.PositionOffset and data and data.Player and data.Player.Character then
        local player = data.Player
        local frame = player.Character:GetPivot()
        position = frame.Position
        local baseOffset = frame.LookVector * self.config.PositionOffset -- 船头前方偏移
        
        -- 添加小范围随机偏移 (-5到5米的随机范围)
        local randomX = math.random(-100, 100)
        local randomZ = math.random(-100, 100)
        local randomOffset = Vector3.new(randomX, 1.5, randomZ)
        
        position = Vector3.new(position.X + baseOffset.X + randomOffset.X, randomOffset.Y, position.Z + baseOffset.Z + randomOffset.Z)
    end

    local function ChestTouched(player, chest, anchor)
        self.isToucheds[chest] = true
        chest.PrimaryPart.Anchored = false
        
        -- 遍历宝箱中的所有WeldConstraint并移除
        for _, descendant in pairs(chest:GetDescendants()) do
            if descendant:IsA("WeldConstraint") then
                descendant:Destroy()
            end
        end
        -- 遍历宝箱中的所有WeldConstraint并移除
        for _, descendant in pairs(chest.PrimaryPart:GetDescendants()) do
            descendant:Destroy()
        end
        if anchor then
            anchor:Destroy()
        end

        if self.destroyToResetCondition then
            if self.ResetConditionDelayTime[1] > 0 and self.ResetConditionDelayTime[2] > 0 then
                local delay = math.random(self.ResetConditionDelayTime[1], self.ResetConditionDelayTime[2])
                task.delay(delay, function()
                    if self.condition then
                        self.condition:Reset()
                    end
                end)
            end
        end
        
        -- 处理宝箱奖励
        local Knit = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
        local ChestService = Knit.GetService('ChestService')
        if ChestService and ChestService.ProcessChestRewards then
            local chestPosition = chest.PrimaryPart.Position
            ChestService:ProcessChestRewards(player, chestPosition)
        end
    end

    local chest = game.ServerStorage:WaitForChild("Chest"):Clone()
    table.insert(self.chests, chest)
    chest:PivotTo(CFrame.new(position))
    chest.Parent = workspace
    chest.PrimaryPart.Anchored = true
    local anchor = self:CreateAnchor(chest)
    -- 遍历宝箱中的所有WeldConstraint并移除
    for _, descendant in pairs(chest:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
        end
    end
    
    self.isToucheds[chest] = false
    -- 如果Model设置了PrimaryPart
    if chest.PrimaryPart then
        chest.PrimaryPart.Touched:Connect(function(hit)
            if self.isToucheds[chest]  then return end
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
                       ChestTouched(boatOwner, chest, anchor)
                       return
                   end
               end
           end

            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid then
                local player = game.Players:GetPlayerFromCharacter(model)
                if player then
                    print("玩家触发宝箱:", player.Name)
                    ChestTouched(player, chest, anchor)
                    return
                end
            end
        end)
    end

    task.delay(self.config.Lifetime, function()
        chest:Destroy()
        self.isToucheds[chest] = nil
    end)
end

return CreateChestAction