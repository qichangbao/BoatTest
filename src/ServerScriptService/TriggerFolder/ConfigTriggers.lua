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
    
    -- 航行距离触发器测试
    {
        ConditionType = "SailingDistance", -- 条件类型：基于航行距离的触发器
        MaxConditions = -1, -- 最大触发次数，-1表示无限制
        RequiredDistance = 500, -- 需要航行的距离（单位：studs）
        Cooldown = 30, -- 触发冷却时间（秒）
        RandomChance = 30, -- 随机触发的概率
        IsGoodCondition = true,
        Action = {
            ActionType = "CreateMonster",
            MonsterName = "Shark",
            UsePlayerPosition = true, -- 使用玩家当前位置
            PositionOffset = 100, -- 相对于玩家位置的偏移
            DestroyToResetCondition = true, -- 死亡是否重置条件
            ResetConditionDelayTime = {30, 50}, -- 重置条件的延迟时间
            Lifetime = 300 -- 怪物存在时间
        },
    },
    -- 航行距离触发器测试
    {
        ConditionType = "SailingDistance", -- 条件类型：基于航行距离的触发器
        MaxConditions = -1, -- 最大触发次数，-1表示无限制
        RequiredDistance = 200, -- 需要航行的距离（单位：studs）
        Cooldown = 30, -- 触发冷却时间（秒）
        RandomChance = 40, -- 随机触发的概率
        IsGoodCondition = true,
        Action = {
            ActionType = "CreateChest",
            UsePlayerPosition = true, -- 使用玩家当前位置
            PositionOffset = 80, -- 相对于玩家位置的偏移
            DestroyToResetCondition = true, -- 销毁后重置条件
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
        RandomChance = 40, -- 随机触发的概率
        IsGoodCondition = false,
        Action = {
            ActionType = "Wave",
            Lifetime = 3,
            UsePlayerPosition = true, -- 使用玩家当前位置
            PositionOffset = 150, -- 相对于玩家位置的偏移
            ChangeHp = 30,
        },
    },
    -- 航行距离触发器测试
    {
        ConditionType = "SailingDistance", -- 条件类型：基于航行距离的触发器
        MaxConditions = -1, -- 最大触发次数，-1表示无限制
        RequiredDistance = 1000, -- 需要航行的距离（单位：studs）
        Cooldown = 30, -- 触发冷却时间（秒）
        RandomChance = 40, -- 随机触发的概率
        IsGoodCondition = true,-- 是否好的条件，用于玩家的幸运值怎么影响
        Action = {
            ActionType = "CreateIsland",
            Lifetime = 300,
            UsePlayerPosition = true, -- 使用玩家当前位置
            PositionOffset = 600, -- 相对于玩家位置的偏移
            DestroyToResetCondition = true, -- 销毁后重置条件
            ResetConditionDelayTime = {10, 20}, -- 重置条件的延迟时间
        },
    },
}