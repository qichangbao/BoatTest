print("加载TriggerManager")
local TriggerFolder = script.Parent
local ConfigTriggers = require(TriggerFolder:WaitForChild("ConfigTriggers"))

local ConditionFolder = TriggerFolder:WaitForChild("ConditionFolder")
local PositionCondition = require(ConditionFolder:WaitForChild("PositionCondition"))
local PlayerActionCondition = require(ConditionFolder:WaitForChild("PlayerActionCondition"))
local CompositeCondition = require(ConditionFolder:WaitForChild("CompositeCondition"))
local SailingDistanceCondition = require(ConditionFolder:WaitForChild("SailingDistanceCondition"))

local ActionFolder = TriggerFolder:WaitForChild("ActionFolder")
local CreateChestAction = require(ActionFolder:WaitForChild("CreateChestAction"))
local WaveAction = require(ActionFolder:WaitForChild("WaveAction"))
local CreateMonsterAction = require(ActionFolder:WaitForChild("CreateMonsterAction"))

local TriggerManager = {}

function TriggerManager.new()
    local self = setmetatable({}, { __index = TriggerManager })

    self:Init()
    return self
end

local _needHeartbeatConditions = {}
-- 加载条件
function TriggerManager:Init()
    -- 遍历所有触发器配置
    for _, triggerConfig in ipairs(ConfigTriggers) do
        local condition
        
        -- 根据触发器类型创建相应的触发器实例
        if triggerConfig.ConditionType == "Position" then
            condition = PositionCondition.new(triggerConfig)
            table.insert(_needHeartbeatConditions, condition)
        elseif triggerConfig.ConditionType == "PlayerAction" then
            condition = PlayerActionCondition.new(triggerConfig)
        elseif triggerConfig.ConditionType == "Composite" then
            condition = CompositeCondition.new(triggerConfig)
        elseif triggerConfig.ConditionType == "SailingDistance" then
            condition = SailingDistanceCondition.new(triggerConfig)
            table.insert(_needHeartbeatConditions, condition)
        else
            warn("未知的触发器类型:", triggerConfig.ConditionType)
            continue
        end
        -- 启动触发器监控
        condition:StartMonitoring()

        local action
        if triggerConfig.Action then
            action = self:InitAction(triggerConfig.Action, condition)
        end
        
        -- 连接触发器事件
        condition:Connect(function(data)
            if triggerConfig.ConditionType == "Position" then
                print("位置触发器被触发!", data.Player.Name, "在位置", data.Position)
            elseif triggerConfig.ConditionType == "PlayerAction" then
                print("玩家动作触发器被触发!", data.Player.Name)
            elseif triggerConfig.ConditionType == "Random" then
                print("玩家随机触发器被触发!", data.Player.Name)
            elseif triggerConfig.ConditionType == "Composite" then
                print("组合触发器被触发!", "模式:", data.ConditionMode)
            elseif triggerConfig.ConditionType == "SailingDistance" then
                print("玩家航行距离触发器被触发!", data.Player.Name)
            else
                warn("未知的触发器类型:", triggerConfig.ConditionType)
                return
            end
            
            -- 执行关联动作
            if action then
                action:Execute(data)
            end
        end)
    end

    game:GetService("RunService").Heartbeat:Connect(function()
        for _, condition in ipairs(_needHeartbeatConditions) do
            local conditionType = condition.config.ConditionType
            if conditionType == "Position" or conditionType == "SailingDistance" then
                for _, v in pairs(game.Players:GetPlayers()) do
                    condition:MonitorPlayer(v)
                end
            end
        end
    end)
end

-- 加载动作
function TriggerManager:InitAction(actionConfig, condition)
    local action
    if actionConfig.ActionType == "CreateChest" then
        action = CreateChestAction.new(actionConfig, condition)
    elseif actionConfig.ActionType == "Wave" then
        action = WaveAction.new(actionConfig, condition)
    elseif actionConfig.ActionType == "CreateMonster" then
        action = CreateMonsterAction.new(actionConfig, condition)
    else
        warn("未知的动作类型:", actionConfig.ActionType)
        return nil
    end

    return action
end

return TriggerManager