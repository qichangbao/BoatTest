local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local BuffConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BuffConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local ClientData = {}
ClientData.Gold = 0                 -- 玩家金币
ClientData.InventoryItems = {}      -- 玩家背包物品
ClientData.IsAdmin = false          -- 是否为管理员
ClientData.IsLandOwners = {}        -- 所有土地的拥有者
ClientData.ActiveBuffs = {}         -- 当前激活的BUFF
ClientData.IsBoatAssembling = false -- 是否正在组装船
ClientData.IsOnBoat = false         -- 是否在船上

ClientData.RankData = {}
-- 排行榜个人数据
ClientData.PersonRankData = {
    -- 服务器同步的历史数据
    serverData = {
        totalDistance = 0,          -- 总航行距离
        maxSingleDistance = 0,      -- 单次最大距离
        totalSailingTime = 0,       -- 总航行时间（秒）
        maxSailingTime = 0,         -- 单次最长时间（秒）
        totalDisRank = 0,           -- 总航行距离排名
        maxDisRank = 0,             -- 单次最大距离排名
        totalTimeRank = 0,          -- 总航行时间排名
        maxTimeRank = 0,            -- 单次最长时间排名
    },
    -- 当前航行数据（客户端实时计算）
    currentData = {
        distance = 0,               -- 当前航行距离
        sailingTime = 0,            -- 当前航行时间（秒）
        startTime = 0,              -- 开始航行时间
        lastPosition = nil,         -- 上次位置
        isOnBoat = false            -- 是否在船上
    }
}

-- 更新buff剩余时间函数
local function updateRemainingTimes()
    local currentTime = tick()
    
    for buffKey, buffData in pairs(ClientData.ActiveBuffs) do
        local elapsed = currentTime - buffData.startTime
        local newRemainingTime = math.max(0, buffData.remainingTime - elapsed)
        
        if newRemainingTime <= 0 then
            -- BUFF过期，移除
            ClientData.ActiveBuffs[buffKey] = nil
        else
            -- 重置开始时间以避免累积误差
            buffData.startTime = currentTime
            buffData.remainingTime = newRemainingTime
        end
    end
end

local function updatePersonalRanKData(personalData)
    if personalData then
        local serverData = ClientData.PersonRankData.serverData
        serverData.totalDistance = personalData.totalDistance or 0
        serverData.maxSingleDistance = personalData.maxSingleDistance or 0
        serverData.totalSailingTime = personalData.totalSailingTime or 0
        serverData.maxSailingTime = personalData.maxSailingTime or 0
        serverData.totalDisRank = personalData.totalDisRank or 0
        serverData.maxDisRank = personalData.maxDisRank or 0
        serverData.totalTimeRank = personalData.totalTimeRank or 0
        serverData.maxTimeRank = personalData.maxTimeRank or 0
    end
end

-- 更新排行榜数据函数
local function updateRankData()
    local currentTime = tick()
    local boat = Interface.GetBoatByPlayerUserId(Players.LocalPlayer.UserId)
    if not boat or boat:GetAttribute("Destroying") then return end
    
    local currentData = ClientData.PersonRankData.currentData
    
    -- 如果刚上船，初始化数据
    if ClientData.IsOnBoat and not currentData.isOnBoat then
        currentData.isOnBoat = true
        currentData.startTime = currentTime
        currentData.distance = 0
        currentData.sailingTime = 0
        currentData.lastPosition = boat:GetPivot().Position
    
        -- 初始化排行榜数据同步
        Knit.GetService('RankService'):GetPersonalData():andThen(function(personalData)
            updatePersonalRanKData(personalData)
        end):catch(warn)
    -- 如果刚下船，重置数据
    elseif not ClientData.IsOnBoat and currentData.isOnBoat then
        currentData.isOnBoat = false
        currentData.distance = 0
        currentData.sailingTime = 0
        currentData.lastPosition = nil
    -- 如果在船上，更新数据
    elseif ClientData.IsOnBoat and currentData.isOnBoat then
        -- 更新航行时间
        currentData.sailingTime = currentTime - currentData.startTime
        
        -- 更新航行距离
        if currentData.lastPosition then
            local currentPosition = boat:GetPivot().Position
            local distance = Vector3.new(currentPosition.X - currentData.lastPosition.X, 0, currentPosition.Z - currentData.lastPosition.Z).Magnitude
            currentData.distance = currentData.distance + distance
            currentData.lastPosition = currentPosition
        else
            currentData.lastPosition = boat:GetPivot().Position
        end
    end
end

