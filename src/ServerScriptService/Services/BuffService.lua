local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local BuffConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BuffConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local BuffService = Knit.CreateService({
    Name = 'BuffService',
    Client = {
        BuffAdded = Knit.CreateSignal(),
        BuffRemoved = Knit.CreateSignal(),
        BuffUpdated = Knit.CreateSignal(),
    },
})

-- 存储所有玩家的BUFF数据
local playerBuffs = {}
-- 存储BUFF的计时器
local buffTimers = {}

-- 初始化玩家BUFF数据
local function initPlayerBuffs(player)
    if not playerBuffs[player.UserId] then
        playerBuffs[player.UserId] = {
            speed = {},
            health = {},
            damage = {},
            other = {},
        }
    end
end

-- 清理玩家BUFF数据
local function cleanupPlayerBuffs(player)
    if playerBuffs[player.UserId] then
        -- 清理所有计时器
        for buffType, buffs in pairs(playerBuffs[player.UserId]) do
            for buffId, _ in pairs(buffs) do
                local timerId = player.UserId .. "_" .. buffType .. "_" .. buffId
                if buffTimers[timerId] then
                    pcall(task.cancel, buffTimers[timerId])
                    buffTimers[timerId] = nil
                end
            end
        end
        playerBuffs[player.UserId] = nil
    end
end

-- 计算BUFF效果
local function calculateBuffEffect(player, buffType)
    local buffs = playerBuffs[player.UserId][buffType]
    local totalMultiplier = 1
    local totalAdditive = 0
    local totalChance = 0
    
    for buffId, buffData in pairs(buffs) do
        local config = BuffConfig.GetBuffConfig(buffId)
        if config then
            if config.effectType == "multiplier" then
                totalMultiplier = totalMultiplier * config.value
            elseif config.effectType == "additive" then
                totalAdditive = totalAdditive + config.value
            elseif config.effectType == "chance" then
                totalChance = totalChance + config.value
            end
        end
    end
    
    return {
        multiplier = totalMultiplier,
        additive = totalAdditive,
        chance = math.min(totalChance, 1) -- 概率不能超过100%
    }
end

-- 应用速度BUFF
local function applySpeedBuff(player)
    local boat = Interface.GetBoatByPlayerUserId(player.UserId)
    if not boat then
        return
    end
    
    local effect = calculateBuffEffect(player, "speed")
    
    -- 获取船只的基础速度（没有BUFF时的原始速度）
    local baseSpeed = boat:GetAttribute('BaseSpeed') or boat:GetAttribute('MaxSpeed') or 0
    if not boat:GetAttribute('BaseSpeed') then
        -- 首次应用BUFF时，保存原始速度作为基础速度
        boat:SetAttribute('BaseSpeed', boat:GetAttribute('Speed') or 0)
        boat:SetAttribute('BaseMaxSpeed', boat:GetAttribute('MaxSpeed') or 0)
        baseSpeed = boat:GetAttribute('BaseSpeed')
    end
    
    local newSpeed = (baseSpeed + effect.additive) * effect.multiplier
    local newMaxSpeed = (boat:GetAttribute('BaseMaxSpeed') + effect.additive) * effect.multiplier
    
    boat:SetAttribute('Speed', math.max(0, newSpeed))
    boat:SetAttribute('MaxSpeed', math.max(0, newMaxSpeed))
    
    -- 通知BoatAttributeService更新UI
    local BoatAttributeService = Knit.GetService('BoatAttributeService')
    BoatAttributeService:ChangeBoatSpeed(player, newSpeed, newMaxSpeed)
end

-- 应用生命BUFF
local function applyHealthBuff(player)
    local boat = Interface.GetBoatByPlayerUserId(player.UserId)
    if not boat then
        return
    end
    
    local effect = calculateBuffEffect(player, "health")
    
    -- 获取船只的基础生命值（没有BUFF时的原始生命值）
    local baseMaxHealth = boat:GetAttribute('BaseMaxHealth') or boat:GetAttribute('MaxHealth') or 0
    if not boat:GetAttribute('BaseMaxHealth') then
        -- 首次应用BUFF时，保存原始生命值作为基础生命值
        boat:SetAttribute('BaseHealth', boat:GetAttribute('Health') or 0)
        boat:SetAttribute('BaseMaxHealth', boat:GetAttribute('MaxHealth') or 0)
        baseMaxHealth = boat:GetAttribute('BaseMaxHealth')
    end
    
    local currentHealth = boat:GetAttribute('Health') or 0
    local currentMaxHealth = boat:GetAttribute('MaxHealth') or 1
    local currentHealthRatio = currentHealth / currentMaxHealth
    
    local newMaxHealth = (baseMaxHealth + effect.additive) * effect.multiplier
    local newHealth = newMaxHealth * currentHealthRatio
    
    boat:SetAttribute('MaxHealth', math.max(1, newMaxHealth))
    boat:SetAttribute('Health', math.max(0, newHealth))
    
    -- 通知BoatAttributeService更新UI
    local BoatAttributeService = Knit.GetService('BoatAttributeService')
    BoatAttributeService:ChangeBoatHealth(player, newHealth, newMaxHealth)
