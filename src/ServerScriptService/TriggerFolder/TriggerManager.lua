print("加载TriggerManager")
local TriggerFolder = script.Parent
local ConfigTriggers = require(TriggerFolder:WaitForChild("ConfigTriggers"))

local ConditionFolder = TriggerFolder:WaitForChild("ConditionFolder")
local PositionCondition = require(ConditionFolder:WaitForChild("PositionCondition"))
local PlayerActionCondition = require(ConditionFolder:WaitForChild("PlayerActionCondition"))
local CompositeCondition = require(ConditionFolder:WaitForChild("CompositeCondition"))

local ActionFolder = TriggerFolder:WaitForChild("ActionFolder")
local CreatePartAction = require(ActionFolder:WaitForChild("CreatePartAction"))
local WaveAction = require(ActionFolder:WaitForChild("WaveAction"))

local TriggerManager = {}

function TriggerManager.new()
    local self = setmetatable({}, { __index = TriggerManager })
    self.triggersCount = 0
    self.positionConditions = {}

    self:Init()

    game:GetService("RunService").Heartbeat:Connect(function()
        for _, condition in ipairs(self.positionConditions) do
            for _, v in pairs(game.Players:GetPlayers()) do
                condition:MonitorPlayer(v)
            end
        end
    end)
    return self
end

-- 加载条件
function TriggerManager:Init()
    -- 遍历所有触发器配置
    for i, triggerConfig in ipairs(ConfigTriggers) do
        local condition
        
        -- 根据触发器类型创建相应的触发器实例
        if triggerConfig.ConditionType == "Position" then
            condition = PositionCondition.new(triggerConfig)
            table.insert(self.positionConditions, condition)
        elseif triggerConfig.ConditionType == "PlayerAction" then
            condition = PlayerActionCondition.new(triggerConfig)
        elseif triggerConfig.ConditionType == "Composite" then
            condition = CompositeCondition.new(triggerConfig)
        else
            warn("未知的触发器类型:", triggerConfig.ConditionType)
            continue
        end
        
        -- 启动触发器监控
        condition:StartMonitoring()

        local action
        if triggerConfig.Action then
            action = self:InitAction(triggerConfig.Action)
        end
        
        -- 连接触发器事件
        condition:Connect(function(data)
            if triggerConfig.ConditionType == "Position" then
                print("位置触发器被触发!", data.Player.Name, "在位置", data.Position)
            elseif triggerConfig.ConditionType == "PlayerAction" then
                print("玩家动作触发器被触发!", data.Player.Name)
            elseif triggerConfig.ConditionType == "Composite" then
                print("组合触发器被触发!", "模式:", data.ConditionMode)
            else
                warn("未知的触发器类型:", triggerConfig.ConditionType)
                return
            end
            
            -- 执行关联动作
            if action then
                action:Execute()
            end
        end)
        
        self.triggersCount += 1
    end
end

-- 加载动作
function TriggerManager:InitAction(actionConfig)
    local action
    if actionConfig.ActionType == "CreatePart" then
        action = CreatePartAction.new(actionConfig)
    elseif actionConfig.ActionType == "Wave" then
        action = WaveAction.new(actionConfig)
    else
        warn("未知的动作类型:", actionConfig.ActionType)
        return nil
    end

    return action
end

return TriggerManager