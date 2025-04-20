local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

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
    self.timer = 1
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.timer = self.timer - dt
        if self.timer <= 0 then
            self:CheckDistance()
            self.timer = 1
        end
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
    -- local npcPos = self.AIManager.Humanoid.RootPart.Position
    -- local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    -- local params = OverlapParams.new()
    -- params.FilterType = Enum.RaycastFilterType.Include
    -- local players = CollectionService:GetTagged("Player")
    -- local boats = CollectionService:GetTagged("Boat")
    -- params.FilterDescendantsInstances = {table.unpack(players), table.unpack(boats)}
    -- local parts = workspace:GetPartBoundsInRadius(npcPos, visionRange, params) or {}
    
    -- local nearestModelPos = nil
    -- local minDistance = math.huge
    -- for _, part in ipairs(parts) do
    --     local character = part.Parent
    --     local modelType = character:GetAttribute("ModelType")
    --     if modelType == "Boat" and not character:GetAttribute("Destroying") then
    --         local pos = character:GetPivot().Position
    --         local distance = (pos - npcPos).Magnitude
    --         if distance < minDistance then
    --             self.AIManager.target = character
    --             nearestModelPos = pos
    --             minDistance = distance
    --         end
    --     elseif modelType == "Player" and character.HumanoidRootPart and character.Humanoid and character.Humanoid.Health > 0 then
    --         local pos = character.HumanoidRootPart.Position
    --         local distance = (pos - npcPos).Magnitude
    --         if distance < minDistance then
    --             self.AIManager.target = character
    --             nearestModelPos = pos
    --             minDistance = distance
    --         end
    --     end
    -- end

    local npcPos = self.AIManager.Humanoid.RootPart.Position
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    local nearestModelPos = nil
    local minDistance = math.huge
    local boats = CollectionService:GetTagged("Boat")
    for _, v in ipairs(boats) do
        if not v:GetAttribute("Destroying") then
            local dis = (v:GetPivot().Position - npcPos).Magnitude
            if dis <= visionRange then
                if not minDistance or dis < minDistance then
                    self.AIManager.target = v
                    minDistance = dis
                    nearestModelPos = v:GetPivot().Position
                end
            end
        end
    end

    for _, v in ipairs(Players:GetChildren()) do
        local character = v.character
        if character and character.HumanoidRootPart and character.Humanoid and character.Humanoid.Health > 0 then
            local dis = (character.HumanoidRootPart.Position - npcPos).Magnitude
            if dis <= visionRange then
                if not minDistance or dis < minDistance then
                    self.AIManager.target = character
                    minDistance = dis
                    nearestModelPos = character.HumanoidRootPart.Position
                end
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
    local target = self.AIManager.target
    local modelType = target:GetAttribute("ModelType")
    if modelType == "Boat" then
        if target:GetAttribute("Destroying") then
            self.AIManager.target = nil
            self.AIManager:SetState("Idle")
            return
        else
            distanceToPlayer = (target:GetPivot().Position - currentPos).Magnitude
        end
    elseif modelType == "Player" then
        local HumanoidRootPart = target:FindFirstChild('HumanoidRootPart')
        local Humanoid = target:FindFirstChild('Humanoid')
        if HumanoidRootPart and Humanoid and Humanoid.Health > 0 then
            distanceToPlayer = (HumanoidRootPart.Position - currentPos).Magnitude
        else
            self.AIManager.target = nil
            self.AIManager:SetState("Idle")
            return
        end
    end
    
    local attackRange = self.AIManager.NPC:GetAttribute("AttackRange")
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {target}
    local parts = workspace:GetPartBoundsInRadius(currentPos, attackRange, params) or {}
    if #parts > 0 then
        self.AIManager:SetState("Attack")
        return
    elseif distanceToPlayer > visionRange then
        self.AIManager.target = nil
        self.AIManager:SetState("Idle")
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
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self.currentWaypointIndex = nil
    self.waypoints = nil
    print("退出Chase状态")
end

return ChaseState
