--[[
    改进版ClientData - 使用通用数据重试工具
    展示如何使用DataRetryUtil来简化和标准化数据获取逻辑
]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local BuffConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BuffConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
local DataRetryUtil = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("DataRetryUtil"))

local ClientData = {}
ClientData.Gold = 0
ClientData.InventoryItems = {}
ClientData.IsAdmin = false
ClientData.IsLandOwners = {}
ClientData.ActiveBuffs = {}
ClientData.IsBoatAssembling = false
ClientData.IsOnBoat = false
ClientData.RankData = {}

-- 排行榜个人数据
ClientData.PersonRankData = {
    totalDistance = 0,
    maxSailingDistance = 0,
    totalSailingTime = 0,
    maxSailingTime = 0,
    currentSailingDistance = 0,
    currentSailingTime = 0,
    totalDisRank = 0,
    maxDisRank = 0,
    totalTimeRank = 0,
    maxTimeRank = 0,
}

-- 更新buff剩余时间函数
local function updateRemainingTimes()
    local currentTime = tick()
    
    for buffKey, buffData in pairs(ClientData.ActiveBuffs) do
        local elapsed = currentTime - buffData.startTime
        local newRemainingTime = math.max(0, buffData.remainingTime - elapsed)
        
        if newRemainingTime <= 0 then
            ClientData.ActiveBuffs[buffKey] = nil
        else
            buffData.startTime = currentTime
            buffData.remainingTime = newRemainingTime
        end
    end
end

