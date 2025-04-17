local PatrolState = {}
PatrolState.__index = PatrolState

-- 巡逻状态
function PatrolState.new(AIManager)
    local self = setmetatable({}, PatrolState)
    self.AIManager = AIManager
    self.Path = game:GetService("PathfindingService"):CreatePath()
    return self
end

function PatrolState:Enter()
    print("进入Patrol状态")
    local center = self.AIManager.NPC:GetPivot().Position
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    local patrolRadius = self.AIManager.NPC:GetAttribute("PatrolRadius")
    
    local targetPosition = center + Vector3.new(
        math.random(-patrolRadius, patrolRadius),
        0,
        math.random(-patrolRadius, patrolRadius)
    )
    
    self.Path:ComputeAsync(self.AIManager.Humanoid.RootPart.Position, targetPosition)
    
    if self.Path.Status == Enum.PathStatus.Success then
        self.waypoints = self.Path:GetWaypoints()
        self.currentWaypoint = 2
        self.connection = self.AIManager.Humanoid.MoveToFinished:Connect(function(reached) 
            if reached and self.currentWaypoint <= #self.waypoints then
                self.AIManager.Humanoid:MoveTo(self.waypoints[self.currentWaypoint].Position)
                self.currentWaypoint += 1
            else
                self.AIManager:SetState("Chase")
                return
            end
        end)
        
        self.detectionConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            local npcPos = self.AIManager.Humanoid.RootPart.Position
            local cframe = CFrame.new(npcPos)
            local size = Vector3.new(visionRange, visionRange, visionRange)
            local params = OverlapParams.new()
            params.FilterDescendantsInstances = {self.AIManager.NPC}
            local parts = workspace:GetPartBoundsInBox(cframe, size, params)
            for _, part in ipairs(parts) do
                local character = part.Parent
                local target = game.Players:GetPlayerFromCharacter(character)
                if target and target.Character and target.Character.HumanoidRootPart and not target.Character.Humanoid.Died then
                    self.AIManager:SetState("Chase")
                    return
                end
            end
        end)
        
        self.AIManager.Humanoid:MoveTo(self.waypoints[1].Position)
    else
        self.AIManager:SetState("Chase")
        return
    end
end

function PatrolState:Exit()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.detectionConnection then
        self.detectionConnection:Disconnect()
        self.detectionConnection = nil
    end
    self.AIManager.Humanoid:MoveTo(self.AIManager.Humanoid.RootPart.Position)
end


return PatrolState