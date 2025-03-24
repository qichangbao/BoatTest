local PatrolState = {}
PatrolState.__index = PatrolState

function PatrolState.new(controller)
    local self = setmetatable({}, PatrolState)
    self.Controller = controller
    self.Path = game:GetService("PathfindingService"):CreatePath()
    return self
end

function PatrolState:Enter()
    local center = self.Controller.NPC:GetPivot().Position
    local visionRange = self.Controller.NPC:GetAttribute("VisionRange")
    
    local targetPosition = center + Vector3.new(
        math.random(-visionRange, visionRange),
        0,
        math.random(-visionRange, visionRange)
    )
    
    self.Path:ComputeAsync(self.Controller.Humanoid.RootPart.Position, targetPosition)
    
    if self.Path.Status == Enum.PathStatus.Success then
        self.waypoints = self.Path:GetWaypoints()
        self.currentWaypoint = 2
        self.connection = self.Controller.Humanoid.MoveToFinished:Connect(function(reached) 
            if reached and self.currentWaypoint <= #self.waypoints then
                self.Controller.Humanoid:MoveTo(self.waypoints[self.currentWaypoint].Position)
                self.currentWaypoint += 1
            else
                self.Controller:SetState("Chase")
            end
        end)
        
        self.detectionConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            local npcPos = self.Controller.Humanoid.RootPart.Position
            local visionRange = self.Controller.NPC:GetAttribute("VisionRange")
            
            local detectionBox = Region3.new(
                npcPos - Vector3.new(visionRange, visionRange, visionRange),
                npcPos + Vector3.new(visionRange, visionRange, visionRange)
            )
            
            local params = OverlapParams.new()
            params.FilterDescendantsInstances = {self.Controller.NPC}
            
            local parts = workspace:GetPartBoundsInBox(detectionBox, params)
            
            for _, part in ipairs(parts) do
                local character = part.Parent
                local player = game.Players:GetPlayerFromCharacter(character)
                if player and character:FindFirstChild("HumanoidRootPart") then
                    self.Controller:SetState("Chase")
                    return
                end
            end
        end)
        
        self.Controller.Humanoid:MoveTo(self.waypoints[1].Position)
    else
        self.Controller:SetState("Chase")
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
    self.Controller.Humanoid:MoveTo(self.Controller.Humanoid.RootPart.Position)
end


return PatrolState