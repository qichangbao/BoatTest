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
        self.timer = self.timer - dt
        
        local npcPos = self.AIManager.Humanoid.RootPart.Position
        local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
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
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

return IdleState