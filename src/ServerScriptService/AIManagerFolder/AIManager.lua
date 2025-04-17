
local ServerStorage = game:GetService("ServerStorage")
local MonsterConfig = require(script.Parent:WaitForChild("MonsterConfig"))

local AIManager = {}
AIManager.__index = AIManager

function AIManager.new(name, position)
    local self = setmetatable({}, AIManager)
    
    -- 保存原始NPC克隆体
    self.NPC = ServerStorage:WaitForChild(name):Clone()
    self.NPC:PivotTo(CFrame.new(position))
    self.NPC.Parent = workspace
    
    self:InitializeAttributes(name)

    -- 初始化状态
    self.Humanoid = self.NPC:FindFirstChildOfClass('Humanoid')
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
    return self
end

function AIManager:InitializeAttributes(name)
    local config = MonsterConfig[name]
    if config then
        self.NPC:SetAttribute('Type', config.Type)
        self.NPC:SetAttribute('VisionRange', config.VisionRange)
        self.NPC:SetAttribute('AttackRange', config.AttackRange)
        self.NPC:SetAttribute('PatrolRadius', config.PatrolRadius)
        self.NPC:SetAttribute('RespawnTime', config.RespawnTime)
        self.NPC:SetAttribute("SpawnPosition", self.NPC:GetPivot().Position)
        self.NPC.Humanoid.MaxHealth = config.Health
        self.NPC.Humanoid.Health = config.Health
        self.NPC.Humanoid.WalkSpeed = config.WalkSpeed
    else
        warn("未找到怪物配置:", name)
    end
end

function AIManager:SetState(newState)
    if self.CurrentState then
        self.CurrentState:Exit()
    end
    
    self.CurrentState = self.States[newState]
    self.CurrentState:Enter()
end

function AIManager:Start()
    self:SetState('Idle')
    self.Humanoid.Died:Connect(function()
        self:SetState('Dead')
        task.wait(10)
        self.NPC = nil
        self.CurrentState = nil
        for i, v in pairs(self.States) do
            v:Exit()
        end
        self:Destroy()
    end)
end

return AIManager