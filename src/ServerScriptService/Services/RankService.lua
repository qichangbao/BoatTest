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

-- 创建OrderedDataStore用于排行榜
local TotalDistanceLeaderboard = DataStoreService:GetOrderedDataStore("SailingTotalDistance")
TotalDistanceLeaderboard:RemoveAsync(7689724124)
local MaxSingleDistanceLeaderboard = DataStoreService:GetOrderedDataStore("SailingMaxSingleDistance")
MaxSingleDistanceLeaderboard:RemoveAsync(7689724124)
local TotalSailingTimeLeaderboard = DataStoreService:GetOrderedDataStore("SailingTotalTime")
TotalSailingTimeLeaderboard:RemoveAsync(7689724124)
local MaxSailingTimeLeaderboard = DataStoreService:GetOrderedDataStore("SailingMaxTime")
MaxSailingTimeLeaderboard:RemoveAsync(7689724124)

-- 创建普通DataStore用于玩家名称映射
local PlayerNameStore = DataStoreService:GetDataStore("PlayerNames")

local RankService = Knit.CreateService({
    Name = 'RankService',
    Client = {
        UpdateLeaderboard = Knit.CreateSignal(),
    },
    
    -- 服务器端数据
    playerSailingData = {}, -- 存储玩家当前航行数据
    leaderboardCache = {}, -- 排行榜缓存
    lastCacheUpdate = 0, -- 上次缓存更新时间
    pendingUpdates = {}, -- 待更新的数据队列
})

-- 配置参数
local UPDATE_INTERVAL = 1 -- 距离更新间隔（秒）
local CACHE_UPDATE_INTERVAL = 30 -- 缓存更新间隔（秒）
local LEADERBOARD_SIZE = 100 -- 排行榜显示数量
local BATCH_UPDATE_INTERVAL = 5 -- 批量更新间隔（秒）

