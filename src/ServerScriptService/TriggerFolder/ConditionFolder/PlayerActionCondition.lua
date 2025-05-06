print("加载PlayerActionCondition")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local PlayerActionCondition = {}
setmetatable(PlayerActionCondition, ConditionBase)
PlayerActionCondition.__index = PlayerActionCondition

function PlayerActionCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), PlayerActionCondition)
    
    self.subConditionType = self.config.SubConditionType or ""
    self.requiredActions = self.config.RequiredActions or 1
    self.timeWindow = self.config.TimeWindow or 5
    self.resetOnLeave = self.config.ResetOnLeave or false
    
    -- 初始化动作计数和时间记录
    self.actionCount = 0
    self.lastActionTime = 0
    
    return self
end

function PlayerActionCondition:StartMonitoring()
    ConditionBase.StartMonitoring(self)
    
    local function monitorPlayer(player)
        player.CharacterAdded:Connect(function(character)
            local function actionStart()
                -- 检查是否超过最大触发次数
                if self:IsReachingMaxConditions() then
                    return
                end
                
                local currentTime = tick()
                -- 检查时间窗口
                if currentTime - self.lastActionTime > self.timeWindow then
                    -- 超出时间窗口，重置计数
                    self.actionCount = 1
                else
                    -- 在时间窗口内，增加计数
                    self.actionCount = self.actionCount + 1
                end
                
                -- 检查是否达到触发条件
                if self.actionCount >= self.requiredActions then
                    print("触发了PlayerActionCondition")
                    self:Fire({
                        Player = player,
                        JumpCount = self.actionCount,  -- 修改为正确的计数值
                    })
                    
                    -- 触发后重置
                    self.actionCount = 0  -- 重置计数器
                    self.lastActionTime = tick()  -- 修正变量名
                end
            end

            local humanoid = character:WaitForChild("Humanoid")
            if self.subConditionType == "Jump" then
                -- 修改Jumping事件的连接方式
                humanoid.Jumping:Connect(function()
                    actionStart()
                end)
            end

            if self.resetOnLeave then
                humanoid.StateChanged:Connect(function(_, newState)
                    if newState == Enum.HumanoidStateType.Freefall then
                        self.lastActionTime = 0  -- 修正变量名
                        self.actionCount = 0  -- 重置计数器
                    end
                end)
            end
        end)
    end

    game:GetService("Players").PlayerAdded:Connect(monitorPlayer)
end

return PlayerActionCondition