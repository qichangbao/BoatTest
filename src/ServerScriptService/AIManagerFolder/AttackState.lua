local AttackState = {}
AttackState.__index = AttackState

function AttackState.new(controller)
    local self = setmetatable({}, AttackState)
    self.Controller = controller
    self.proximityPrompt = Instance.new("ProximityPrompt")
    self.proximityPrompt.HoldDuration = 0
    self.proximityPrompt.MaxActivationDistance = self.Controller.NPC:GetAttribute("AttackRange")
    self.attributeListener = self.Controller.NPC:GetAttributeChangedSignal("AttackRange"):Connect(function()
        self.proximityPrompt.MaxActivationDistance = self.Controller.NPC:GetAttribute("AttackRange")
    end)
    self.proximityPrompt.Parent = self.Controller.Humanoid.RootPart
    return self
end

function AttackState:Exit()
    if self.attackConnection then
        self.attackConnection:Disconnect()
    end
    if self.attributeListener then
        self.attributeListener:Disconnect()
    end
    self.proximityPrompt:Destroy()
end

function AttackState:Enter()
    self.attackConnection = self.proximityPrompt.Triggered:Connect(function(player)
        if self.Controller.Humanoid.Health > 0 then
            -- 播放攻击动画
            local animateScript = self.Controller.NPC:FindFirstChild("Animate")
            if animateScript then
                animateScript.Attack:Fire()
            end
            
            -- 伤害判定逻辑
            local hitbox = self.Controller.NPC:FindFirstChild("Hitbox")
            if hitbox then
                hitbox.Touched:Connect(function(hit)
                    local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid ~= self.Controller.Humanoid then
                        humanoid:TakeDamage(10)
                    end
                end)
            end
        end
    end)
end



return AttackState