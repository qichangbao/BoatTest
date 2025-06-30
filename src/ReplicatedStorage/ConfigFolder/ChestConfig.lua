-- 宝箱奖励配置
local ChestConfig = {
    -- 金币奖励配置
    gold = {
        chance = 0.6, -- 60%概率获得金币
        minAmount = 10,
        maxAmount = 50,
    },
    
    -- Buff奖励配置
    buff = {
        chance = 0.3, -- 30%概率获得Buff
    },
    
    -- 物品奖励配置
    item = {
        chance = 0.4, -- 40%概率获得物品
    }
}

return ChestConfig