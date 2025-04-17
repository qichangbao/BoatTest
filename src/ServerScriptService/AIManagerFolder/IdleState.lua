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
        
        -- 玩家检测逻辑
        local npcPos = self.AIManager.Humanoid.RootPart.Position
        local visionRange = self.AIManager.NPC:GetAttribute("VisionRange")
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