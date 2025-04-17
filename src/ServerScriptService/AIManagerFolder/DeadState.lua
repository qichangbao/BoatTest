local DeadState = {}
DeadState.__index = DeadState

-- 死亡状态
function DeadState.new(AIManager)
    local self = setmetatable({}, DeadState)
    self.AIManager = AIManager
    return self
end

function DeadState:Enter()
    print("进入Dead状态")
    -- 销毁原有NPC
    self.AIManager.NPC:Destroy()

    -- 播放死亡动画
    local animateScript = self.AIManager.NPC:FindFirstChild("Animate")
    if animateScript and animateScript:FindFirstChild("Death") then
        animateScript.Death:Fire()
    end
    
    -- 禁用碰撞和移动
    self.AIManager.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    self.AIManager.Humanoid.WalkSpeed = 0
    
    -- 触发物品掉落
    local monsterType = self.AIManager.NPC:GetAttribute("MonsterType")
    local success, MonsterConfig = pcall(require, self.AIManager.NPC.Parent.MonsterConfig)
    local config = success and MonsterConfig[monsterType] or {Drops = {}}
    if not success then
        warn("[MonsterConfig] 配置加载失败:", MonsterConfig)
    end
    
    if config and config.Drops then
        local npcPosition = self.AIManager.NPC:GetPivot().Position
        
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
end

function DeadState:Exit()
end

return DeadState