end

-- 还原船只属性到基础值
local function restoreBoatAttributes(player, buffType)
    local boat = Interface.GetBoatByPlayerUserId(player.UserId)
    if not boat then
        return
    end
    
    -- 检查是否还有相同类型的BUFF
    local hasBuffs = false
    if playerBuffs[player.UserId] and playerBuffs[player.UserId][buffType] then
        for _, _ in pairs(playerBuffs[player.UserId][buffType]) do
            hasBuffs = true
            break
        end
    end
    
    -- 如果没有相关BUFF了，还原到基础值
    if not hasBuffs then
        if buffType == "speed" then
            local baseSpeed = boat:GetAttribute('BaseSpeed')
            local baseMaxSpeed = boat:GetAttribute('BaseMaxSpeed')
            if baseSpeed and baseMaxSpeed then
                boat:SetAttribute('Speed', baseSpeed)
                boat:SetAttribute('MaxSpeed', baseMaxSpeed)
                
                -- 通知BoatAttributeService更新UI
                local BoatAttributeService = Knit.GetService('BoatAttributeService')
                BoatAttributeService:ChangeBoatSpeed(player, baseSpeed, baseMaxSpeed)
            end
        elseif buffType == "health" then
            local baseHealth = boat:GetAttribute('BaseHealth')
            local baseMaxHealth = boat:GetAttribute('BaseMaxHealth')
            if baseHealth and baseMaxHealth then
                -- 保持当前生命值比例
                local currentHealth = boat:GetAttribute('Health') or 0
                local currentMaxHealth = boat:GetAttribute('MaxHealth') or 1
                local healthRatio = currentHealth / currentMaxHealth
                
                boat:SetAttribute('MaxHealth', baseMaxHealth)
                boat:SetAttribute('Health', baseMaxHealth * healthRatio)
                
                -- 通知BoatAttributeService更新UI
                local BoatAttributeService = Knit.GetService('BoatAttributeService')
                BoatAttributeService:ChangeBoatHealth(player, baseMaxHealth * healthRatio, baseMaxHealth)
            end
        end
    end
end

-- 获取伤害BUFF效果（供其他系统调用）
function BuffService:GetDamageMultiplier(player)
    if not playerBuffs[player.UserId] then
        return 1
    end
    
    local effect = calculateBuffEffect(player, "damage")
    return effect.multiplier
end

-- 添加BUFF
function BuffService:AddBuff(player, buffId, duration)
    initPlayerBuffs(player)
    
    local config = BuffConfig.GetBuffConfig(buffId)
    if not config then
        warn("BuffService: 未找到BUFF配置: " .. tostring(buffId))
        return false
    end
    
    if not playerBuffs[player.UserId][config.buffType] then
        warn("BuffService: 无效的BUFF类型: " .. tostring(config.buffType))
        return false
    end
    
    -- 添加BUFF数据
    playerBuffs[player.UserId][config.buffType][buffId] = {
        startTime = tick(),
        duration = duration or config.duration,
        config = config
    }
    
    -- 设置BUFF过期计时器
    local timerId = player.UserId .. "_" .. config.buffType .. "_" .. buffId
    if buffTimers[timerId] then
        pcall(task.cancel, buffTimers[timerId])
    end
    
    buffTimers[timerId] = task.delay(duration or config.duration, function()
        -- 清除计时器引用，避免在RemoveBuff中重复取消
        buffTimers[timerId] = nil
        self:RemoveBuff(player, buffId, config.buffType)
    end)
    
    -- 应用BUFF效果
    if config.buffType == "speed" then
        applySpeedBuff(player)
    elseif config.buffType == "health" then
        applyHealthBuff(player)
    end
    
    -- 通知客户端
    self.Client.BuffAdded:Fire(player, buffId, duration or config.duration)
    
    print("BuffService: 为玩家 " .. player.Name .. " 添加了BUFF: " .. buffId)
    return true
