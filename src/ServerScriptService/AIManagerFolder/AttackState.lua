local AttackState = {}
AttackState.__index = AttackState

-- 攻击状态
function AttackState.new(AIManager)
    local self = setmetatable({}, AttackState)
    self.AIManager = AIManager
    return self
end

function AttackState:Enter()
    print("进入Attack状态")
    self.timer = 3
    self.isFirst = true
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        local HumanoidRootPart = self.AIManager.NPC:FindFirstChild('HumanoidRootPart')
        if not HumanoidRootPart then
            print("HumanoidRootPart not found")
            return
        end

        local target = self.AIManager.target
        if not target then
            self.AIManager:SetState("Idle")
            return
        end

        self.timer = self.timer - dt
        if not self.isFirst and self.timer > 0 then
            local targetPosition = nil
            local modelType = target:GetAttribute("ModelType")
            if modelType == "Boat" then
                if not target:GetAttribute("Destroying") and target.PrimaryPart then
                    targetPosition = target.PrimaryPart.CFrame.Position
                end
            elseif modelType == "Player" then
                local targetHumanoidRootPart = target:FindFirstChild('HumanoidRootPart')
                local targetHumanoid = target:FindFirstChild('Humanoid')
                if targetHumanoidRootPart and targetHumanoid and targetHumanoid.Health > 0 then
                    targetPosition = targetHumanoidRootPart.CFrame.Position
                end
            end
    
            if not targetPosition then
                self.AIManager:SetState("Idle")
                return
            end
            local currentPos = HumanoidRootPart.CFrame.Position
            HumanoidRootPart.CFrame = CFrame.new(currentPos, targetPosition)
            return
        end

        print('正在攻击')
        self.isFirst = false
        self.timer = 3

        local currentPos = HumanoidRootPart.CFrame.Position
        local attackRange = self.AIManager.NPC:GetAttribute("AttackRange")
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = {self.AIManager.target}
        local parts = workspace:GetPartBoundsInRadius(currentPos, attackRange, params) or {}
        if #parts == 0 then
            self.AIManager:SetState("Idle")
            return
        end

        local modelType = target:GetAttribute("ModelType")
        if modelType == "Boat" and target:GetAttribute("Destroying") then
            self.AIManager:SetState("Idle")
            return
        elseif modelType == "Player" and (not target.HumanoidRootPart or not target.Humanoid or target.Humanoid.Health <= 0) then
            self.AIManager:SetState("Idle")
            return
        end

        -- 播放攻击动画
        -- local animateScript = self.AIManager.NPC:FindFirstChild("Animate")
        -- if animateScript then
        --     animateScript.Attack:Fire()
        -- end
        
        if modelType == "Boat" then
            local boatHealth = target:GetAttribute("Health")
            target:SetAttribute("Health", boatHealth - 10)
        elseif modelType == "Player" then
            local humanoid = target:FindFirstChild("Humanoid")
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
    print("退出Attack状态")
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.attackConnection then
        self.attackConnection:Disconnect()
        self.attackConnection = nil
    end
    self.AIManager.target = nil
    --self.proximityPrompt:Destroy()
end

return AttackState