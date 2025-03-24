print("加载PositionCondition")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local PositionCondition = {}
setmetatable(PositionCondition, ConditionBase)
PositionCondition.__index = PositionCondition

function PositionCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), PositionCondition)
    
    self.position = self.config.Position
    self.radius = self.config.Radius
    self.maxConditions = self.config.MaxConditions or 1
    self.cooldown = self.config.Cooldown or 0
    self.conditionCount = 0
    self.lastConditionTime = 0
    
    return self
end

function PositionCondition:StartMonitoring()
    local RunService = game:GetService("RunService")
    
    local function monitorPlayer(player)
        player.CharacterAdded:Connect(function(character)
            RunService.Heartbeat:Connect(function()
                local rootPart = character:WaitForChild("HumanoidRootPart")
                -- 检查是否超过最大触发次数
                if self.conditionCount >= self.maxConditions then
                    return
                end
                
                -- 检查冷却时间
                local currentTime = tick()
                if currentTime - self.lastConditionTime < self.cooldown then
                    return
                end
                
                -- 检查玩家是否在触发范围内
                local distance = (rootPart.Position - self.position).Magnitude
                if distance <= self.radius then
                    self.conditionCount = self.conditionCount + 1
                    self.lastConditionTime = currentTime
                    
                    print("触发了PositionCondition")
                    self.bindableEvent:Fire({
                        Player = player,
                        Position = rootPart.Position,
                        ConditionPosition = self.position,
                        ConditionCount = self.conditionCount
                    })
                end
            end)
        end)
    end
    
    if RunService:IsServer() then
        -- 服务器端通过PlayerAdded监听
        game:GetService("Players").PlayerAdded:Connect(monitorPlayer)
    else
        -- 客户端保持原有逻辑
        monitorPlayer(game.Players.LocalPlayer)
    end
end

return PositionCondition