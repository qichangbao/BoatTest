local AIController = {}
AIController.__index = AIController

function AIController.new(npcModel)
    local self = setmetatable({}, AIController)
    
    -- 保存原始NPC克隆体
    self.NPCClone = npcModel:Clone()
    self.NPC = npcModel
    self.Humanoid = npcModel:FindFirstChildOfClass('Humanoid')
    if not self.Humanoid then
        error("NPC模型必须包含Humanoid组件")
    end
    self.CurrentState = nil
    self.States = {
        Idle = require(script.Parent:WaitForChild("IdleState")).new(self),
        Patrol = require(script.Parent:WaitForChild("PatrolState")).new(self),
        Attack = require(script.Parent:WaitForChild("AttackState")).new(self),
        Dead = require(script.Parent:WaitForChild("DeadState")).new(self),
        Chase = require(script.Parent:WaitForChild("ChaseState")).new(self),
    }
    
    self:InitializeAttributes()
    return self
end

function AIController:InitializeAttributes()
    -- 确保关键属性存在
    self.NPC:SetAttribute("VisionRange", self.NPC:GetAttribute("VisionRange") or 50)
    self.NPC:SetAttribute("AttackRange", self.NPC:GetAttribute("AttackRange") or 10)
    
    local success, MonsterConfig = pcall(function()
        return require(script.Parent:WaitForChild("MonsterConfig"))
    end)
    
    if success then
        local monsterType = self.NPC:GetAttribute("MonsterType") or "Zombie"
        local config = MonsterConfig[monsterType]
        
        if config then
            self.NPC:SetAttribute('Health', config.Health)
            self.NPC:SetAttribute('WalkSpeed', config.WalkSpeed)
            self.NPC:SetAttribute('VisionRange', config.VisionRange)
            self.NPC:SetAttribute('AttackRange', config.AttackRange)
            self.NPC:SetAttribute('PatrolRadius', config.PatrolRadius)
            self.NPC:SetAttribute('RespawnTime', config.RespawnTime)
        else
            warn("未找到怪物配置:", monsterType)
        end
    else
        warn("加载MonsterConfig失败:", MonsterConfig)
    end
end

function AIController:SetState(newState)
    if self.CurrentState then
        self.CurrentState:Exit()
    end
    
    self.CurrentState = self.States[newState]
    self.CurrentState:Enter()
end

function AIController:Start()
    self:SetState('Idle')
    self.Humanoid.Died:Connect(function()
        self:SetState('Dead')
    end)
end

return AIController