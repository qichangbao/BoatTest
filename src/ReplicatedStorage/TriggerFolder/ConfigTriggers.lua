return {
    -- -- 单独的位置触发器
    -- {
    --     ConditionType = "Position", -- 条件类型：基于位置的触发器
    --     Position = Vector3.new(0, 0, 0), -- 触发位置
    --     Radius = 5, -- 触发区域的半径，与Position共同定义触发区域
    --     MaxConditions = 1, -- 最大触发次数，超过此次数后不再触发
    --     Cooldown = 5, -- 触发冷却时间（秒），在此时间内不会再次触发
    --     Action = {
    --         ActionType = "CreatePart",
    --     },
    -- },
    
    -- -- 单独的玩家动作触发器
    -- {
    --     ConditionType = "PlayerAction", -- 条件类型：基于玩家动作的触发器
    --     SubConditionType = "Jump", -- 子触发器类型
    --     RequiredActions = 2, -- 需要玩家动作的次数才能触发
    --     TimeWindow = 3, -- 完成所需动作的时间窗口（秒）
    --     ResetOnLeave = true, -- 当玩家离开区域时是否重置触发器状态
    --     Action = {
    --         ActionType = "CreatePart",
    --         Size = Vector3.new(3,3,3),
    --         Position = Vector3.new(0, 10, 0),
    --         Color = Color3.new(0, 1, 0),
    --         Duration = 10
    --     },
    -- },
    
    -- -- 组合触发器示例：玩家到达特定区域后跳跃才触发
    -- {
    --     ConditionType = "Composite", -- 条件类型：组合多个触发条件的复合触发器
    --     ConditionMode = "Sequential", -- 触发模式：Sequential(按顺序触发), Parallel(同时满足条件)
    --     Conditions = { -- 子触发器列表
    --         {
    --             ConditionType = "Position", -- 第一个子触发器：位置条件
    --             Position = Vector3.new(5, 0, 5), -- 触发位置
    --             Radius = 10, -- 触发区域的半径
    --             MaxConditions = 1 -- 最大触发次数，这里设为1表示只触发一次
    --         },
    --         {
    --             ConditionType = "PlayerAction", -- 第二个子触发器：玩家动作条件
    --             SubConditionType = "Jump", -- 子触发器类型
    --             RequiredActions = 1, -- 需要玩家动作1次
    --             TimeWindow = 5, -- 5秒内完成跳跃
    --             ResetOnLeave = false -- 玩家离开区域后不重置状态
    --         }
    --     },
    --     ResetOnFail = true, -- 如果任一子触发器失败，重置所有子触发器状态
    --     Cooldown = 10, -- 组合触发器的冷却时间（秒）
    --     Action = {
    --         ActionType = "CreatePart",
    --         Size = Vector3.new(1,5,1),
    --         Position = Vector3.new(5, 5, 5),
    --         Color = Color3.new(0, 0, 1)
    --     },
    -- },
}