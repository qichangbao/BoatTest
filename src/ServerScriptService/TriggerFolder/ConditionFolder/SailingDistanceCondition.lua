local RunService = game:GetService("RunService")
local ConditionBase = require(script.Parent:WaitForChild("ConditionBase"))

local SailingDistanceCondition = {}
setmetatable(SailingDistanceCondition, ConditionBase)
SailingDistanceCondition.__index = SailingDistanceCondition

function SailingDistanceCondition.new(config)
    local self = setmetatable(ConditionBase.new(config), SailingDistanceCondition)
    
    self.requiredDistance = self.config.RequiredDistance or 1000 -- 需要航行的距离
    self.playerDistances = {} -- 存储每个玩家的航行距离
    self.playerLastPositions = {} -- 存储每个玩家的上一个位置
    
    return self
end

function SailingDistanceCondition:MonitorPlayer(player)
    -- 检查是否超过最大触发次数
    if self:IsReachingMaxConditions(player) then
        return
    end

    -- 检查冷却时间
    if self:IsReachingCooldown(player) then
        return
    end

    -- 检查玩家是否在船上
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..player.UserId)
    if not boat or not boat.PrimaryPart then
        -- 玩家不在船上，重置距离记录
        self.playerDistances[player.UserId] = nil
        self.playerLastPositions[player.UserId] = nil
        return
    end

    local currentPosition = boat.PrimaryPart.Position
    
    -- 初始化玩家数据
    if not self.playerDistances[player.UserId] then
        self.playerDistances[player.UserId] = 0
        self.playerLastPositions[player.UserId] = currentPosition
        return
    end

    -- 计算移动距离
    local lastPosition = self.playerLastPositions[player.UserId]
    local distance = (currentPosition - lastPosition).Magnitude
    
    -- 只有当移动距离大于一定阈值时才累加（避免微小抖动）
    if distance > 1 then
        self.playerDistances[player.UserId] = self.playerDistances[player.UserId] + distance
        self.playerLastPositions[player.UserId] = currentPosition
        
        -- 检查是否达到所需距离
        if self.playerDistances[player.UserId] >= self.requiredDistance then
            local totalDistance = self.playerDistances[player.UserId]
            
            -- 重置该玩家的距离记录
            self.playerDistances[player.UserId] = 0
            
            self:Fire({
                Player = player,
                TotalDistance = totalDistance,
            })
        end
    end
end

function SailingDistanceCondition:Reset(player)
    ConditionBase.Reset(self, player)
    
    -- 重置该玩家的距离记录
    self.playerDistances[player.UserId] = nil
    self.playerLastPositions[player.UserId] = nil
end

return SailingDistanceCondition