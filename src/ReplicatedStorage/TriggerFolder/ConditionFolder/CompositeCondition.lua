print("加载CompositeCondition")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))
local PositionCondition = require(script.Parent:WaitForChild("PositionCondition"))
local PlayerActionCondition = require(script.Parent:WaitForChild("PlayerActionCondition"))

local CompositeCondition = {}
setmetatable(CompositeCondition, ConditionBase)
CompositeCondition.__index = CompositeCondition

function CompositeCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), CompositeCondition)
    
    -- 组合触发器配置
    self.conditionMode = self.config.ConditionMode or "Sequential" -- Sequential或Parallel
    self.resetOnFail = self.config.ResetOnFail or false
    self.cooldown = self.config.Cooldown or 0
    self.lastConditionTime = 0
    
    -- 子触发器状态跟踪
    self.childConditions = {}
    self.conditionStates = {}
    self.currentConditionIndex = 1 -- 用于Sequential模式
    
    -- 初始化子触发器
    self:InitializeChildConditions(self.config.Conditions)
    
    return self
end

function CompositeCondition:InitializeChildConditions(conditionConfigs)
    for i, conditionConfig in ipairs(conditionConfigs) do
        local condition
        
        -- 根据触发器类型创建相应的触发器实例
        if conditionConfig.ConditionType == "Position" then
            condition = PositionCondition.new(conditionConfig)
        elseif conditionConfig.ConditionType == "PlayerAction" then
            condition = PlayerActionCondition.new(conditionConfig)
        else
            warn("未知的触发器类型:", conditionConfig.ConditionType)
            continue
        end
        
        -- 添加到子触发器列表
        table.insert(self.childConditions, condition)
        self.conditionStates[i] = false
    end
end

function CompositeCondition:StartMonitoring()
    -- 启动所有子触发器的监控
    for i, condition in ipairs(self.childConditions) do
        condition:StartMonitoring()
        
        -- 连接子触发器事件
        condition:Connect(function(data)
            self:HandleChildCondition(i, data)
        end)
    end
end

function CompositeCondition:HandleChildCondition(conditionIndex, data)
    local currentTime = tick()
    
    -- 检查冷却时间
    if currentTime - self.lastConditionTime < self.cooldown then
        return
    end
    
    if self.conditionMode == "Sequential" then
        -- 顺序模式：必须按顺序触发
        if conditionIndex == self.currentConditionIndex then
            self.conditionStates[conditionIndex] = true
            self.currentConditionIndex = self.currentConditionIndex + 1
            
            -- 检查是否所有触发器都已触发
            if self.currentConditionIndex > #self.childConditions then
                self:FireCompositeCondition(data)
                self:ResetConditionStates()
            end
        elseif self.resetOnFail then
            -- 如果触发了错误的顺序且设置了失败重置，则重置所有状态
            self:ResetConditionStates()
        end
    elseif self.conditionMode == "Parallel" then
        -- 并行模式：所有触发器都必须被触发，不考虑顺序
        self.conditionStates[conditionIndex] = true
        
        -- 检查是否所有触发器都已触发
        local allConditioned = true
        for _, state in pairs(self.conditionStates) do
            if not state then
                allConditioned = false
                break
            end
        end
        
        if allConditioned then
            self:FireCompositeCondition(data)
            self:ResetConditionStates()
        end
    end
end

function CompositeCondition:FireCompositeCondition(data)
    self.lastConditionTime = tick()
    
    print("触发了CompositeCondition")
    -- 触发组合事件
    self.bindableEvent:Fire({
        ConditionType = "Composite",
        ConditionMode = self.conditionMode,
        ChildData = data,
        Timestamp = self.lastConditionTime
    })
end

function CompositeCondition:ResetConditionStates()
    -- 重置所有子触发器状态
    for i in pairs(self.conditionStates) do
        self.conditionStates[i] = false
    end
    self.currentConditionIndex = 1
end

return CompositeCondition