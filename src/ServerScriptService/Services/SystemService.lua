print('SystemService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SystemStore = DataStoreService:GetDataStore("SystemStore")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ActiveServers = MemoryStoreService:GetSortedMap("ActiveServers")
local RunService = game:GetService("RunService")
local isStudio = RunService:IsStudio()
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local IsLandOwnerTag = "IsLandOwnerTag" -- 土地更新领主消息，其他服务器发送，用于让主服务器更新数据库
local IsLandOwnerMainServeTag = "IsLandOwnerMainServeTag"   -- 土地更新领主消息，主服务器发送，用于让其他服务器同步数据
local IsLandPayTag = "IsLandPayTag"
local ChangeIsLandDataTag = "ChangeIsLandDataTag"
local ChangeIsLandDataMainServeTag = "ChangeIsLandDataMainServeTag"
local _IsLandOwners = {}
local _isMainServer = false

-- SystemStore:UpdateAsync("IsLandOwners", function(oldData)
--     oldData["阿卡迪亚"].towerData[1].towerType = "Tower1"
--     oldData["阿卡迪亚"].towerData[1].towerName = "基础箭塔"
--     oldData["阿卡迪亚"].towerData[2].towerType = "Tower1"
--     oldData["阿卡迪亚"].towerData[2].towerName = "基础箭塔"
--     return oldData
-- end)

local SystemService = Knit.CreateService {
    Name = "SystemService",
    Client = {
        Tip = Knit.CreateSignal(),
        SystemMessage = Knit.CreateSignal(),
        IsLandOwnerChanged = Knit.CreateSignal(),
        IsLandInfoChanged = Knit.CreateSignal(),
    },
}

function SystemService:SendTip(player, tipId, ...)
    self.Client.Tip:Fire(player, tipId, ...)
end

function SystemService:SendSystemMessage(messageType, tipId, ...)
    self.Client.SystemMessage:FireAll(messageType, tipId, ...)
end

function SystemService:SendSystemMessageToSinglePlayer(player, messageType, tipId, ...)
    self.Client.SystemMessage:Fire(player, messageType, tipId, ...)
end

function SystemService:SendIsLandOwnerChanged(data)
    self.Client.IsLandOwnerChanged:FireAll(data)
    self:SendSystemMessage('success', 10039, data.playerName, data.landName)
end

function SystemService:GetIsLandOwner()
    return table.clone(_IsLandOwners)
end

-- 更新岛屿信息
function SystemService:ChangeIsLandOwnerData(isLandOwners, changeInfo)
    local islandId = changeInfo.islandId
    local isLandData = changeInfo.isLandData
    _IsLandOwners[islandId] = isLandData
    self.Client.IsLandInfoChanged:FireAll({landName = islandId, isLandData = isLandData})
    if _isMainServer then
        _IsLandOwners = isLandOwners
        task.spawn(function()
            pcall(function()
                return SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
            end)

            MessagingService:PublishAsync(ChangeIsLandDataMainServeTag, {
                jobId = game.JobId,
                isLandOwners = isLandOwners,
                islandId = islandId,
                isLandData = isLandData
            })
        end)
    else
        task.spawn(function()
            MessagingService:PublishAsync(ChangeIsLandDataTag, {
                jobId = game.JobId,
                isLandOwners = isLandOwners,
                islandId = islandId,
                isLandData = isLandData
            })
        end)
    end
end

-- 更新岛主信息
function SystemService:UpdateIsLandOwner(player, landName)
    -- 如果是主服务器，则更新岛主数据库
    Knit.GetService("TowerService"):RemoveTowersByLandName(landName)
    _IsLandOwners[landName] = {userId = player.UserId, playerName = player.Name}
    if _isMainServer then
        task.spawn(function()
            pcall(function()
                return SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
            end)

            -- 跨服发送土地更新领主消息
            MessagingService:PublishAsync(IsLandOwnerMainServeTag, {
                jobId = game.JobId,
                IsLandOwners = _IsLandOwners,
                landName = landName,
                userId = player.UserId,
                playerName = player.Name,
            })
        end)
    else
        task.spawn(function()
            -- 跨服发送土地更新领主消息
            MessagingService:PublishAsync(IsLandOwnerTag, {
                jobId = game.JobId,
                landName = landName,
                userId = player.UserId,
                playerName = player.Name,
            })
        end)
    end
end

function SystemService:AddGoldFromIsLandPay(payPlayerName, landName, price)
    local data = _IsLandOwners[landName]
    if not data then
        return
    end

    -- 如果是本服玩家，则直接更新玩家金币
    local player = Players:GetPlayerByUserId(data.userId)
    if player then
        local gold = player:GetAttribute("Gold")
        player:SetAttribute("Gold", gold + price)
        self:SendSystemMessageToSinglePlayer(player, 'success', 10045, payPlayerName, landName, price)
        return
    end

    task.spawn(function()
        local success, playerSystemData = pcall(function()
            return Knit.GetService('DBService'):GetPlayerSystemData(data.userId)
        end)
        if success then
            playerSystemData = playerSystemData or {}
            -- 跨服发送土地付费消息
            MessagingService:PublishAsync(IsLandPayTag, {
                jobId = playerSystemData.JobId or "",
                userId = data.userId,
                login = playerSystemData.Login or false,
                data = {payPlayerName = payPlayerName, landName = landName, price = price}
            })
        end
    end)
end

-- 获取服务器ID的兼容性写法
local function getServerId()
    -- 优先使用JobId
    local jobId = tostring(game.JobId)
    if jobId and jobId ~= "" then
        return jobId
    end
    
    -- Studio环境下使用临时生成的UUID
    return "STUDIO"
end

local _serverId = getServerId()
print("服务器ID:", _serverId)

local _serverStartTime = os.time()
-- 启动注册协程
task.spawn(function()
    if isStudio then
        return
    end

    pcall(function()
        return ActiveServers:SetAsync(_serverId, _serverStartTime, 60)
    end)
    task.wait(30)
end)

function SystemService:CheckMainServer()
    if isStudio then
        -- Studio环境下直接设为主服务器
        _isMainServer = true
        local success, ownersInfo = pcall(function()
            return SystemStore:GetAsync("IsLandOwners")
        end)
        if success then
            print("IsLandOwners", ownersInfo)
            _IsLandOwners = ownersInfo or {}
            for i, v in pairs(_IsLandOwners) do
                Knit.GetService("TowerService"):CreateTowersByLandName(i)
            end
        else
            warn('无法连接数据库: SystemStore')
        end
        print("IsLandOwners", _IsLandOwners)
        return
    end

    local servers = ActiveServers:GetRangeAsync(Enum.SortDirection.Descending, 1)
    if #servers > 0 then
        if servers[1].key == _serverId then
            _isMainServer = true

            -- 主服务器从数据库获取所有岛主数据
            local success, ownersInfo = pcall(function()
                return SystemStore:GetAsync("IsLandOwners")
            end)
            if success then
                _IsLandOwners = ownersInfo or {}
                for i, v in pairs(_IsLandOwners) do
                    Knit.GetService("TowerService"):CreateTowersByLandName(i)
                end
            else
                warn('无法连接数据库: SystemStore')
            end
            print("IsLandOwners", _IsLandOwners)
        end
    end
end

function SystemService:KnitInit()
    print('SystemService initialized')
    -- 开启协程定时检查主服务器，防止主服务器崩溃
    task.spawn(function()
        self:CheckMainServer()
        task.wait(30)
    end)
    
    -- 其他服务器接收主服务器土地更新领主消息
    MessagingService:SubscribeAsync(IsLandOwnerMainServeTag, function(message)
        print("Received message for IsLandOwnerMainServeTag",  message)
        if message.Data.jobId == game.JobId then
            return
        end

        -- 主服务器在发送这个消息的时候已经更新了数据库，所以这里只需要更新其他服务器的数据
        if not _isMainServer then
            Knit.GetService("TowerService"):RemoveTowersByLandName(message.Data.landName)
            _IsLandOwners = message.Data.IsLandOwners
        end
        self:SendIsLandOwnerChanged({landName = message.Data.landName, userId = message.Data.userId, playerName = message.Data.playerName})
    end)
    -- 主服务器更新领主消息
    MessagingService:SubscribeAsync(IsLandOwnerTag, function(message)
        print("Received message for IsLandOwnerTag",  message)
        local jobId = message.Data.jobId
        if jobId == game.JobId then
            return
        end
        -- 如果是主服务器，则更新岛主数据库, 并发送消息给其他服务器
        if _isMainServer then
            Knit.GetService("TowerService"):RemoveTowersByLandName(message.Data.landName)
            _IsLandOwners[message.Data.landName] = {userId = message.Data.userId, playerName = message.Data.playerName}
            
            task.spawn(function()
                pcall(function()
                    return SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
                end)

                -- 跨服发送土地更新领主消息
                MessagingService:PublishAsync(
                    IsLandOwnerMainServeTag,
                    {
                        jobId = jobId,
                        IsLandOwners = _IsLandOwners,
                        landName = message.Data.landName,
                        userId = message.Data.userId,
                        playerName = message.Data.playerName,
                    }
                )
            end)
        end
    end)
    -- 跨服接收土地付费消息
    MessagingService:SubscribeAsync(IsLandPayTag, function(message)
        print("Received message for IsLandPayTag",  message)
        local jobId = message.Data.jobId
        local userId = message.Data.userId
        local data = message.Data.data
        local login = message.Data.login
        -- 如果是本服玩家且在线，则直接更新玩家金币
        if login and jobId == game.JobId then
            local player = Players:GetPlayerByUserId(userId)
            if player then
                local gold = player:GetAttribute("Gold") + data.price
                player:SetAttribute("Gold", gold)
                self:SendSystemMessageToSinglePlayer(player, 'success', 10045, data.payPlayerName, data.landName, data.price)
                return
            end
        end

        -- 如果玩家不在线且是主服务器，则将数据添加到主服务器数据库
        if not login and _isMainServer then
            Knit.GetService("DBService"):UpdatePayInfos(userId, function(oldData)
                oldData = oldData or {}
                table.insert(oldData, data)
                return oldData
            end)
            return
        end
    end)
    -- 跨服发送土地属性改变消息
    MessagingService:SubscribeAsync(ChangeIsLandDataMainServeTag, function(message)
        print("Received message for ChangeIsLandDataMainServeTag",  message)
        if message.Data.jobId == game.JobId then
            return
        end
        if not _isMainServer then
            _IsLandOwners = message.Data.isLandOwners
            self.Client.IsLandInfoChanged:FireAll({landName = message.Data.islandId, isLandData = message.Data.isLandData})
        end
    end)
    -- 跨服发送土地属性改变消息
    MessagingService:SubscribeAsync(ChangeIsLandDataTag, function(message)
        print("Received message for ChangeIsLandDataTag",  message)
        local jobId = message.Data.jobId
        if jobId == game.JobId then
            return
        end

        if _isMainServer then
            _IsLandOwners[message.Data.islandId] = message.Data.isLandData
            self.Client.IsLandInfoChanged:FireAll({landName = message.Data.islandId, isLandData = message.Data.isLandData})
            if _isMainServer then
                task.spawn(function()
                    pcall(function()
                        return SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
                    end)
            
                    MessagingService:PublishAsync(ChangeIsLandDataMainServeTag, {
                        jobId = jobId,
                        isLandOwners = _IsLandOwners,
                        islandId = message.Data.islandId,
                        isLandData = message.Data.isLandData
                    })
                end)
            end
        end
    end)
end

function SystemService:KnitStart()
    print('SystemService started')
end

return SystemService