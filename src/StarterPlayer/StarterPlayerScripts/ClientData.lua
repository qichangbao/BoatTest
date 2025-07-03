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
    totalDistance = 0,          -- 总航行距离
    maxSailingDistance = 0,      -- 单次最大距离
    totalSailingTime = 0,       -- 总航行时间（秒）
    maxSailingTime = 0,         -- 单次最长时间（秒）
    currentSailingDistance = 0, -- 当前航行距离
    currentSailingTime = 0,    -- 当前航行时间
    totalDisRank = 0,           -- 总航行距离排名
    maxDisRank = 0,             -- 单次最大距离排名
    totalTimeRank = 0,          -- 总航行时间排名
    maxTimeRank = 0,            -- 单次最长时间排名
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
        ClientData.PersonRankData.totalDistance = personalData.totalDistance or ClientData.PersonRankData.totalDistance
        ClientData.PersonRankData.maxSailingDistance = personalData.maxSailingDistance or ClientData.PersonRankData.maxSailingDistance
        ClientData.PersonRankData.totalSailingTime = personalData.totalSailingTime or ClientData.PersonRankData.totalSailingTime
        ClientData.PersonRankData.maxSailingTime = personalData.maxSailingTime or ClientData.PersonRankData.maxSailingTime
        ClientData.PersonRankData.currentSailingDistance = personalData.currentSailingDistance or ClientData.PersonRankData.currentSailingDistance
        ClientData.PersonRankData.currentSailingTime = personalData.currentSailingTime or ClientData.PersonRankData.currentSailingTime
        ClientData.PersonRankData.totalDisRank = personalData.totalDisRank or ClientData.PersonRankData.totalDisRank
        ClientData.PersonRankData.maxDisRank = personalData.maxDisRank or ClientData.PersonRankData.maxDisRank
        ClientData.PersonRankData.totalTimeRank = personalData.totalTimeRank or ClientData.PersonRankData.totalTimeRank
        ClientData.PersonRankData.maxTimeRank = personalData.maxTimeRank or ClientData.PersonRankData.maxTimeRank
    end
end

Knit:OnStart():andThen(function()
    Players.LocalPlayer.CharacterAdded:Connect(function()
        local humanoid = Players.LocalPlayer.Character:FindFirstChild('Humanoid')
        -- 监听玩家死亡事件
        humanoid.Died:Connect(function()
            Knit.GetController('UIController').ShowMessageBox:Fire({
                Content = LanguageConfig.Get(10096),
                ConfirmText = LanguageConfig.Get(10097),
                CancelText = LanguageConfig.Get(10098),
                OnConfirm = function()
                    Knit.GetService('PlayerAttributeService'):BuyRevive():andThen(function()
                        
                    end)
                end,
                OnCancel = function()
                    Knit.GetService('PlayerAttributeService'):DeclineRevive():andThen(function()
                        
                    end)
                end,
                ConfirmHide = false,
                CloseButtonVisible = false,
            })
        end)
    end)

    -- 监听金币变化
    Players.LocalPlayer:GetAttributeChangedSignal('Gold'):Connect(function()
        ClientData.Gold = tonumber(Players.LocalPlayer:GetAttribute('Gold'))
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end)
    ClientData.Gold = tonumber(Players.LocalPlayer:GetAttribute('Gold') or 0)
    if ClientData.Gold ~= 0 then
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end

    Knit.GetService('PlayerAttributeService'):GetLoginData():andThen(function(data)
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

    Knit.GetService('SystemService').IsLandOwnerChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = {userId = data.userId, playerName = data.playerName}
        Knit.GetController('UIController').IsLandOwnerChanged:Fire(data.landName, data.playerName)
    end)
    Knit.GetService('SystemService').IsLandInfoChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = data.isLandData
    end)

    Knit.GetService('InventoryService').AddItem:Connect(function(itemData)
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
    Knit.GetService('InventoryService').RemoveItem:Connect(function(modelName, itemName)
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
    Knit.GetService('InventoryService').InitInventory:Connect(function(inventoryData)
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
    Knit.GetService('BuffService').BuffAdded:Connect(function(buffId, duration)
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
    Knit.GetService('BuffService').BuffRemoved:Connect(function(buffId)
        ClientData.ActiveBuffs[buffId] = nil
        Knit.GetController('UIController').BuffChanged:Fire()
    end)
    -- 获取初始BUFF状态
    Knit.GetService('BuffService'):GetPlayerBuffs(Players.LocalPlayer):andThen(function(initialBuffs)
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
    Knit.GetService('ChestService').RewardReceived:Connect(function(rewardType, rewardData)
        -- 播放飞行特效
        if rewardData and rewardData.chestPosition then
            local RewardFlyEffect = require(game:GetService('StarterGui'):WaitForChild('RewardFlyEffect'))
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
    Knit.GetService("RankService").UpdatePlayerSailingData:Connect(function(leaderboardData)
        updatePersonalRanKData(leaderboardData)
    end)
    
    -- 启动时间更新循环
    RunService.Heartbeat:Connect(function()
        updateRemainingTimes()
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