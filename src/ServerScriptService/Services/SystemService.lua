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

local IsLandOwnerTag = "IsLandOwnerTag"
local IsLandPayTag = "IsLandPayTag"
local _IsLandOwners = {}
local _isMainServer = false

local SystemService = Knit.CreateService {
    Name = "SystemService",
    Client = {
        Tip = Knit.CreateSignal(),
        SystemMessage = Knit.CreateSignal(),
        IsLandOwnerChanged = Knit.CreateSignal(),
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

-- 客户端登陆时调用，获取跨服岛主数据
function SystemService:GetIsLandOwner(player)
    return _IsLandOwners
end

function SystemService:UpdateIsLandOwner(player, landName)
    -- 跨服发送土地更新领主消息
    MessagingService:PublishAsync(
        IsLandOwnerTag,
        {
            landName = landName,
            userId = player.UserId,
            playerName = player.Name,
        }
    )

    local isLandData = {towerData = {}}
    _IsLandOwners[landName] = {userId = player.UserId, playerName = player.Name, isLandData = isLandData}
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

local function CheckMainServer()
    if isStudio then
        -- Studio环境下直接设为主服务器
        _isMainServer = true
        local success, ownersInfo = pcall(function()
            return SystemStore:GetAsync("IsLandOwners")
        end)
        if success then
            _IsLandOwners = ownersInfo or {}
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
            else
                warn('无法连接数据库: SystemStore')
            end
            print("IsLandOwners", _IsLandOwners)
        end
    end
end

-- 安全的DataStore操作函数
local function safeDataStoreOperation(operation, ...)
    if isStudio then
        warn("Studio环境：DataStore操作可能受限")
    end
    
    local success, result = pcall(operation, ...)
    if not success then
        if string.find(result, "HTTP 403") or string.find(result, "Forbidden") then
            warn("DataStore访问被拒绝：请检查Studio设置或游戏发布状态")
            return false, "Access denied"
        else
            warn("DataStore操作失败：", result)
            return false, result
        end
    end
    
    return success, result
end

function SystemService:KnitInit()
    print('SystemService initialized')
    -- 开启协程定时检查主服务器，防止主服务器崩溃
    task.spawn(function()
        CheckMainServer()
        task.wait(30)
    end)
    
    -- 跨服接收土地更新领主消息
    MessagingService:SubscribeAsync(IsLandOwnerTag, function(message)
        print("Received message for IsLandOwnerTag",  message)
        local isLandData = {towerData = {}}
        _IsLandOwners[message.Data.landName] = {userId = message.Data.userId, playerName = message.Data.playerName, isLandData = isLandData}
        self:SendIsLandOwnerChanged({landName = message.Data.landName, userId = message.Data.userId, playerName = message.Data.playerName})

        -- 如果是主服务器，则更新岛主数据库
        if _isMainServer then
            local success = safeDataStoreOperation(function()
                return SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
            end)
            if not success then
                warn('无法连接数据库: SystemStore')
            end
        end
    end)
    -- 跨服接收土地付费消息
    MessagingService:SubscribeAsync(IsLandPayTag, function(message)
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
            local DBService = Knit.GetService("DBService")
            DBService:UpdatePayInfos(userId, function(oldData)
                oldData = oldData or {}
                table.insert(oldData, data)
                return oldData
            end)
            return
        end
    end)
end

function SystemService:KnitStart()
    print('SystemService started')
end

return SystemService