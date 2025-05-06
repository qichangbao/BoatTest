local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PatrolState = {}
PatrolState.__index = PatrolState

local HEARTBEAT_SPACE = 1       -- 每秒执行一次

-- 巡逻状态
function PatrolState.new(AIManager)
    local self = setmetatable({}, PatrolState)
    self.AIManager = AIManager
    self.Path = game:GetService("PathfindingService"):CreatePath()
    return self
end

function PatrolState:Enter()
    print("进入Patrol状态")
    local npcPos = self.AIManager.NPC.HumanoidRootPart.CFrame.Position
    local maxDisForSpawn = self.AIManager.NPC:GetAttribute("MaxDisForSpawn")
    local patrolRadius = self.AIManager.NPC:GetAttribute("PatrolRadius")
    local spawnPosition = self.AIManager.NPC:GetAttribute("SpawnPosition")
    local targetPosition
    if (spawnPosition - npcPos).Magnitude > maxDisForSpawn then
        targetPosition = spawnPosition
    else
        targetPosition = npcPos + Vector3.new(
            math.random(-patrolRadius, patrolRadius),
            0,
            math.random(-patrolRadius, patrolRadius)
        )
    end

    self.timer = HEARTBEAT_SPACE
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        -- 计算移动方向
        local HumanoidRootPart = self.AIManager.NPC:FindFirstChild('HumanoidRootPart')
        if not HumanoidRootPart then
            print("HumanoidRootPart not found")
            return
        end
        
        local currentPos = HumanoidRootPart.CFrame.Position
        -- 检测是否到达目标点
        if (currentPos - targetPosition).Magnitude < 1 then
            self.AIManager:SetState("Idle")
            return
        end

        local direction = (targetPosition - currentPos).Unit
        local speed = self.AIManager.Humanoid.WalkSpeed * dt
        local newPos = currentPos + direction * speed
        
        -- 实时检测障碍
        local raycastParams = RaycastParams.new()
        raycastParams.IgnoreWater = true
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {self.AIManager.NPC}
        local ray = workspace:Raycast(currentPos, (newPos - currentPos) * 20, raycastParams)
        if ray then
            self.AIManager:SetState("Idle")
            return
        end

        -- 更新位置和方向
        HumanoidRootPart.CFrame = CFrame.new(newPos, targetPosition)

        -- self.timer = self.timer - dt
        -- if self.timer <= 0 then
        --     local boats = CollectionService:GetTagged("Boat")
        --     for _, v in ipairs(boats) do
        --         if not v:GetAttribute("Destroying") then
        --             local dis = (v.PrimaryPart.CFrame.Position - npcPos).Magnitude
        --             if dis <= visionRange then
        --                 self.AIManager:SetState("Chase")
        --                 return
        --             end
        --         end
        --     end
    
        --     for _, v in ipairs(Players:GetPlayers()) do
        --         local character = v.character
        --         if character then
        --             local HumanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        --             local Humanoid = character:FindFirstChild('Humanoid')
        --             if HumanoidRootPart and Humanoid and Humanoid.Health > 0 then
        --                 local dis = (character.HumanoidRootPart.Position - npcPos).Magnitude
        --                 if dis <= visionRange then
        --                     self.AIManager:SetState("Chase")
        --                     return
        --                 end
        --             end
        --         end
        --     end
        --     self.timer = HEARTBEAT_SPACE
        -- end
    end)
end

function PatrolState:Exit()
    print("退出Patrol状态")
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end


return PatrolState