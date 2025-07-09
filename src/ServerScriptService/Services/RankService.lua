--[[
全服航行距离排行榜服务
负责管理跨所有服务器的玩家航行距离排行榜

功能:
- 跨服务器总航行距离排行榜
- 跨服务器单次最大航行距离排行榜
- 实时数据同步到全服排行榜
- 高效的数据查询和缓存

作者: Roblox海浪系统
版本: 1.0
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

-- 创建OrderedDataStore用于排行榜
local TotalDistanceLeaderboard = DataStoreService:GetOrderedDataStore("SailingTotalDistance")
--TotalDistanceLeaderboard:RemoveAsync(7689724124)
local MaxSingleDistanceLeaderboard = DataStoreService:GetOrderedDataStore("SailingMaxSingleDistance")
local TotalSailingTimeLeaderboard = DataStoreService:GetOrderedDataStore("SailingTotalTime")
local MaxSailingTimeLeaderboard = DataStoreService:GetOrderedDataStore("SailingMaxTime")

-- 创建普通DataStore用于玩家名称映射
local PlayerNameStore = DataStoreService:GetDataStore("PlayerNames")

local RankService = Knit.CreateService({
    Name = 'RankService',
    Client = {
        UpdateLeaderboard = Knit.CreateSignal(),
        InitPlayerSailingData = Knit.CreateSignal(),
        UpdatePlayerSailingData = Knit.CreateSignal(),
    },
    
    -- 服务器端数据
    playerSailingData = {}, -- 存储玩家当前航行数据
    leaderboardCache = {}, -- 排行榜缓存
    lastCacheUpdate = 0, -- 上次缓存更新时间
    pendingUpdates = {}, -- 待更新的数据队列
})

-- 配置参数
local UPDATE_INTERVAL = 1 -- 距离更新间隔（秒）
local CACHE_UPDATE_INTERVAL = 3600 -- 缓存更新间隔（秒）
local LEADERBOARD_SIZE = 15 -- 排行榜显示数量
local BATCH_UPDATE_INTERVAL = 30 -- 批量更新间隔（秒）

-- 初始化玩家航行数据
-- @param player Player 玩家对象
function RankService:InitPlayerSailingData(player)
    local userId = player.UserId
    
    -- 从数据库获取玩家航行数据
    local DBService = Knit.GetService('DBService')
    local totalDistance = DBService:Get(player.UserId, "TotalSailingDistance") or 0
    local maxSailingDistance = DBService:Get(player.UserId, "MaxSingleSailingDistance") or 0
    local totalSailingTime = DBService:Get(player.UserId, "TotalSailingTime") or 0
    local maxSailingTime = DBService:Get(player.UserId, "MaxSailingTime") or 0
    
    -- 初始化当前航行数据
    self.playerSailingData[userId] = {
        player = player,
        totalDistance = totalDistance,
        maxSailingDistance = maxSailingDistance,
        totalSailingTime = totalSailingTime,
        maxSailingTime = maxSailingTime,
        currentSailingDistance = 0, -- 当前航行距离
        currentSailingTime = 0, -- 当前航行时间（秒）
        lastPosition = nil, -- 上次位置
        isTracking = false, -- 是否正在追踪
        lastUpdateTime = tick(), -- 上次更新时间
    }
    
    -- 保存玩家名称到DataStore（用于排行榜显示）
    self:SavePlayerName(userId, player.Name)
    
    -- 如果玩家有现有数据，添加到待更新队列同步到OrderedDataStore
    if totalDistance > 0 or maxSailingDistance > 0 or totalSailingTime > 0 or maxSailingTime > 0 then
        self.pendingUpdates[userId] = {
            totalDistance = math.floor(totalDistance),
            maxSailingDistance = math.floor(maxSailingDistance),
            totalSailingTime = totalSailingTime,
            maxSailingTime = maxSailingTime,
            playerName = player.Name
        }
    end

    self.Client.InitPlayerSailingData:Fire(player, {
        totalDistance = math.floor(totalDistance),
        maxSailingDistance = math.floor(maxSailingDistance),
        totalSailingTime = totalSailingTime,
        maxSailingTime = maxSailingTime,
    })
end

function RankService:RemovePlayerSailingData(player)
    local userId = player.UserId
    if self.playerSailingData[userId] then
        -- 如果玩家在追踪中，保存当前航行数据
        if self.playerSailingData[userId].isTracking then
            self:StopTrackingPlayer(player)
        end
        
        -- 清理数据
        self.playerSailingData[userId] = nil
    end
end

-- 保存玩家名称到DataStore
-- @param userId number 玩家ID
-- @param playerName string 玩家名称
function RankService:SavePlayerName(userId, playerName)
    task.spawn(function()
        local success, err = pcall(function()
            PlayerNameStore:SetAsync(tostring(userId), playerName)
        end)
        
        if not success then
            warn("保存玩家名称失败:", playerName, err)
        end
    end)
end

-- 获取玩家名称
-- @param userId number 玩家ID
-- @return string 玩家名称
function RankService:GetPlayerName(userId)
    local success, playerName = pcall(function()
        return PlayerNameStore:GetAsync(tostring(userId))
    end)
    
    if success and playerName then
        return playerName
    else
        return "未知玩家" .. userId
    end
end

-- 开始追踪玩家航行距离
-- @param player Player 玩家对象
-- @param isRevive 是否重生
function RankService:StartTrackingPlayer(player, isRevive)
    local userId = player.UserId
    local data = self.playerSailingData[userId]
    
    if not data then
        self:InitPlayerSailingData(player)
        data = self.playerSailingData[userId]
    end
    
    if not data then
        warn("无法开始追踪玩家:", player.Name)
        return
    end
    
    -- 重置当前航行数据
    if not isRevive then
        data.currentSailingDistance = 0
        data.currentSailingTime = 0
    end
    data.isTracking = true
    data.lastUpdateTime = tick()
    data.lastPosition = nil
    if player.Character then
        data.lastPosition = player.Character:GetPivot().Position
    end
    
    -- 同步客户端航行数据
    self.Client.UpdatePlayerSailingData:Fire(player, {
        totalDistance = data.totalDistance,
        maxSailingDistance = data.maxSailingDistance,
        totalSailingTime = data.totalSailingTime,
        maxSailingTime = data.maxSailingTime,
        currentSailingDistance = data.currentSailingDistance,
        currentSailingTime = data.currentSailingTime,
    })
end

-- 停止追踪玩家航行距离
-- @param player Player 玩家对象
function RankService:StopTrackingPlayer(player)
    local userId = player.UserId
    local data = self.playerSailingData[userId]
    
    if not data or not data.isTracking then
        return
    end
    
    data.isTracking = false
    
    if player.Character and data.lastPosition then
        -- 更新最大单次航行距离
        local currentPosition = player.Character:GetPivot().Position
        -- 计算距离
        local distance = Vector3.new(currentPosition.X - data.lastPosition.X, 0, currentPosition.Z - data.lastPosition.Z).Magnitude
        
        -- 防止传送等异常移动（距离过大）
        if distance < 1000 and distance > 0.1 then
            data.totalDistance += distance
        end
    end
    data.maxSailingDistance = math.max(data.maxSailingDistance, data.currentSailingDistance)
    
    -- 计算航行时间
    local currentTime = tick()
    local stepTime = currentTime - data.lastUpdateTime
    data.currentSailingTime += stepTime * GameConfig.Real_To_Game_Second
    data.totalSailingTime += stepTime * GameConfig.Real_To_Game_Second
    -- 更新航行时间
    data.maxSailingTime = math.max(data.maxSailingTime, data.currentSailingTime)
    
    -- 保存到数据库
    local DBService = Knit.GetService('DBService')
    DBService:Set(player.UserId, "TotalSailingDistance", data.totalDistance)
    DBService:Set(player.UserId, "MaxSingleSailingDistance", data.maxSailingDistance)
    DBService:Set(player.UserId, "TotalSailingTime", data.totalSailingTime)
    DBService:Set(player.UserId, "MaxSailingTime", data.maxSailingTime)
    
    -- 添加到待更新队列（确保数据为整数类型）
    self.pendingUpdates[userId] = {
        totalDistance = math.floor(data.totalDistance),
        maxSailingDistance = math.floor(data.maxSailingDistance),
        totalSailingTime = data.totalSailingTime,
        maxSailingTime = data.maxSailingTime,
        playerName = player.Name
    }
    
    -- -- 重置当前航行数据
    -- data.currentSailingDistance = 0
    -- data.currentSailingTime = 0
    -- data.lastUpdateTime = 0
    -- data.lastPosition = nil
end

-- 更新玩家航行距离
-- @param player Player 玩家对象
function RankService:UpdatePlayerDistance(player)
    local userId = player.UserId
    local data = self.playerSailingData[userId]
    
    if not data or not data.isTracking then
        return
    end
    
    local currentTime = tick()
    local stepTime = currentTime - data.lastUpdateTime
    -- 限制更新频率
    if stepTime < UPDATE_INTERVAL then
        return
    end
    
    data.lastUpdateTime = currentTime
    
    local boat = Interface.GetBoatByPlayerUserId(userId)
    -- 获取玩家当前位置
    if not boat or boat:GetAttribute("Destroying") then
        return
    end
    
    if player.Character and data.lastPosition then
        local currentPosition = player.Character:GetPivot().Position
        -- 计算距离
        local distance = Vector3.new(currentPosition.X - data.lastPosition.X, 0, currentPosition.Z - data.lastPosition.Z).Magnitude
        
        -- 防止传送等异常移动（距离过大）
        if distance < 1000 and distance > 0.1 then
            data.currentSailingDistance += distance
            data.totalDistance += distance
        end
        -- 更新位置
        data.lastPosition = currentPosition
    end

    -- 计算本次航行时间（秒）
    data.currentSailingTime += stepTime * GameConfig.Real_To_Game_Second
    data.totalSailingTime += stepTime * GameConfig.Real_To_Game_Second

    -- 同步客户端航行数据
    self.Client.UpdatePlayerSailingData:Fire(player, {
        totalDistance = data.totalDistance,
        maxSailingDistance = data.maxSailingDistance,
        totalSailingTime = data.totalSailingTime,
        maxSailingTime = data.maxSailingTime,
        currentSailingDistance = data.currentSailingDistance,
        currentSailingTime = data.currentSailingTime,
    })
end

-- 批量更新全服排行榜
function RankService:BatchUpdateGlobalLeaderboard()
    if next(self.pendingUpdates) == nil then
        return
    end
    
    for userId, updateData in pairs(self.pendingUpdates) do
        task.spawn(function()
            -- 更新总距离排行榜
            pcall(function()
                TotalDistanceLeaderboard:SetAsync(userId, math.floor(updateData.totalDistance))
            end)
            
            -- 更新最大单次距离排行榜
            pcall(function()
                MaxSingleDistanceLeaderboard:SetAsync(userId, math.floor(updateData.maxSailingDistance))
            end)

            -- 更新总航行时间排行榜
            pcall(function()
                TotalSailingTimeLeaderboard:SetAsync(userId, math.floor(updateData.totalSailingTime))
            end)
            
            -- 更新最大航行时间排行榜
            pcall(function()
                MaxSailingTimeLeaderboard:SetAsync(userId, math.floor(updateData.maxSailingTime))
            end)
        end)
    end
    
    -- 清空待更新队列
    self.pendingUpdates = {}
end

-- 获取全服排行榜数据
-- @param leaderboardType string 排行榜类型 ("totalDis"、"maxDis"、"totalTime"、"maxTime")
-- @param limit number 获取数量限制
-- @return table 排行榜数据
function RankService:GetGlobalLeaderboardData(leaderboardType, limit)
    local dataStore
    if leaderboardType == "totalDis" then
        dataStore = TotalDistanceLeaderboard
    elseif leaderboardType == "maxDis" then
        dataStore = MaxSingleDistanceLeaderboard
    elseif leaderboardType == "totalTime" then
        dataStore = TotalSailingTimeLeaderboard
    elseif leaderboardType == "maxTime" then
        dataStore = MaxSailingTimeLeaderboard
    else
        return {leaderboard = {}, lastUpdate = tick()}
    end
    
    local success, pages = pcall(function()
        return dataStore:GetSortedAsync(false, limit)
    end)
    
    if not success then
        warn("获取全服排行榜失败:", leaderboardType, pages)
        return {leaderboard = {}, lastUpdate = tick()}
    end
    
    local leaderboard = {}
    local rank = 1
    
    while true do
        local success2, data = pcall(function()
            return pages:GetCurrentPage()
        end)
        
        if not success2 or not data then
            print("获取当前页面失败:", leaderboardType, data)
            break
        end
        
        for _, entry in pairs(data) do
            local userId = entry.key
            local value = entry.value
            local playerName = self:GetPlayerName(tonumber(userId))
            
            table.insert(leaderboard, {
                rank = rank,
                userId = userId,
                playerName = playerName,
                value = value,
            })
            
            rank = rank + 1
            
            if rank > limit then
                break
            end
        end
        
        if rank > limit then
            break
        end
        
        if pages.IsFinished then
            break
        end
        
        local success3 = pcall(function()
            pages:AdvanceToNextPageAsync()
        end)
        
        if not success3 then
            print("翻页失败:", leaderboardType)
            break
        end
    end
    
    return {
        leaderboard = leaderboard,
        lastUpdate = tick()
    }
end

-- 更新排行榜缓存
function RankService:UpdateLeaderboardCache()
    local currentTime = tick()
    
    -- 限制缓存更新频率
    if currentTime - self.lastCacheUpdate < CACHE_UPDATE_INTERVAL then
        return
    end
    
    self.lastCacheUpdate = currentTime
    
    -- 获取排行榜数据
    task.spawn(function()
        local totalDisLeaderboard = self:GetGlobalLeaderboardData("totalDis", LEADERBOARD_SIZE)
        local maxDisLeaderboard = self:GetGlobalLeaderboardData("maxDis", LEADERBOARD_SIZE)
        local totalTimeLeaderboard = self:GetGlobalLeaderboardData("totalTime", LEADERBOARD_SIZE)
        local maxTimeLeaderboard = self:GetGlobalLeaderboardData("maxTime", LEADERBOARD_SIZE)
        
        -- 更新缓存
        self.leaderboardCache = {
            totalDis = totalDisLeaderboard,
            maxDis = maxDisLeaderboard,
            totalTime = totalTimeLeaderboard,
            maxTime = maxTimeLeaderboard,
            lastUpdate = currentTime
        }
        
        -- 通知所有客户端更新排行榜
        self.Client.UpdateLeaderboard:FireAll(self.leaderboardCache)
    end)
end

function  RankService:GetPersonalData(player)
    local userId = player.UserId
    local data = self.playerSailingData[userId]
    return data
end

-- 获取玩家个人数据和排名
-- @param player Player 玩家对象
-- @return table 玩家数据
function RankService:GetPersonalDataWithRank(player)
    local userId = player.UserId
    local data = self.playerSailingData[userId]
    
    if not data then
        return
    end
    
    -- 获取排名（同步等待）
    local totalDisRank = GameConfig.TotalDistanceRank
    local maxDisRank = GameConfig.MaxDistanceRank
    local totalTimeRank = GameConfig.TotalTimeRank
    local maxTimeRank = GameConfig.MaxTimeRank
    
    -- 获取总距离排名
    local success1, totalRankData = pcall(function()
        return TotalDistanceLeaderboard:GetSortedAsync(false, 100)
    end)
    
    if success1 and totalRankData then
        local rank = 1
        while true do
            local success2, data2 = pcall(function()
                return totalRankData:GetCurrentPage()
            end)
            
            if not success2 or not data2 then
                break
            end
            
            for _, entry in pairs(data2) do
                if tonumber(entry.key) == userId then
                    totalDisRank = rank
                    break
                end
                rank = rank + 1
            end
            
            if totalDisRank < GameConfig.TotalDistanceRank or totalRankData.IsFinished then
                break
            end
            
            local success3 = pcall(function()
                totalRankData:AdvanceToNextPageAsync()
            end)
            
            if not success3 then
                break
            end
        end
    end
    
    -- 获取最大单次距离排名
    local success4, maxRankData = pcall(function()
        return MaxSingleDistanceLeaderboard:GetSortedAsync(false, 100)
    end)
    
    if success4 and maxRankData then
        local rank = 1
        while true do
            local success5, data5 = pcall(function()
                return maxRankData:GetCurrentPage()
            end)
            
            if not success5 or not data5 then
                break
            end
            
            for _, entry in pairs(data5) do
                if tonumber(entry.key) == userId then
                    maxDisRank = rank
                    break
                end
                rank = rank + 1
            end
            
            if maxDisRank < GameConfig.MaxDistanceRank or maxRankData.IsFinished then
                break
            end
            
            local success6 = pcall(function()
                maxRankData:AdvanceToNextPageAsync()
            end)
            
            if not success6 then
                break
            end
        end
    end
    
    -- 获取航行时间排名
    local success7, totalTimeRankData = pcall(function()
        return TotalSailingTimeLeaderboard:GetSortedAsync(false, 100)
    end)
    
    if success7 and totalTimeRankData then
        local rank = 1
        while true do
            local success8, data8 = pcall(function()
                return totalTimeRankData:GetCurrentPage()
            end)
            
            if not success8 or not data8 then
                break
            end
            
            for _, entry in pairs(data8) do
                if tonumber(entry.key) == userId then
                    totalTimeRank = rank
                    break
                end
                rank = rank + 1
            end
            
            if totalTimeRank < GameConfig.TotalTimeRank or totalTimeRankData.IsFinished then
                break
            end
            
            local success9 = pcall(function()
                totalTimeRankData:AdvanceToNextPageAsync()
            end)
            
            if not success9 then
                break
            end
        end
    end
    
    -- 获取航行天数排名
    local success10, maxTimeRankData = pcall(function()
        return MaxSailingTimeLeaderboard:GetSortedAsync(false, 100)
    end)
    
    if success10 and maxTimeRankData then
        local rank = 1
        while true do
            local success11, data11 = pcall(function()
                return maxTimeRankData:GetCurrentPage()
            end)
            
            if not success11 or not data11 then
                break
            end
            
            for _, entry in pairs(data11) do
                if tonumber(entry.key) == userId then
                    maxTimeRank = rank
                    break
                end
                rank = rank + 1
            end
            
            if maxTimeRank < GameConfig.MaxTimeRank or maxTimeRankData.IsFinished then
                break
            end
            
            local success12 = pcall(function()
                maxTimeRankData:AdvanceToNextPageAsync()
            end)
            
            if not success12 then
                break
            end
        end
    end
    
    return {
        totalDistance = data.totalDistance + data.currentSailingDistance,
        maxSailingDistance = math.max(data.maxSailingDistance, data.currentSailingDistance),
        totalSailingTime = data.totalSailingTime,
        maxSailingTime = math.max(data.maxSailingTime, data.currentSailingTime),
        totalDisRank = totalDisRank,
        maxDisRank = maxDisRank,
        totalTimeRank = totalTimeRank,
        maxTimeRank = maxTimeRank,
    }
end

-- 客户端请求排行榜数据
function RankService.Client:GetLeaderboard(player)
    local cache = self.Server.leaderboardCache
    if cache then
        return cache
    else
        local totalDisLeaderboard = self:GetGlobalLeaderboardData("totalDis", LEADERBOARD_SIZE)
        local maxDisLeaderboard = self:GetGlobalLeaderboardData("maxDis", LEADERBOARD_SIZE)
        local totalTimeLeaderboard = self:GetGlobalLeaderboardData("totalTime", LEADERBOARD_SIZE)
        local maxTimeLeaderboard = self:GetGlobalLeaderboardData("maxTime", LEADERBOARD_SIZE)
        -- 如果缓存为空，立即获取数据
        local data = {
            totalDis = totalDisLeaderboard,
            maxDis = maxDisLeaderboard,
            totalTime = totalTimeLeaderboard,
            maxTime = maxTimeLeaderboard,
        }
        return data
    end
end

-- 客户端请求个人数据
function RankService.Client:GetPersonalData(player)
    local data = self.Server:GetPersonalDataWithRank(player)
    return data
end

-- 服务启动时初始化
function RankService:KnitStart()
    -- 启动距离更新循环
    RunService.Heartbeat:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            self:UpdatePlayerDistance(player)
        end
    end)
    
    -- 定期批量更新全服排行榜
    local handler1
    handler1 = task.spawn(function()
        while true do
            task.wait(BATCH_UPDATE_INTERVAL)
            self:BatchUpdateGlobalLeaderboard()
        end
    end)
    
    -- 定期更新排行榜缓存
    local handler2
    handler2 = task.spawn(function()
        while true do
            task.wait(CACHE_UPDATE_INTERVAL)
            self:UpdateLeaderboardCache()
        end
    end)
    
    -- 初始化排行榜缓存
    self:UpdateLeaderboardCache()

    -- 在服务器关闭时保存排行榜数据
    game:BindToClose(function()
        task.cancel(handler1)
        task.cancel(handler2)
        self:BatchUpdateGlobalLeaderboard()
    end)
end

return RankService