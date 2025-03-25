local ChaseState = {}
ChaseState.__index = ChaseState

function ChaseState.new(controller)
    local self = setmetatable({}, ChaseState)
    self.Controller = controller
    self.Path = game:GetService("PathfindingService"):CreatePath()
    self.spawnPosition = controller.NPC:GetAttribute("SpawnPosition")
    return self
end

function ChaseState:Enter()
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        local target = self:FindNearestPlayer()
        if target then
            self:UpdatePath(target.Character.HumanoidRootPart.Position)
            self:CheckDistance(target)
        else
            self.Controller:SetState("Idle")
        end
    end)
end

function ChaseState:FindNearestPlayer()
    local npcPos = self.Controller.Humanoid.RootPart.Position
    local visionRange = self.Controller.NPC:GetAttribute("VisionRange")
    
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {self.Controller.NPC}
    
    local detectionBox = Region3.new(
        npcPos - Vector3.new(visionRange, visionRange, visionRange),
        npcPos + Vector3.new(visionRange, visionRange, visionRange)
    )
    
    local parts = workspace:GetPartBoundsInBox(detectionBox, params)
    
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
    if not self.Controller.Humanoid or not self.Controller.Humanoid.RootPart then
        self.Controller:SetState("Idle")
        return
    end
    
    local currentPos = self.Controller.Humanoid.RootPart.Position
    local attackRange = self.Controller.NPC:GetAttribute("AttackRange")
    local visionRange = self.Controller.NPC:GetAttribute("VisionRange")
    
    local distanceToPlayer = (player.Character.HumanoidRootPart.Position - currentPos).Magnitude
    local distanceToSpawn = (self.spawnPosition - currentPos).Magnitude
    
    if distanceToPlayer <= attackRange then
        self.Controller:SetState("Attack")
    elseif distanceToPlayer > visionRange or distanceToSpawn > visionRange*1.5 then
        self.Controller.Humanoid:MoveTo(self.spawnPosition)
        self.moveConnection = self.Controller.Humanoid.MoveToFinished:Connect(function(reached)
            if reached then
                self.Controller:SetState("Idle")
            end
        end)
    end
end

function ChaseState:UpdatePath(targetPos)
    if not self.Controller.Humanoid or not self.Controller.Humanoid.RootPart then
        self.Controller:SetState("Idle")
        return
    end
    
    self.Path:ComputeAsync(self.Controller.Humanoid.RootPart.Position, targetPos)
    if self.Path.Status == Enum.PathStatus.Success then
        local waypoints = self.Path:GetWaypoints()
        if #waypoints > 1 then
            self.Controller.Humanoid:MoveTo(waypoints[2].Position)
        end
    else
        self.Controller:SetState("Idle")
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