local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local ChaseState = {}
ChaseState.__index = ChaseState

local HEARTBEAT_SPACE = 1       -- 每秒执行一次

-- 追赶状态
function ChaseState.new(AIManager)
    local self = setmetatable({}, ChaseState)
    self.AIManager = AIManager
    return self
end

function ChaseState:Enter()
    print("进入Chase状态")
    self:FindNearestModel()
    
    self.timer = HEARTBEAT_SPACE
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        local HumanoidRootPart = self.AIManager.NPC:FindFirstChild('HumanoidRootPart')
        if not HumanoidRootPart then
            return
        end

        local target = self.AIManager.target
        if not target then
            self.AIManager:SetState("Idle")
            return
        end
        
        local targetPosition = nil
        local modelType = target:GetAttribute("ModelType")
        if modelType == "Boat" then
            if not target:GetAttribute("Destroying") then
                targetPosition = target.PrimaryPart.CFrame.Position
            end
        elseif modelType == "Player" then
            local targetHumanoidRootPart = target:FindFirstChild('HumanoidRootPart')
            local targetHumanoid = target:FindFirstChild('Humanoid')
            if targetHumanoidRootPart and targetHumanoid and targetHumanoid.Health > 0 then
                targetPosition = targetHumanoidRootPart.CFrame.Position
            end
        end

        if not targetPosition then
            self.AIManager.target = nil
            self.AIManager:SetState("Idle")
            return
        end
        -- 计算移动方向
        local currentPos = HumanoidRootPart.CFrame.Position
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
        HumanoidRootPart.CFrame = CFrame.new(newPos, direction)

        self.timer = self.timer - dt
        if self.timer <= 0 then
            self:CheckDistance()
            self.timer = HEARTBEAT_SPACE
        end
    end)
end

function ChaseState:FindNearestModel()
    local HumanoidRootPart = self.AIManager.NPC:FindFirstChild('HumanoidRootPart')
    if not HumanoidRootPart then
        print("HumanoidRootPart not found")
        self.AIManager:SetState("Dead")
        return
    end
    local npcPos = HumanoidRootPart.CFrame.Position
    local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
    local minDistance = math.huge
    local boats = CollectionService:GetTagged("Boat")
    for _, v in ipairs(boats) do
        if not v:GetAttribute("Destroying") then
            local dis = (v.PrimaryPart.CFrame.Position - npcPos).Magnitude
            if dis <= visionRange then
                if not minDistance or dis < minDistance then
                    self.AIManager.target = v
                    minDistance = dis
                end
            end
        end
    end

    for _, v in ipairs(Players:GetPlayers()) do
        local character = v.character
        if character and character.HumanoidRootPart and character.Humanoid and character.Humanoid.Health > 0 then
            local dis = (character.HumanoidRootPart.Position - npcPos).Magnitude
            if dis <= visionRange then
                if not minDistance or dis < minDistance then
                    self.AIManager.target = character
                    minDistance = dis
                end
            end
        end
    end

    -- 如果目标是玩家且在船内，切换目标为船
    if self.AIManager.target and self.AIManager.target:GetAttribute("ModelType") == "Player" then
        local playr = Players:GetPlayerFromCharacter(self.AIManager.target)
        local boat = Knit.GetService('BoatAttributeService'):GetPlayerBoat(playr)
        if boat and not boat:GetAttribute("Destroying") and self.AIManager.target.Humanoid.Sit then
            self.AIManager.target = boat
            return
        end
    end
end

function ChaseState:CheckDistance()
    local currentPos = self.AIManager.NPC.HumanoidRootPart.CFrame.Position
    local distanceToPlayer = 0
    local target = self.AIManager.target
    local modelType = target:GetAttribute("ModelType")
    if modelType == "Boat" then
        if target:GetAttribute("Destroying") then
            self.AIManager.target = nil
            self.AIManager:SetState("Idle")
            return
        else
            distanceToPlayer = (target.PrimaryPart.CFrame.Position - currentPos).Magnitude
        end
    elseif modelType == "Player" then
        local targetHumanoidRootPart = target:FindFirstChild('HumanoidRootPart')
        local targetHumanoid = target:FindFirstChild('Humanoid')
        if targetHumanoidRootPart and targetHumanoid and targetHumanoid.Health > 0 then
            distanceToPlayer = (targetHumanoidRootPart.CFrame.Position - currentPos).Magnitude
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

function ChaseState:Exit()
    -- 断开连接
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    
    print("退出Chase状态")
end

return ChaseState
