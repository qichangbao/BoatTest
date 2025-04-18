local ChaseState = {}
ChaseState.__index = ChaseState

-- 追赶状态
function ChaseState.new(AIManager)
    local self = setmetatable({}, ChaseState)
    self.AIManager = AIManager
    self.Path = game:GetService("PathfindingService"):CreatePath()
    self.spawnPosition = AIManager.NPC:GetAttribute("SpawnPosition")
    return self
end

function ChaseState:Enter()
    print("进入Chase状态")
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:CheckDistance()
    end)

    local nearestPos = self:FindNearestModel()
    if nearestPos then
        self:UpdatePath(nearestPos)
        return
    end

    self.AIManager:SetState("Idle")
    return
end

function ChaseState:FindNearestModel()
    local npcPos = self.AIManager.Humanoid.RootPart.Position
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {self.AIManager.NPC}
    local parts = workspace:GetPartBoundsInRadius(npcPos, visionRange, params) or {}
    
    local nearestModelPos = nil
    local minDistance = math.huge
    for _, part in ipairs(parts) do
        local character = part.Parent
        local modelType = character:GetAttribute("ModelType")
        if modelType == "Boat" and not character:GetAttribute("Destroying") then
            local pos = character:GetPivot().Position
            local distance = (pos - npcPos).Magnitude
            if distance < minDistance then
                self.AIManager.target = character
                nearestModelPos = pos
                minDistance = distance
            end
        elseif modelType == "Player" and character.HumanoidRootPart and character.Humanoid and character.Humanoid.Health > 0 then
            local pos = character.HumanoidRootPart.Position
            local distance = (pos - npcPos).Magnitude
            if distance < minDistance then
                self.AIManager.target = character
                nearestModelPos = pos
                minDistance = distance
            end
        end
    end
    return nearestModelPos
end

function ChaseState:CheckDistance()
    if not self.AIManager.target then
        return
    end

    local currentPos = self.AIManager.Humanoid.RootPart.Position
    local distanceToPlayer = 0
    local modelType = self.AIManager.target:GetAttribute("ModelType")
    if modelType == "Boat" then
        if self.AIManager.target:GetAttribute("Destroying") then
            self.AIManager:SetState("Idle")
            return
        else
            distanceToPlayer = (self.AIManager.target:GetPivot().Position - currentPos).Magnitude
        end
    elseif modelType == "Player" then
        if self.AIManager.target.HumanoidRootPart and self.AIManager.target.Humanoid and self.AIManager.target.Humanoid.Health > 0 then
            distanceToPlayer = (self.AIManager.target:GetPivot().Position - currentPos).Magnitude
        else
            self.AIManager:SetState("Idle")
            return
        end
    end
    
    local attackRange = self.AIManager.NPC:GetAttribute("AttackRange")
    if distanceToPlayer <= attackRange then
        self.AIManager:SetState("Attack")
        return
    end
end

function ChaseState:UpdatePath(targetPos)
    self.AIManager.Humanoid:MoveTo(targetPos)
    -- 监听到达事件
    self.moveToFinished = self.AIManager.Humanoid.MoveToFinished:Connect(function(reached)
        if not reached then
            self.AIManager.NPC:MoveTo(targetPos)
        end
    end)
    
    -- self.Path:ComputeAsync(self.AIManager.Humanoid.RootPart.Position, targetPos)
    -- if self.Path.Status == Enum.PathStatus.Success then
    --     self.waypoints = self.Path:GetWaypoints()
    --     self.currentWaypointIndex = 2
        
    --     if self.currentWaypointIndex <= #self.waypoints then
    --         local nextWaypoint = self.waypoints[self.currentWaypointIndex]
    --         --self.AIManager.Humanoid:MoveTo(nextWaypoint.Position)
    --         self.AIManager.Humanoid:MoveTo(targetPos)
    --         -- 监听到达事件
    --         self.moveToFinished = self.AIManager.Humanoid.MoveToFinished:Connect(function(reached)
    --             if self.currentWaypointIndex <= #self.waypoints then
    --                 self.currentWaypointIndex = self.currentWaypointIndex + 1
    --                 nextWaypoint = self.waypoints[self.currentWaypointIndex]
    --                 self.AIManager.NPC:MoveTo(nextWaypoint.Position)
    --             end
    --         end)
    --     else
    --         -- 到达终点返回空闲状态
    --         self.AIManager:SetState("Idle")
    --         return
    --     end
    -- else
    --     self.AIManager:SetState("Idle")
    --     return
    -- end
end

function ChaseState:Exit()
    if self.moveConnection then
        self.moveConnection:Disconnect()
        self.moveConnection = nil
    end
    if self.moveToFinished then
        self.moveToFinished:Disconnect()
        self.moveToFinished = nil
    end
    self.currentWaypointIndex = nil
    self.waypoints = nil
    print("退出Chase状态")
end

return ChaseState