return {
    -- -- 单独的位置触发器
    -- {
    --     ConditionType = "Position", -- 条件类型：基于位置的触发器
    --     MaxConditions = 1, -- 最大触发次数，超过此次数后不再触发
    --     Position = Vector3.new(0, 0, -400), -- 触发位置
    --     Radius = 50, -- 触发区域的半径，与Position共同定义触发区域
    --     Cooldown = 20, -- 触发冷却时间（秒），在此时间内不会再次触发
    --     RandomChance = 50, -- 随机触发的概率，10%的概率触发
    --     -- Action = {
    --     --     ActionType = "Wave",
    --     --     Lifetime = 5,
    --     --     Position = Vector3.new(0, 0, -200),
    --     --     Size = Vector3.new(300, 80, 2),
    --     --     TargetPosition = Vector3.new(0, 0, -100),
    --     --     ChangeHp = -30,
    --     -- },
    --     Action = {
    --         ActionType = "CreateMonster",
    --         MonsterName = "haiguai1",
    --         Position = Vector3.new(0, 0, -450),
    --         DestroyToResetCondition = true, -- 死亡是否重置条件
    --         ResetConditionDelayTime = {30, 50}, -- 重置条件的延迟时间
    --     }
    -- },
    -- -- 单独的位置触发器
    -- {
    --     ConditionType = "Position", -- 条件类型：基于位置的触发器
    --     MaxConditions = -1, -- 最大触发次数，超过此次数后不再触发
    --     Position = Vector3.new(650, 0, 450), -- 触发位置
    --     Radius = 50, -- 触发区域的半径，与Position共同定义触发区域
    --     Cooldown = 20, -- 触发冷却时间（秒），在此时间内不会再次触发
    --     RandomChance = 100, -- 随机触发的概率
    --     Action = {
    --         ActionType = "Wave",
    --         Lifetime = 10,
    --         Position = Vector3.new(700, 50, 450),
    --         TargetPosition = Vector3.new(600, 50, 450),
    --         ChangeHp = 30,
    --     },
    -- },
    -- -- 单独的位置触发器
    -- {
    --     ConditionType = "Position", -- 条件类型：基于位置的触发器
    --     MaxConditions = 1, -- 最大触发次数，超过此次数后不再触发
    --     Position = Vector3.new(200, 0, 100), -- 触发位置
    --     Radius = 50, -- 触发区域的半径，与Position共同定义触发区域
    --     Cooldown = 20, -- 触发冷却时间（秒），在此时间内不会再次触发
    --     RandomChance = 100, -- 随机触发的概率
    --     Action = {
    --         ActionType = "CreateChest",
    --         Position = Vector3.new(200, 0, 100),
    --         DestroyToResetCondition = true, -- 死亡是否重置条件
    --         ResetConditionDelayTime = {30, 50}, -- 重置条件的延迟时间
    --         Duration = 10
    --     },
    -- },
    
    -- -- 单独的玩家动作触发器
    -- {
    --     ConditionType = "PlayerAction", -- 条件类型：基于玩家动作的触发器
    --     MaxConditions = 1, -- 最大触发次数，超过此次数后不再触发
    --     SubConditionType = "Jump", -- 子触发器类型
    --     RequiredActions = 2, -- 需要玩家动作的次数才能触发
    --     TimeWindow = 3, -- 完成所需动作的时间窗口（秒）
    --     ResetOnLeave = true, -- 当玩家离开区域时是否重置触发器状态
    --     Action = {
    --         ActionType = "CreateChest",
    --         Lifetime = 5,
    --         Position = Vector3.new(0, 10, 0),
    --         Size = Vector3.new(3,3,3),
    --         Color = Color3.new(0, 1, 0),
    --         Duration = 10
    --     },
    -- },
    
    -- 组合触发器示例：玩家到达特定区域后跳跃才触发
    -- {
    --     ConditionType = "Composite", -- 条件类型：组合多个触发条件的复合触发器
    --     MaxConditions = 1, -- 最大触发次数，超过此次数后不再触发
    --     ConditionMode = "Parallel", -- 触发模式：Sequential(按顺序触发), Parallel(同时满足条件)
    --     ResetOnFail = true, -- 如果任一子触发器失败，重置所有子触发器状态
    --     Cooldown = 20, -- 组合触发器的冷却时间（秒）
    --     Conditions = { -- 子触发器列表
    --         {
    --             ConditionType = "Position", -- 第一个子触发器：位置条件
    --             MaxConditions = 1, -- 最大触发次数，超过此次数后不再触发
    --             Position = Vector3.new(0, 0, -200), -- 触发位置
    --             Radius = 50, -- 触发区域的半径
    --             Cooldown = 20, -- 触发冷却时间（秒），在此时间内不会再次触发1
    --         },
    --         {
    --             ConditionType = "Random", -- 第二个子触发器：随机条件
    --             RandomChance = 10, -- 随机触发的概率，10%的概率触发
    --         }
    --     },
    --     Action = {
    --         ActionType = "CreateChest",
    --         Lifetime = 5,
    --         Position = Vector3.new(5, 5, 5),
    --         Size = Vector3.new(1,5,1),
    --         Color = Color3.new(0, 0, 1)
    --     },
    -- },
    
    -- 航行距离触发器测试
    {
        ConditionType = "SailingDistance", -- 条件类型：基于航行距离的触发器
        MaxConditions = -1, -- 最大触发次数，-1表示无限制
        RequiredDistance = 500, -- 需要航行的距离（单位：studs）
        Cooldown = 30, -- 触发冷却时间（秒）
        RandomChance = 30, -- 随机触发的概率，30%的概率触发
        Action = {
            ActionType = "CreateChest",
            UsePlayerPosition = true, -- 使用玩家当前位置
            PositionOffset = 200, -- 相对于玩家位置的偏移
            DestroyToResetCondition = true, -- 宝箱被拾取后重置条件
            ResetConditionDelayTime = {10, 20}, -- 重置条件的延迟时间
            Lifetime = 300 -- 宝箱存在时间
        },
    },
    -- 航行距离触发器测试
    {
        ConditionType = "SailingDistance", -- 条件类型：基于航行距离的触发器
        MaxConditions = -1, -- 最大触发次数，-1表示无限制
        RequiredDistance = 300, -- 需要航行的距离（单位：studs）
        Cooldown = 30, -- 触发冷却时间（秒）
        RandomChance = 30, -- 随机触发的概率，30%的概率触发
        Action = {
            ActionType = "Wave",
            Lifetime = 10,
            UsePlayerPosition = true, -- 使用玩家当前位置
            PositionOffset = 200, -- 相对于玩家位置的偏移
            ChangeHp = 30,
        },
    },
}