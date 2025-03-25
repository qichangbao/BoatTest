--[[
冒险事件管理模块
功能：处理障碍物碰撞、昼夜循环等冒险模式事件
版本：1.0.0
最后修改：2024/05/15
]]
local AdventureEventManager = {}
AdventureEventManager.__index = AdventureEventManager

-- 构造函数
-- @param eventManager 事件管理器实例
function AdventureEventManager.new(eventManager)
    local self = setmetatable({
        _eventManager = eventManager,
        _currentDayNight = "Day",
        _obstacleTypes = {
            {name = "风暴", damage = 0.15, minLevel = 2},
            {name = "暗礁", damage = 0.3, minLevel = 3},
            {name = "海盗船", damage = 0.4, minLevel = 5}
        }
    }, AdventureEventManager)
    
    self:_initEvents()
    return self
end

function AdventureEventManager:_initEvents()
    -- 注册障碍物碰撞事件（伤害计算逻辑）
    self._eventManager:RegisterEvent("ObstacleHit", function(player, obstacleType)
        local shipManager = self._eventManager:GetShipManager(player)
        local damage = obstacleType.damage * shipManager.shipData.totalHealth -- 基于总血量的百分比伤害计算
        shipManager.shipData.totalHealth = math.max(shipManager.shipData.totalHealth - damage, 0)
        
        if shipManager.shipData.totalHealth == 0 then
            self._eventManager:TriggerEvent(player, "ShipDestroyed")
        end
    end)

    -- 注册昼夜循环事件（光照强度变化）
self._eventManager:RegisterEvent("DayNightCycle", function(player)
        self._currentDayNight = (self._currentDayNight == "Day") and "Night" or "Day"
        self._eventManager:TriggerEvent(player, "VisualEffectChanged", {
            type = "Lighting",
            intensity = (self._currentDayNight == "Night") and 0.3 or 1.0
        })
    end)
end

-- 生成随机关卡障碍物
-- @param playerLevel 当前玩家等级
-- @return 符合等级要求的随机障碍物配置
function AdventureEventManager:GenerateRandomObstacle(playerLevel)
    local validObstacles = {}
    for _,obstacle in ipairs(self._obstacleTypes) do
        if playerLevel >= obstacle.minLevel then
            table.insert(validObstacles, obstacle)
        end
    end
    return validObstacles[math.random(#validObstacles)]
end

-- 启动昼夜循环定时器
-- 循环间隔：300秒（5分钟）
function AdventureEventManager:StartDayNightCycle()
    while true do
        task.wait(300) -- 300秒（5分钟）定时器，nil参数表示全局事件
        self._eventManager:TriggerEvent(nil, "DayNightCycle")
    end
end

return AdventureEventManager