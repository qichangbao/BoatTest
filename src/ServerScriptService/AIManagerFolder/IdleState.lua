local IdleState = {}
IdleState.__index = IdleState

function IdleState.new(controller)
    local self = setmetatable({}, IdleState)
    self.Controller = controller
    return self
end



function IdleState:Exit()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

function IdleState:Enter()
    self.timer = math.random(3, 8)
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.timer = self.timer - dt
        
        -- 玩家检测逻辑
        local npcPos = self.Controller.Humanoid.RootPart.Position
        local visionRange = self.Controller.NPC:GetAttribute("VisionRange")
        
        local detectionBox = Region3.new(
            npcPos - Vector3.new(visionRange, 5, visionRange),
            npcPos + Vector3.new(visionRange, 5, visionRange)
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
        
        if self.timer <= 0 then
            self.Controller:SetState("Patrol")
        end
    end)
end



return IdleState