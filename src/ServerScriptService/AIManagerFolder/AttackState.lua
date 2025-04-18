local AttackState = {}
AttackState.__index = AttackState

-- 攻击状态
function AttackState.new(AIManager)
    local self = setmetatable({}, AttackState)
    self.AIManager = AIManager
    -- self.proximityPrompt = Instance.new("ProximityPrompt")
    -- self.proximityPrompt.HoldDuration = 0
    -- self.proximityPrompt.MaxActivationDistance = self.AIManager.NPC:GetAttribute("AttackRange")
    -- self.proximityPrompt.Parent = self.AIManager.Humanoid.RootPart
    return self
end

function AttackState:Enter()
    print("进入Attack状态")
    self.timer = 3
    self.isFirst = true
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.timer = self.timer - dt
        if not self.isFirst and self.timer > 0 then
            return
        end
        self.isFirst = false
        self.timer = 3
        if self.AIManager.Humanoid.Health > 0 then
            local target = self.AIManager.target
            if not target then
                self.AIManager:SetState("Idle")
                return
            end
            -- 检查距离
            local npcPos = self.AIManager.Humanoid.RootPart.Position
            local targetPos = target:GetPivot().Position
            local distance = (targetPos - npcPos).Magnitude
            if distance > self.AIManager.NPC:GetAttribute("AttackRange") then
                self.AIManager:SetState("Chase")
                return
            end

            -- 播放攻击动画
            -- local animateScript = self.AIManager.NPC:FindFirstChild("Animate")
            -- if animateScript then
            --     animateScript.Attack:Fire()
            -- end
            
            local modelType = target:GetAttribute("ModelType")
            if modelType == "Boat" then
                local boatHealth = target:GetAttribute("Health")
                target:SetAttribute("Health", boatHealth - 10)
            elseif modelType == "Player" then
                local humanoid = target.Humanoid
                if humanoid and humanoid.Health > 0 then
                    humanoid:TakeDamage(10)
                end
            end
            -- local hitbox = self.AIManager.NPC:FindFirstChild("Hitbox")
            -- if hitbox then
            --     hitbox.Touched:Connect(function(hit)
            --         local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            --         if humanoid and humanoid ~= self.AIManager.Humanoid then
            --             humanoid:TakeDamage(10)
            --         end
            --     end)
            -- end
        end
    end)
    -- self.attackConnection = self.proximityPrompt.Triggered:Connect(function(player)
    --     if self.AIManager.Humanoid.Health > 0 then
    --         -- 播放攻击动画
    --         local animateScript = self.AIManager.NPC:FindFirstChild("Animate")
    --         if animateScript then
    --             animateScript.Attack:Fire()
    --         end
            
    --         -- 伤害判定逻辑
    --         local hitbox = self.AIManager.NPC:FindFirstChild("Hitbox")
    --         if hitbox then
    --             hitbox.Touched:Connect(function(hit)
    --                 local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
    --                 if humanoid and humanoid ~= self.AIManager.Humanoid then
    --                     humanoid:TakeDamage(10)
    --                 end
    --             end)
    --         end
    --     end
    -- end)
end

function AttackState:Exit()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.attackConnection then
        self.attackConnection:Disconnect()
        self.attackConnection = nil
    end
    --self.proximityPrompt:Destroy()
end

return AttackState