local ReplicatedStorage = game.ReplicatedStorage
local ServerStorage = game:GetService("ServerStorage")
local MonsterConfig = require(script.Parent:WaitForChild("MonsterConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local AIManager = {}
AIManager.__index = AIManager

function AIManager.new(name, position, isWaterMonster, deadCallFunc)
    local self = setmetatable({}, AIManager)
    self.deadCallFunc = deadCallFunc
    
    -- 保存原始NPC克隆体
    self.NPC = ServerStorage:FindFirstChild(name):Clone()
    if isWaterMonster then
        local isHasPart, foundParts = Interface.CheckPosHasPart(position, self.NPC:GetExtentsSize())
        if isHasPart then
            print("位置有物体，取消创建")
            self.NPC:Destroy()
            return
        end
    end

    self.NPC.HumanoidRootPart.CFrame = CFrame.new(position, self.NPC.HumanoidRootPart.CFrame.LookVector)
    for _, part in ipairs(self.NPC:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup = "MonsterCollisionGroup"
        end
    end
    self.NPC.Parent = workspace
    self.target = nil
    self.Humanoid = self.NPC:FindFirstChildOfClass('Humanoid')
    if not self.Humanoid then
        error("NPC模型必须包含Humanoid组件")
    end
    
    self:InitializeAttributes(name)

    self.CurrentState = nil
    self.States = {
        Idle = require(script.Parent:WaitForChild("IdleState")).new(self),
        Patrol = require(script.Parent:WaitForChild("PatrolState")).new(self),
        Attack = require(script.Parent:WaitForChild("AttackState")).new(self),
        Dead = require(script.Parent:WaitForChild("DeadState")).new(self),
        Chase = require(script.Parent:WaitForChild("ChaseState")).new(self),
    }

    -- 监听死亡状态
    self.Humanoid.Died:Connect(function()
        print("怪物死亡")
        self:SetState("Dead")
        if self.deadCallFunc then
            self.deadCallFunc()
        end
    end)
    return self
end

function AIManager:InitializeAttributes(name)
    local config = MonsterConfig[name]
    if config then
        self.NPC:SetAttribute('Type', config.Type)
        self.NPC:SetAttribute('VisionRange', config.VisionRange)
        self.NPC:SetAttribute('AttackRange', config.AttackRange)
        self.NPC:SetAttribute('Damage', config.Damage)
        self.NPC:SetAttribute('PatrolRadius', config.PatrolRadius)
        self.NPC:SetAttribute('RespawnTime', config.RespawnTime)
        self.NPC:SetAttribute("MaxDisForSpawn", config.MaxDisForSpawn)
        self.NPC:SetAttribute("SpawnPosition", self.NPC.PrimaryPart.CFrame.Position)
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
end

function AIManager:Destroy()
    -- 清理AI实例相关资源
    self.NPC:Destroy()
    self.States = nil
    if self.CurrentState then
        self.CurrentState:Exit()
        self.CurrentState = nil
    end
end

return AIManager