-- 初始化玩家航行数据
-- @param player Player 玩家对象
function RankService:InitPlayerSailingData(player)
    local userId = player.UserId
    
    -- 从数据库获取玩家航行数据
    local DBService = Knit.GetService('DBService')
    local totalDistance = DBService:Get(player.UserId, "TotalSailingDistance") or 0
    local maxSingleDistance = DBService:Get(player.UserId, "MaxSingleSailingDistance") or 0
    local totalSailingTime = DBService:Get(player.UserId, "TotalSailingTime") or 0
    local maxSailingTime = DBService:Get(player.UserId, "MaxSailingTime") or 0
    
    -- 初始化当前航行数据
    self.playerSailingData[userId] = {
        player = player,
        totalDistance = totalDistance,
        maxSingleDistance = maxSingleDistance,
        totalSailingTime = totalSailingTime,
        maxSailingTime = maxSailingTime,
        currentSailingDistance = 0, -- 当前航行距离
        currentSailingTime = 0, -- 当前航行时间（秒）
        lastPosition = nil, -- 上次位置
        isTracking = false, -- 是否正在追踪
        lastUpdateTime = tick(), -- 上次更新时间
        trackingStartTime = 0, -- 开始追踪时间
    }
    
    -- 保存玩家名称到DataStore（用于排行榜显示）
    self:SavePlayerName(userId, player.Name)
    
    -- 如果玩家有现有数据，添加到待更新队列同步到OrderedDataStore
    if totalDistance > 0 or maxSingleDistance > 0 or totalSailingTime > 0 or maxSailingTime > 0 then
        self.pendingUpdates[userId] = {
            totalDistance = math.floor(totalDistance),
            maxSingleDistance = math.floor(maxSingleDistance),
            totalSailingTime = totalSailingTime,
            maxSailingTime = maxSailingTime,
            playerName = player.Name
        }
        print("📤 已将现有数据添加到待更新队列:", player.Name, "总距离:", math.floor(totalDistance), "最大单次:", math.floor(maxSingleDistance), "总航行天数:", totalSailingTime / (24 * 3600), "航行天数:", maxSailingTime / (24 * 3600))
    end
    
    print("🏃 初始化玩家航行数据:", player.Name, "总距离:", totalDistance, "最大单次:", maxSingleDistance, "总航行天数:", totalSailingTime / (24 * 3600), "航行天数:", maxSailingTime / (24 * 3600))
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
function RankService:StartTrackingPlayer(player)
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
    data.currentSailingDistance = 0
    data.currentSailingTime = 0
    data.isTracking = true
    data.lastPosition = nil
    data.lastUpdateTime = tick()
    data.trackingStartTime = tick()
    
    -- 获取初始位置
    if player.Character and player.Character.PrimaryPart then
        data.lastPosition = player.Character.PrimaryPart.Position
    end
    
    print("🚢 开始追踪玩家航行:", player.Name)
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
    
    -- 计算本次航行时间（秒）
    local currentTime = tick()
    data.currentSailingTime = currentTime - data.trackingStartTime
    
    -- 更新总航行距离
    data.totalDistance += data.currentSailingDistance
    -- 更新最大单次航行距离
    if data.currentSailingDistance > data.maxSingleDistance then
        data.maxSingleDistance = data.currentSailingDistance
    end
    
    -- 计算航行时间
    data.totalSailingTime += data.currentSailingTime * GameConfig.Real_To_Game_Second
    -- 更新航行时间
    if data.currentSailingTime * GameConfig.Real_To_Game_Second > data.maxSailingTime then
        data.maxSailingTime = data.currentSailingTime * GameConfig.Real_To_Game_Second
    end
    
    -- 保存到数据库
    local DBService = Knit.GetService('DBService')
    DBService:Set(player.UserId, "TotalSailingDistance", data.totalDistance)
    DBService:Set(player.UserId, "MaxSingleSailingDistance", data.maxSingleDistance)
    DBService:Set(player.UserId, "TotalSailingTime", data.totalSailingTime)
    DBService:Set(player.UserId, "MaxSailingTime", data.maxSailingTime)
    
    -- 添加到待更新队列（确保数据为整数类型）
    self.pendingUpdates[userId] = {
        totalDistance = math.floor(data.totalDistance),
        maxSingleDistance = math.floor(data.maxSingleDistance),
        totalSailingTime = data.totalSailingTime,
        maxSailingTime = data.maxSailingTime,
        playerName = player.Name
    }
    
    print("🏁 停止追踪玩家航行:", player.Name, 
          "本次距离:", math.floor(data.currentSailingDistance), 
          "总距离:", math.floor(data.totalDistance),
          "最大单次:", math.floor(data.maxSingleDistance),
          "总航行天数:", string.format("%.2f天", data.totalSailingTime / (24 * 3600)),
          "航行天数:", string.format("%.2f天", data.maxSailingTime / (24 * 3600))
        )
    
    -- 重置当前航行数据
    data.currentSailingDistance = 0
    data.currentSailingTime = 0
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
    
    -- 限制更新频率
    if currentTime - data.lastUpdateTime < UPDATE_INTERVAL then
        return
    end
    
    data.lastUpdateTime = currentTime
    
    -- 获取玩家当前位置
    if not player.Character or not player.Character.PrimaryPart then
        return
    end
    
    local currentPosition = player.Character.PrimaryPart.Position
    
    -- 如果有上次位置，计算距离
    if data.lastPosition then
        local distance = (currentPosition - data.lastPosition).Magnitude
        
        -- 防止传送等异常移动（距离过大）
        if distance < 1000 and distance > 0.1 then
            data.currentSailingDistance = data.currentSailingDistance + distance
        end
    end
    
    -- 更新位置
    data.lastPosition = currentPosition
end

