print("加载TriggerManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TriggerFolder = ReplicatedStorage:WaitForChild("Trigger")
local ConfigTriggers = require(TriggerFolder:WaitForChild("ConfigTriggers"))

local ConditionFolder = TriggerFolder:WaitForChild("Condition")
local PositionCondition = require(ConditionFolder:WaitForChild("PositionCondition"))
local PlayerActionCondition = require(ConditionFolder:WaitForChild("PlayerActionCondition"))
local CompositeCondition = require(ConditionFolder:WaitForChild("CompositeCondition"))

local ActionFolder = TriggerFolder:WaitForChild("Action")
local CreatePartAction = require(ActionFolder:WaitForChild("CreatePartAction"))

local TriggerManager = {}

function TriggerManager.new()
    local self = setmetatable({}, { __index = TriggerManager })
    self.triggersCount = 0
    return self
end

function TriggerManager:Initialize()
    self:InitCondition()
    print("触发器管理器初始化完成，共", #ConfigTriggers, "个触发器,", "成功加载", self.triggersCount, "个触发器")
    return self
end

-- 加载条件
function TriggerManager:InitCondition()
    -- 遍历所有触发器配置
    for i, triggerConfig in ipairs(ConfigTriggers) do
        local condition
        
        -- 根据触发器类型创建相应的触发器实例
        if triggerConfig.ConditionType == "Position" then
            condition = PositionCondition.new(triggerConfig)
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
    end

    return action
end

return TriggerManager