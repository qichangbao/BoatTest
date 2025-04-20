local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

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
    local npcPos = self.AIManager.Humanoid.RootPart.Position
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    local patrolRadius = self.AIManager.NPC:GetAttribute("PatrolRadius")
    local spawnPosition = self.AIManager.NPC:GetAttribute("SpawnPosition")
    local targetPosition
    if (spawnPosition - npcPos).Magnitude > visionRange then
        targetPosition = spawnPosition
    else
        targetPosition = npcPos + Vector3.new(
            math.random(-patrolRadius, patrolRadius),
            0,
            math.random(-patrolRadius, patrolRadius)
        )
    end
    self.AIManager.Humanoid:MoveTo(targetPosition)
    -- 监听到达事件
    self.moveToFinished = self.AIManager.Humanoid.MoveToFinished:Connect(function(reached)
        self.AIManager:SetState("Idle")
        return
    end)

    self.timer = 1
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        -- local params = OverlapParams.new()
        -- params.FilterType = Enum.RaycastFilterType.Include
        -- local players = CollectionService:GetTagged("Player")
        -- local boats = CollectionService:GetTagged("Boat")
        -- params.FilterDescendantsInstances = {table.unpack(players), table.unpack(boats)}
        -- local parts = workspace:GetPartBoundsInRadius(npcPos, visionRange, params) or {}
        -- for _, part in ipairs(parts) do
        --     local character = part.Parent
        --     local modelType = character:GetAttribute("ModelType")
        --     if modelType == "Boat" and not character:GetAttribute("Destroying") then
        --         self.AIManager:SetState("Chase")
        --         return
        --     elseif modelType == "Player" and character.HumanoidRootPart and character.Humanoid and character.Humanoid.Health > 0 then
        --         self.AIManager:SetState("Chase")
        --         return
        --     end
        -- end

        self.timer = self.timer - dt
        if self.timer <= 0 then
            local boats = CollectionService:GetTagged("Boat")
            for _, v in ipairs(boats) do
                if not v:GetAttribute("Destroying") then
                    local dis = (v:GetPivot().Position - npcPos).Magnitude
                    if dis <= visionRange then
                        self.AIManager:SetState("Chase")
                        return
                    end
                end
            end
    
            for _, v in ipairs(Players:GetChildren()) do
                local character = v.character
                if character then
                    local HumanoidRootPart = character:FindFirstChild('HumanoidRootPart')
                    local Humanoid = character:FindFirstChild('Humanoid')
                    if HumanoidRootPart and Humanoid and Humanoid.Health > 0 then
                        local dis = (character.HumanoidRootPart.Position - npcPos).Magnitude
                        if dis <= visionRange then
                            self.AIManager:SetState("Chase")
                            return
                        end
                    end
                end
            end
            self.timer = 1
        end
    end)
    
    -- self.Path:ComputeAsync(self.AIManager.Humanoid.RootPart.Position, targetPosition)
    
    -- if self.Path.Status == Enum.PathStatus.Success then
    --     self.waypoints = self.Path:GetWaypoints()
    --     self.currentWaypoint = 2
    --     self.connection = self.AIManager.Humanoid.MoveToFinished:Connect(function(reached) 
    --         if reached and self.currentWaypoint <= #self.waypoints then
    --             self.AIManager.Humanoid:MoveTo(self.waypoints[self.currentWaypoint].Position)
    --             self.currentWaypoint += 1
    --         else
    --             self.AIManager:SetState("Chase")
    --             return
    --         end
    --     end)
        
    --     self.detectionConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
    --         local params = OverlapParams.new()
    --         params.FilterType = Enum.RaycastFilterType.Exclude
    --         params.FilterDescendantsInstances = {self.AIManager.NPC}
    --         local parts = workspace:GetPartBoundsInRadius(npcPos, visionRange, params) or {}
    --         for _, part in ipairs(parts) do
    --             local character = part.Parent
    --             local target = game.Players:GetPlayerFromCharacter(character)
    --             if target and target.Character and target.Character.HumanoidRootPart and not target.Character.Humanoid.Died then
    --                 self.AIManager:SetState("Chase")
    --                 return
    --             end
    --         end
    --     end)
        
    --     self.AIManager.Humanoid:MoveTo(self.waypoints[1].Position)
    -- else
    --     self.AIManager:SetState("Chase")
    --     return
    -- end
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
    if self.moveToFinished then
        self.moveToFinished:Disconnect()
        self.moveToFinished = nil
    end
end


return PatrolState