-- 批量更新全服排行榜
function RankService:BatchUpdateGlobalLeaderboard()
    if next(self.pendingUpdates) == nil then
        return
    end
    
    local updateCount = 0
    for _ in pairs(self.pendingUpdates) do
        updateCount = updateCount + 1
    end
    
    for userId, updateData in pairs(self.pendingUpdates) do
        task.spawn(function()
            -- 更新总距离排行榜（确保数据为整数类型）
            local success1, err1 = pcall(function()
                TotalDistanceLeaderboard:SetAsync(userId, math.floor(updateData.totalDistance))
            end)
            
            -- 更新最大单次距离排行榜（确保数据为整数类型）
            local success2, err2 = pcall(function()
                MaxSingleDistanceLeaderboard:SetAsync(userId, math.floor(updateData.maxSingleDistance))
            end)

            -- 更新航行时间排行榜（将小数乘以100存储为整数以保留精度）
            local success3, err3 = pcall(function()
                TotalSailingTimeLeaderboard:SetAsync(userId, math.floor(updateData.totalSailingTime))
            end)
            
            -- 更新航行时间排行榜（将小数乘以100存储为整数以保留精度）
            local success4, err4 = pcall(function()
                MaxSailingTimeLeaderboard:SetAsync(userId, math.floor(updateData.maxSailingTime))
            end)
            
            if success1 and success2 and success3 and success4 then
                print("✅ 更新全服排行榜成功:", updateData.playerName, "总距离:", math.floor(updateData.totalDistance), "最大单次:", math.floor(updateData.maxSingleDistance), "总航行天数:", updateData.totalSailingTime / (24 * 3600), "航行天数:", updateData.maxSailingTime / (24 * 3600))
            else
                warn("❌ 更新全服排行榜失败:", updateData.playerName, "错误:", err1 or err2 or err3 or err4)
            end
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
    limit = limit or LEADERBOARD_SIZE
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
        warn("❌ 获取全服排行榜失败:", leaderboardType, pages)
        return {leaderboard = {}, lastUpdate = tick()}
    end
    
    local leaderboard = {}
    local rank = 1
    
    while true do
        local success2, data = pcall(function()
            return pages:GetCurrentPage()
        end)
        
        if not success2 or not data then
            print("❌ 获取当前页面失败:", leaderboardType, data)
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
            print("❌ 翻页失败:", leaderboardType)
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
        local totalDisLeaderboard = self:GetGlobalLeaderboardData("totalDis", 50)
        local maxDisLeaderboard = self:GetGlobalLeaderboardData("maxDis", 50)
        local totalTimeLeaderboard = self:GetGlobalLeaderboardData("totalTime", 50)
        local maxTimeLeaderboard = self:GetGlobalLeaderboardData("maxTime", 50)
        
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
        
        print("📊 全服排行榜缓存已更新")
    end)
end

-- 获取玩家个人数据和排名
-- @param player Player 玩家对象
-- @return table 玩家数据
function RankService:GetPersonalDataWithRank(player)
    local userId = player.UserId
    local data = self.playerSailingData[userId]
    
    if not data then
        self:InitPlayerSailingData(player)
        data = self.playerSailingData[userId]
    end
    
    if not data then
        return {
            totalDistance = 0,
            maxSingleDistance = 0,
            currentSailingDistance = 0,
            totalSailingTime = 0,
            maxSailingTime = 0,
            currentSailingTime = 0,
            totalDisRank = 0,
            maxDisRank = 0,
            totalTimeRank = 0,
            maxTimeRank = 0,
            isTracking = false
        }
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
    
    print("🏆 获取玩家排名:", player.Name, "总距离排名:", totalDisRank, "最大单次排名:", maxDisRank, "总航行天数排名:", totalTimeRank, "航行天数排名:", maxTimeRank)
    
    return {
        totalDistance = data.totalDistance + data.currentSailingDistance,
        maxSingleDistance = math.max(data.maxSingleDistance, data.currentSailingDistance),
        currentSailingDistance = data.currentSailingDistance,
        totalSailingTime = data.totalSailingTime,
        maxSailingTime = math.max(data.maxSailingTime, data.currentSailingTime),
        currentSailingTime = data.currentSailingTime,
        totalDisRank = totalDisRank,
        maxDisRank = maxDisRank,
        totalTimeRank = totalTimeRank,
        maxTimeRank = maxTimeRank,
        isTracking = data.isTracking
    }
end

-- 客户端请求排行榜数据
function RankService.Client:GetLeaderboard(player, leaderboardType)
    local cache = self.Server.leaderboardCache[leaderboardType or "totalDis"]
    if cache then
        return cache
    else
        -- 如果缓存为空，立即获取数据
        local data = self.Server:GetGlobalLeaderboardData(leaderboardType or "totalDis", 50)
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
    task.spawn(function()
        while true do
            task.wait(BATCH_UPDATE_INTERVAL)
            self:BatchUpdateGlobalLeaderboard()
        end
    end)
    
    -- 定期更新排行榜缓存
    task.spawn(function()
        while true do
            task.wait(CACHE_UPDATE_INTERVAL)
            self:UpdateLeaderboardCache()
        end
    end)
    
    -- 初始化排行榜缓存
    task.wait(2)
    self:UpdateLeaderboardCache()
    
    print("🌍 全服航行距离排行榜服务已启动")
end

return RankService