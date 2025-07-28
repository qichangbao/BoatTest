local TriggerFolder = script.Parent
local ConfigTriggers = require(TriggerFolder:WaitForChild("ConfigTriggers"))

local ConditionFolder = TriggerFolder:WaitForChild("ConditionFolder")
local PositionCondition = require(ConditionFolder:WaitForChild("PositionCondition"))
local SailingDistanceCondition = require(ConditionFolder:WaitForChild("SailingDistanceCondition"))

local ActionFolder = TriggerFolder:WaitForChild("ActionFolder")
local CreateChestAction = require(ActionFolder:WaitForChild("CreateChestAction"))
local WaveAction = require(ActionFolder:WaitForChild("WaveAction"))
local CreateMonsterAction = require(ActionFolder:WaitForChild("CreateMonsterAction"))
local CreateIslandAction = require(ActionFolder:WaitForChild("CreateIslandAction"))

local TriggerManager = {}

local _allConditions = {}   -- 所有条件
function TriggerManager.new()
    local self = setmetatable({}, { __index = TriggerManager })

    self:Init()

    for _, player in game.Players:GetPlayers() do
        for _, condition in ipairs(_allConditions) do
            condition:StartMonitoring(player)
        end
    end
    return self
end

-- 加载条件
function TriggerManager:Init()
    -- 遍历所有触发器配置
    for _, triggerConfig in ipairs(ConfigTriggers) do
        local condition
        
        -- 根据触发器类型创建相应的触发器实例
        if triggerConfig.ConditionType == "Position" then
            condition = PositionCondition.new(triggerConfig)
        elseif triggerConfig.ConditionType == "SailingDistance" then
            condition = SailingDistanceCondition.new(triggerConfig)
        else
            warn("未知的触发器类型:", triggerConfig.ConditionType)
            continue
        end
        table.insert(_allConditions, condition)

        local action
        if triggerConfig.Action then
            action = self:InitAction(triggerConfig.Action, condition)
        end
        
        -- 连接触发器事件
        condition:Connect(function(data)
            if triggerConfig.ConditionType == "Position" then
                print("位置触发器被触发!", data.Player.Name, "在位置", data.Position)
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
        for _, condition in ipairs(_allConditions) do
            for _, v in pairs(game.Players:GetPlayers()) do
                condition:MonitorPlayer(v)
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
    elseif actionConfig.ActionType == "CreateIsland" then
        action = CreateIslandAction.new(actionConfig, condition)
    else
        warn("未知的动作类型:", actionConfig.ActionType)
        return nil
    end

    return action
end

game.Players.PlayerAdded:Connect(function(player)
    for _, condition in ipairs(_allConditions) do
        condition:StartMonitoring(player)
    end
end)

game.Players.PlayerRemoving:Connect(function(player)
    for _, condition in ipairs(_allConditions) do
        condition:StopMonitoring(player)
    end
end)

return TriggerManager