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
        local target = self:FindNearestPlayer()
        if target and target.Character and target.Character.HumanoidRootPart and not target.Character.Humanoid.Died then
            self:UpdatePath(target.Character.HumanoidRootPart.Position)
            self:CheckDistance(target)
        else
            self.AIManager:SetState("Idle")
            return
        end
    end)
end

function ChaseState:FindNearestPlayer()
    local npcPos = self.AIManager.Humanoid.RootPart.Position
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {self.AIManager.NPC}
    
    print("[调试] 视觉范围:", visionRange)
    local parts = workspace:GetPartBoundsInRadius(npcPos, visionRange, params) or {}
    print("[调试] 检测到零件数量:", #parts)
    
    local nearestPlayer = nil
    local minDistance = math.huge
    
    for _, part in ipairs(parts) do
        local character = part.Parent
        local player = game.Players:GetPlayerFromCharacter(character)
        if player and character:FindFirstChild("HumanoidRootPart") then
            local distance = (character.HumanoidRootPart.Position - npcPos).Magnitude
            if distance < minDistance then
                nearestPlayer = player
                minDistance = distance
            end
        end
    end
    return nearestPlayer
end

function ChaseState:CheckDistance(player)
    if not self.AIManager.Humanoid or not self.AIManager.Humanoid.RootPart then
        self.AIManager:SetState("Idle")
        return
    end
    
    local currentPos = self.AIManager.Humanoid.RootPart.Position
    local attackRange = self.AIManager.NPC:GetAttribute("AttackRange")
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    
    local distanceToPlayer = (player.Character.HumanoidRootPart.Position - currentPos).Magnitude
    local distanceToSpawn = (self.spawnPosition - currentPos).Magnitude
    
    if distanceToPlayer <= attackRange then
        self.AIManager:SetState("Attack")
        return
    elseif distanceToPlayer > visionRange or distanceToSpawn > visionRange*1.5 then
        self.AIManager.Humanoid:MoveTo(self.spawnPosition)
        self.moveConnection = self.AIManager.Humanoid.MoveToFinished:Connect(function(reached)
            if reached then
                self.AIManager:SetState("Idle")
                return
            end
        end)
    end
end

function ChaseState:UpdatePath(targetPos)
    if not self.AIManager.Humanoid or not self.AIManager.Humanoid.RootPart then
        self.AIManager:SetState("Idle")
        return
    end
    
    self.Path:ComputeAsync(self.AIManager.Humanoid.RootPart.Position, targetPos)
    if self.Path.Status == Enum.PathStatus.Success then
        local waypoints = self.Path:GetWaypoints()
        if #waypoints > 1 then
            self.AIManager.Humanoid:MoveTo(waypoints[2].Position)
        end
    else
        self.AIManager:SetState("Idle")
        return
    end
end

function ChaseState:Exit()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.moveConnection then
        self.moveConnection:Disconnect()
        self.moveConnection = nil
    end
end

return ChaseState