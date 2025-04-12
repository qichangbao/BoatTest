print("加载PositionCondition")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local PositionCondition = {}
setmetatable(PositionCondition, ConditionBase)
PositionCondition.__index = PositionCondition

function PositionCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), PositionCondition)
    
    self.position = self.config.Position
    self.radius = self.config.Radius
    self.cooldown = self.config.Cooldown or 0
    self.lastConditionTime = 0
    self.trackedCharacters = {}
    self.activeConnections = {}
    
    return self
end

function PositionCondition:StartMonitoring()
    ConditionBase.StartMonitoring(self)
    
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")

    -- 全局检测循环
    if RunService:IsServer() then
        self.heartbeatConnection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            
            for character, _ in pairs(self.trackedCharacters) do
                if not character:IsDescendantOf(workspace) then
                    self.trackedCharacters[character] = nil
                    continue
                end
                
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart and self:_CheckCondition(currentTime, rootPart) then
                    self:_FireConditionEvent(character.Parent, rootPart.Position, currentTime)
                end
            end
        end)
    end

    local function trackCharacter(player, character)
        self.trackedCharacters[character] = true
        
        -- 自动清理逻辑
        local function cleanup()
            self.trackedCharacters[character] = nil
            if self.activeConnections[character] then
                self.activeConnections[character]:Disconnect()
                self.activeConnections[character] = nil
            end
        end
        
        self.activeConnections[character] = character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanup()
            end
        end)
        
        player.CharacterRemoving:Connect(cleanup)
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            trackCharacter(player, character)
        end)
    end)
end

function PositionCondition:_CheckCondition(currentTime, rootPart)
    return not self:IsReachingMaxConditions() 
        and (currentTime - self.lastConditionTime) >= self.cooldown
        and (rootPart.Position - self.position).Magnitude <= self.radius
end

function PositionCondition:_FireConditionEvent(player, position, currentTime)
    self.conditionCount += 1
    self.lastConditionTime = currentTime
    
    self.bindableEvent:Fire({
        Player = player,
        Position = position,
        ConditionPosition = self.position,
        ConditionCount = self.conditionCount
    })
end

return PositionCondition