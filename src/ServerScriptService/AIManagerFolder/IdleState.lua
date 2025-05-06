local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local IdleState = {}
IdleState.__index = IdleState

-- 空闲状态
function IdleState.new(AIManager)
    local self = setmetatable({}, IdleState)
    self.AIManager = AIManager
    return self
end

function IdleState:Enter()
    print("进入Idle状态")
    self.timer = math.random(3, 8)
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        local HumanoidRootPart = self.AIManager.NPC:FindFirstChild('HumanoidRootPart')
        if not HumanoidRootPart then
            print("HumanoidRootPart not found")
            return
        end

        self.timer = self.timer - dt

        -- NPC离开出生点太远后，切换到Patrol状态
        local npcPos = HumanoidRootPart.CFrame.Position
        local maxDisForSpawn = self.AIManager.NPC:GetAttribute("MaxDisForSpawn")
        local spawnPosition = self.AIManager.NPC:GetAttribute("SpawnPosition")
        if (spawnPosition - npcPos).Magnitude > maxDisForSpawn then
            self.AIManager:SetState("Patrol")
            return
        end
        
        local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
        local boats = CollectionService:GetTagged("Boat")
        for _, v in ipairs(boats) do
            if not v:GetAttribute("Destroying") then
                local dis = (v.PrimaryPart.CFrame.Position - npcPos).Magnitude
                if dis <= visionRange then
                    self.AIManager:SetState("Chase")
                    return
                end
            end
        end

        for _, v in ipairs(Players:GetPlayers()) do
            local character = v.character
            if character then
                local targetHumanoidRootPart = character:FindFirstChild('HumanoidRootPart')
                local targetHumanoid = character:FindFirstChild('Humanoid')
                if targetHumanoidRootPart and targetHumanoid and targetHumanoid.Health > 0 then
                    local dis = (targetHumanoidRootPart.CFrame.Position - npcPos).Magnitude
                    if dis <= visionRange then
                        self.AIManager:SetState("Chase")
                        return
                    end
                end
            end
        end
        -- local params = OverlapParams.new()
        -- params.FilterType = Enum.RaycastFilterType.Include
        -- local players = CollectionService:GetTagged("Player")
        -- local boats = CollectionService:GetTagged("Boat")
        -- params.FilterDescendantsInstances = {table.unpack(players), table.unpack(boats)}
        -- local parts = workspace:GetPartBoundsInRadius(npcPos, visionRange, params) or {}
        -- for _, part in ipairs(parts) do
        --     local character = part.Parent
        --     if character then
        --         local modelType = character:GetAttribute("ModelType")
        --         if modelType == "Boat" and not character:GetAttribute("Destroying") then
        --             self.AIManager:SetState("Chase")
        --             return
        --         elseif modelType == "Player" and character.HumanoidRootPart and character.Humanoid and character.Humanoid.Health > 0 then
        --             self.AIManager:SetState("Chase")
        --             return
        --         end
        --     end
        -- end
        
        if self.timer <= 0 then
            self.AIManager:SetState("Patrol")
            return
        end
    end)
end

function IdleState:Exit()
    print("退出Idle状态")
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return IdleState