-- 使用通用工具更新个人排行榜数据
local function updatePersonalRankData(personalData)
    local fieldMappings = {
        totalDistance = "totalDistance",
        maxSailingDistance = "maxSailingDistance",
        totalSailingTime = "totalSailingTime",
        maxSailingTime = "maxSailingTime",
        currentSailingDistance = "currentSailingDistance",
        currentSailingTime = "currentSailingTime",
        totalDisRank = "totalDisRank",
        maxDisRank = "maxDisRank",
        totalTimeRank = "totalTimeRank",
        maxTimeRank = "maxTimeRank"
    }
    
    DataRetryUtil.SafeUpdateNumbers(ClientData.PersonRankData, personalData, fieldMappings)
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

    -- 系统服务事件监听
    Knit.GetService('SystemService').IsLandOwnerChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = {userId = data.userId, playerName = data.playerName}
        Knit.GetController('UIController').IsLandOwnerChanged:Fire(data.landName, data.playerName)
    end)
    
    Knit.GetService('SystemService').IsLandInfoChanged:Connect(function(data)
        ClientData.IsLandOwners[data.landName] = data.isLandData
    end)

    -- 背包服务事件监听
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
        for i, item in ipairs(ClientData.InventoryItems) do
            if item.itemName == itemName and item.modelName == modelName then
                if item.num > 1 then
                    item.num = item.num - 1
                else
                    table.remove(ClientData.InventoryItems, i)
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

    -- 监听宝箱奖励事件
    Knit.GetService('ChestService').RewardReceived:Connect(function(rewardType, rewardData)
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
    
    -- 排行榜更新事件监听（添加数据验证）
    Knit.GetService('RankService').UpdateLeaderboard:Connect(function(leaderboardData)
        if leaderboardData and type(leaderboardData) == "table" then
            ClientData.RankData = leaderboardData
            print("客户端排行榜数据更新:", leaderboardData)
            Knit.GetController('UIController').UpdateRankUI:Fire()
        else
            warn("接收到的排行榜数据格式错误")
        end
    end)
    
    -- 个人航行数据事件监听（添加数据验证）
    Knit.GetService("RankService").InitPlayerSailingData:Connect(function(personalData)
        if personalData and type(personalData) == "table" then
            updatePersonalRankData(personalData)
        else
            warn("初始化个人航行数据格式错误")
        end
    end)
    
    Knit.GetService("RankService").UpdatePlayerSailingData:Connect(function(leaderboardData)
        if leaderboardData and type(leaderboardData) == "table" then
            updatePersonalRankData(leaderboardData)
        else
            warn("更新个人航行数据格式错误")
        end
    end)

    -- 启动时间更新循环
    RunService.Heartbeat:Connect(function()
        updateRemainingTimes()
    end)

    -- 使用通用重试工具获取个人数据
    DataRetryUtil.RetryDataFetch(
        function()
            return Knit.GetService('RankService'):GetPersonalData()
        end,
        {
            maxRetries = 5,
            retryDelay = 2,
            timeout = 30,
            operationName = "个人航行数据获取",
            onSuccess = function(personalData)
                updatePersonalRankData(personalData)
            end
        }
    )
        
    -- 使用通用重试工具获取排行榜数据
    DataRetryUtil.RetryDataFetch(
        function()
            return Knit.GetService('RankService').GetLeaderboard()
        end,
        {
            maxRetries = 5,
            retryDelay = 2,
            operationName = "排行榜数据获取",
            dataValidator = function(data)
                return data and data.totalDis and data.maxDis and data.totalTime and data.maxTime
                and #data.totalDis.leaderboard ~= 0 and #data.maxDis.leaderboard ~= 0
                and #data.totalTime.leaderboard ~= 0 and #data.maxTime.leaderboard ~= 0
            end,
            onSuccess = function(leaderboardData)
                ClientData.RankData = leaderboardData
                Knit.GetController('UIController').UpdateRankUI:Fire()
            end,
            onFailure = function()
                ClientData.RankData = {}
            end
        }
    )
        
    -- 使用通用重试工具获取初始BUFF状态
    DataRetryUtil.RetryDataFetch(
        function()
            return Knit.GetService('BuffService'):GetPlayerBuffs(Players.LocalPlayer)
        end,
        {
            maxRetries = 5,
            retryDelay = 1,
            operationName = "初始BUFF数据获取",
            dataValidator = function(data)
                return data and type(data) == "table"
            end,
            onSuccess = function(initialBuffs)
                local buffCount = 0
                for buffType, buffs in pairs(initialBuffs) do
                    if type(buffs) == "table" then
                        for buffId, buffData in pairs(buffs) do
                            if buffData and buffData.remainingTime then
                                local config = BuffConfig.GetBuffConfig(buffId)
                                if config then
                                    ClientData.ActiveBuffs[buffId] = {
                                        buffId = buffId,
                                        remainingTime = buffData.remainingTime,
                                        startTime = tick(),
                                        config = config
                                    }
                                    buffCount = buffCount + 1
                                end
                            end
                        end
                    end
                end
                print("初始BUFF数据获取成功，加载了 " .. buffCount .. " 个BUFF")
                Knit.GetController('UIController').BuffChanged:Fire()
            end
        }
    )

    -- 使用通用重试工具获取登录数据
    DataRetryUtil.RetryDataFetch(
        function()
            return Knit.GetService('PlayerAttributeService'):GetLoginData()
        end,
        {
            maxRetries = 5,
            retryDelay = 1,
            operationName = "登录数据获取",
            dataValidator = function(data)
                return data and type(data) == "table" and data.Gold ~= nil
            end,
            onSuccess = function(data)
                -- 安全地设置数据
                ClientData.Gold = data.Gold or 0
                Knit.GetController('UIController').UpdateGoldUI:Fire()
                
                ClientData.InventoryItems = {}
                if data.PlayerInventory and type(data.PlayerInventory) == "table" then
                    for _, itemData in pairs(data.PlayerInventory) do
                        if itemData then
                            table.insert(ClientData.InventoryItems, itemData)
                        end
                    end
                end
                Knit.GetController('UIController').UpdateInventoryUI:Fire()

                ClientData.IsAdmin = data.isAdmin or false
                if ClientData.IsAdmin then
                    Knit.GetController('UIController').IsAdmin:Fire()
                end

                ClientData.IsLandOwners = data.IsLandOwners or {}
                Knit.GetController('UIController').IsLandOwner:Fire()
            end,
            onFailure = function(errorMsg)
                -- 使用默认值
                ClientData.Gold = 0
                ClientData.InventoryItems = {}
                ClientData.IsAdmin = false
                ClientData.IsLandOwners = {}
                
                Knit.GetController('UIController').UpdateGoldUI:Fire()
                Knit.GetController('UIController').UpdateInventoryUI:Fire()
            end
        }
    )
end):catch(warn)

return ClientData