Knit:OnStart():andThen(function()
    Players.LocalPlayer:GetAttributeChangedSignal('Gold'):Connect(function()
        ClientData.Gold = tonumber(Players.LocalPlayer:GetAttribute('Gold'))
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end)
    ClientData.Gold = tonumber(Players.LocalPlayer:GetAttribute('Gold')) or 0
    if ClientData.Gold ~= 0 then
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end

    local PlayerAttributeService = Knit.GetService('PlayerAttributeService')
    PlayerAttributeService:GetLoginData():andThen(function(data)
        ClientData.Gold = data.Gold
        Knit.GetController('UIController').UpdateGoldUI:Fire()
        
        ClientData.InventoryItems = {}
        for _, itemData in pairs(data.PlayerInventory) do
            table.insert(ClientData.InventoryItems, itemData)
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()

        ClientData.IsAdmin = data.isAdmin
        if ClientData.IsAdmin then
            Knit.GetController('UIController').IsAdmin:Fire()
        end

        ClientData.IsLandOwners = data.IsLandOwners
        Knit.GetController('UIController').IsLandOwner:Fire()
    end):catch(warn)

    local SystemService = Knit.GetService('SystemService')
    SystemService.IsLandOwnerChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = {userId = data.userId, playerName = data.playerName}
        Knit.GetController('UIController').IsLandOwnerChanged:Fire(data.landName, data.playerName)
    end)
    SystemService.IsLandInfoChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = data.isLandData
    end)

    local InventoryService = Knit.GetService('InventoryService')
    InventoryService.AddItem:Connect(function(itemData)
        local isExist = false
        for _, item in ipairs(ClientData.InventoryItems) do
            if item.itemName == itemData.itemName and item.modelName == itemData.modelName then
                item.num = itemData.num
                isExist = true
                break
            end
        end
    
        if not isExist then
            table.insert(ClientData.InventoryItems, itemData)
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10011), itemData.itemName))
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
    InventoryService.RemoveItem:Connect(function(modelName, itemName)
        local isExist = false
        for _, item in ipairs(ClientData.InventoryItems) do
            if item.itemName == itemName and item.modelName == modelName then
                if item.num > 1 then
                    item.num = item.num - 1
                else
                    table.remove(ClientData.InventoryItems, item)
                end
                isExist = true
                break
            end
        end
    
        if isExist then
            Knit.GetController('UIController').UpdateInventoryUI:Fire()
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10012), itemName))
    end)
    InventoryService.InitInventory:Connect(function(inventoryData)
        ClientData.InventoryItems = {}
        for _, itemData in pairs(inventoryData) do
            table.insert(ClientData.InventoryItems, itemData)
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)

    Knit.GetService('BoatAssemblingService').UpdateInventory:Connect(function(modelName)
        for _, item in pairs(ClientData.InventoryItems) do
            if item.modelName == modelName then
                item.isUsed = 1
            end
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)

    -- BUFF系统事件监听
    local BuffService = Knit.GetService('BuffService')
    BuffService.BuffAdded:Connect(function(buffId, duration)
        local config = BuffConfig.GetBuffConfig(buffId)
        ClientData.ActiveBuffs[buffId] = {
            buffId = buffId,
            remainingTime = duration,
            startTime = tick(),
            config = config
        }

        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10011), config.displayName))
        Knit.GetController('UIController').BuffChanged:Fire()
    end)
    BuffService.BuffRemoved:Connect(function(buffId)
        ClientData.ActiveBuffs[buffId] = nil
        Knit.GetController('UIController').BuffChanged:Fire()
    end)
    -- 获取初始BUFF状态
    BuffService:GetPlayerBuffs(Players.LocalPlayer):andThen(function(initialBuffs)
        if initialBuffs and type(initialBuffs) == "table" then
            for buffType, buffs in pairs(initialBuffs) do
                if type(buffs) == "table" then
                    for buffId, buffData in pairs(buffs) do
                        if buffData and buffData.remainingTime then
                            local config = BuffConfig.GetBuffConfig(buffId)
                            ClientData.ActiveBuffs[buffId] = {
                                buffId = buffId,
                                remainingTime = buffData.remainingTime,
                                startTime = tick(),
                                config = config
                            }
                        end
                    end
                end
            end
        end
    end):catch(warn)

    -- 监听宝箱奖励事件
    local chestService = Knit.GetService('ChestService')
    local RewardFlyEffect = require(game:GetService('StarterGui'):WaitForChild('RewardFlyEffect'))
    
    chestService.RewardReceived:Connect(function(rewardType, rewardData)
        -- 播放飞行特效
        if rewardData and rewardData.chestPosition then
            RewardFlyEffect.PlayEffect(rewardType, rewardData.chestPosition)
        end
        
        if rewardType == "Gold" then
            Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig.Get(10011), rewardData.amount) .. LanguageConfig.Get(10007))
            return
        elseif rewardType == "" then
            Knit.GetController('UIController').ShowTip:Fire(10051)
        end
    end)
    
    -- 监听排行榜更新信号
    Knit.GetService('RankService').GetLeaderboard("totalDis"):andThen(function(leaderboardData)
        ClientData.RankData.totalDis = leaderboardData
    end):catch(warn)
    Knit.GetService('RankService').GetLeaderboard("maxDis"):andThen(function(leaderboardData)
        ClientData.RankData.maxDis = leaderboardData
    end):catch(warn)
    Knit.GetService('RankService').GetLeaderboard("totalTime"):andThen(function(leaderboardData)
        ClientData.RankData.totalTime = leaderboardData
    end):catch(warn)
    Knit.GetService('RankService').GetLeaderboard("maxTime"):andThen(function(leaderboardData)
        ClientData.RankData.maxTime = leaderboardData
    end):catch(warn)
    Knit.GetService('RankService').UpdateLeaderboard:Connect(function(leaderboardData)
        ClientData.RankData = leaderboardData
    end)
    -- 初始化排行榜数据同步
    Knit.GetService("RankService").InitPlayerSailingData:Connect(function(personalData)
        updatePersonalRanKData(personalData)
    end)
    
    -- 启动时间更新循环
    RunService.Heartbeat:Connect(function()
        updateRemainingTimes()
        updateRankData()  -- 每帧更新排行榜数据
    end)

    local success = false
    while true do
        Knit.GetService('RankService'):GetPersonalData():andThen(function(personalData)
            if personalData then
                updatePersonalRanKData(personalData)
                success = true
            end
        end):catch(warn)
        if success then
            break
        end
        task.wait(3)
    end
end):catch(warn)

return ClientData