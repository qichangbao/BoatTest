local AttackState = {}
AttackState.__index = AttackState

-- 攻击状态
function AttackState.new(AIManager)
    local self = setmetatable({}, AttackState)
    self.AIManager = AIManager
    self.proximityPrompt = Instance.new("ProximityPrompt")
    self.proximityPrompt.HoldDuration = 0
    self.proximityPrompt.MaxActivationDistance = self.AIManager.NPC:GetAttribute("AttackRange")
    self.proximityPrompt.Parent = self.AIManager.Humanoid.RootPart
    return self
end

function AttackState:Enter()
    print("进入Attack状态")
    self.attackConnection = self.proximityPrompt.Triggered:Connect(function(player)
        if self.AIManager.Humanoid.Health > 0 then
            -- 播放攻击动画
            local animateScript = self.AIManager.NPC:FindFirstChild("Animate")
            if animateScript then
                animateScript.Attack:Fire()
            end
            
            -- 伤害判定逻辑
            local hitbox = self.AIManager.NPC:FindFirstChild("Hitbox")
            if hitbox then
                hitbox.Touched:Connect(function(hit)
                    local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid ~= self.AIManager.Humanoid then
                        humanoid:TakeDamage(10)
                    end
                end)
            end
        end
    end)
end

function AttackState:Exit()
    if self.attackConnection then
        self.attackConnection:Disconnect()
    end
    self.proximityPrompt:Destroy()
end

return AttackState