end

-- 移除BUFF
function BuffService:RemoveBuff(player, buffId)
    local config = BuffConfig.GetBuffConfig(buffId)
    if not config then
        warn("BuffService: 未找到BUFF配置: " .. tostring(buffId))
        return false
    end

    if not playerBuffs[player.UserId] or not playerBuffs[player.UserId][config.buffType] then
        return false
    end
    
    if not playerBuffs[player.UserId][config.buffType][buffId] then
        return false
    end
    
    -- 移除BUFF数据
    playerBuffs[player.UserId][config.buffType][buffId] = nil
    
    -- 清理计时器
    local timerId = player.UserId .. "_" .. config.buffType .. "_" .. buffId
    if buffTimers[timerId] then
        local timer = buffTimers[timerId]
        buffTimers[timerId] = nil
        pcall(task.cancel, timer)
    end
    
    -- 重新应用BUFF效果或还原到基础值
    if config.buffType == "speed" then
        -- 检查是否还有速度BUFF，如果有则重新应用，否则还原
        local hasSpeedBuffs = false
        if playerBuffs[player.UserId] and playerBuffs[player.UserId]["speed"] then
            for _, _ in pairs(playerBuffs[player.UserId]["speed"]) do
                hasSpeedBuffs = true
                break
            end
        end
        
        if hasSpeedBuffs then
            applySpeedBuff(player)
        else
            restoreBoatAttributes(player, "speed")
        end
    elseif config.buffType == "health" then
        -- 检查是否还有生命BUFF，如果有则重新应用，否则还原
        local hasHealthBuffs = false
        if playerBuffs[player.UserId] and playerBuffs[player.UserId]["health"] then
            for _, _ in pairs(playerBuffs[player.UserId]["health"]) do
                hasHealthBuffs = true
                break
            end
        end
        
        if hasHealthBuffs then
            applyHealthBuff(player)
        else
            restoreBoatAttributes(player, "health")
        end
    end
    
    -- 通知客户端
    self.Client.BuffRemoved:Fire(player, buffId)
    
    print("BuffService: 为玩家 " .. player.Name .. " 移除了BUFF: " .. buffId .. " (" .. config.buffType .. ")")
    return true
end

-- 获取玩家所有BUFF
function BuffService:GetPlayerBuffs(player)
    if not playerBuffs[player.UserId] then
        return {}
    end
    
    local result = {}
    for buffType, buffs in pairs(playerBuffs[player.UserId]) do
        result[buffType] = {}
        for buffId, buffData in pairs(buffs) do
            local remainingTime = buffData.duration - (tick() - buffData.startTime)
            if remainingTime > 0 then
                result[buffType][buffId] = {
                    remainingTime = remainingTime,
                    config = buffData.config
                }
            end
        end
    end
    
    return result
end

-- 客户端获取玩家BUFF
function BuffService.Client:GetPlayerBuffs(player)
    return self.Server:GetPlayerBuffs(player)
end

-- 清除玩家所有BUFF
function BuffService:ClearAllBuffs(player)
    if not playerBuffs[player.UserId] then
        return
    end
    
    for buffType, buffs in pairs(playerBuffs[player.UserId]) do
        for buffId, _ in pairs(buffs) do
            self:RemoveBuff(player, buffId, buffType)
        end
    end
end

-- 检查BUFF是否存在
function BuffService:HasBuff(player, buffId, buffType)
    if not playerBuffs[player.UserId] or not playerBuffs[player.UserId][buffType] then
        return false
    end
    
    return playerBuffs[player.UserId][buffType][buffId] ~= nil
end

function BuffService:KnitInit()
    print('BuffService initialized')
    
    -- 玩家加入时初始化BUFF数据
    local function playerAdded(player)
        initPlayerBuffs(player)
    end
    
    -- 玩家离开时清理BUFF数据
    local function playerRemoving(player)
        cleanupPlayerBuffs(player)
    end
    
    -- 为已存在的玩家初始化
    for _, player in Players:GetPlayers() do
        task.spawn(playerAdded, player)
    end
    
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)
end

function BuffService:KnitStart()
    print('BuffService started')
end

return BuffService