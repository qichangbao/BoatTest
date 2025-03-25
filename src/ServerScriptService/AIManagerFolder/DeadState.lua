local DeadState = {}
DeadState.__index = DeadState

function DeadState.new(controller)
    local self = setmetatable({}, DeadState)
    self.Controller = controller
    return self
end

function DeadState:Enter()
    -- 销毁原有NPC
    -- 保存原始属性后立即销毁
    local originalHealth = self.Controller.NPC:GetAttribute("Health")
    local spawnPosition = self.Controller.NPC:GetAttribute("SpawnPosition")
    self.Controller.NPC:Destroy()

    -- 统一重生处理
    local function respawnNPC()
        local newNPC = self.Controller.NPCClone:Clone()
        newNPC:SetAttribute("Health", originalHealth)
        newNPC:PivotTo(CFrame.new(spawnPosition))
        newNPC.Parent = workspace

        -- 初始化新控制器
        local newController = require(newNPC.Parent.AIController).new(newNPC)
        newController:Start()
        return newNPC
    end

    local npcClone
    -- 延迟重生
    task.delay(self.Controller.NPC:GetAttribute("RespawnTime"), function()
        local newNPC = respawnNPC()
        if newNPC then
            npcClone = newNPC  -- 添加local限定符
        end
    end)
    -- 播放死亡动画
    local animateScript = self.Controller.NPC:FindFirstChild("Animate")
    if animateScript and animateScript:FindFirstChild("Death") then
        animateScript.Death:Fire()
    end
    
    -- 禁用碰撞和移动
    self.Controller.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    self.Controller.Humanoid.WalkSpeed = 0
    
    -- 触发物品掉落
    local monsterType = self.Controller.NPC:GetAttribute("MonsterType")
    local success, MonsterConfig = pcall(require, self.Controller.NPC.Parent.MonsterConfig)
    local config = success and MonsterConfig[monsterType] or {Drops = {}}
    if not success then
        warn("[MonsterConfig] 配置加载失败:", MonsterConfig)
    end
    
    if config and config.Drops then
        local npcPosition = self.Controller.NPC:GetPivot().Position
        
        for _, drop in ipairs(config.Drops) do
            if math.random() <= drop.Chance then
                local dropPart = Instance.new("Part")
                dropPart.Size = Vector3.new(1,1,1)
                dropPart.Position = npcPosition + drop.Offset
                dropPart.Anchored = true
                dropPart.BrickColor = BrickColor.Random()
                dropPart.Parent = workspace
                
                local tag = Instance.new("StringValue")
                tag.Name = "ItemType"
                tag.Value = drop.ItemId
                tag.Parent = dropPart
            end
        end
    end
    
    -- 尸体保留计时
    self.deathTimer = 5
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.deathTimer = self.deathTimer - dt
        if self.deathTimer <= 0 then
            if npcClone and npcClone.Parent then
                npcClone:Destroy()
            end
            self.Controller.NPC = nil
        end
    end)
end

function DeadState:Exit()
    if self.connection then
        self.connection:Disconnect()
    end
end

return DeadState