print('SystemService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SystemStore = DataStoreService:GetDataStore("SystemStore")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local MemoryStoreService = game:GetService("MemoryStoreService")
local ActiveServers = MemoryStoreService:GetSortedMap("ActiveServers")

local IsLandOwnerTag = "IsLandOwnerTag"
local IsLandPayTag = "IsLandPayTag"
local IsLandPayEndedTag = "IsLandPayEndedTag"

local SystemService = Knit.CreateService {
    Name = "SystemService",
    Client = {
        Tip = Knit.CreateSignal(),
        IsLandOwnerChanged = Knit.CreateSignal(),
    },
}

local _IsLandOwners = {}
local _isMainServer = false
local _IsLandPayInfos = {}

function SystemService:SendTip(player, tipId, ...)
    self.Client.Tip:Fire(player, tipId, ...)
end

function SystemService:SendIsLandOwnerChanged(player, data)
    self.Client.IsLandOwnerChanged:Fire(player, data)
end

-- 客户端登陆时调用，获取跨服岛主数据
function SystemService.Client:GetIsLandOwner(player)
    local data = table.clone(_IsLandOwners)
    return data
end

function SystemService:SendToAllPlayer(callFunc, excludeUserId)
    for _, player in pairs(Players:GetPlayers()) do
        if player.UserId ~= excludeUserId then
            callFunc(player)
        end
    end
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

    _IsLandOwners[landName] = {userId = player.UserId, playerName = player.Name}

    -- 如果是主服务器，则更新岛主数据库
    if _isMainServer then
        local success = pcall(function()
            SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
        end)
        if not success then
            warn('无法连接数据库: SystemStore')
        end
    end
end

local function AddPayInfoToMainServer()
    -- 如果是主服务器，则更新玩家交费数据库
    local success = pcall(function()
        SystemStore:SetAsync("IsLandPayInfo", _IsLandPayInfos)
    end)
    if not success then
        warn('无法连接数据库: SystemStore')
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
        self:SendTip(player, 10045, data.playerName, landName, price)
        return
    end

    if not _IsLandPayInfos[data.userId] then
        _IsLandPayInfos[data.userId] = {}
    end
    table.insert(_IsLandPayInfos[data.userId], {payPlayerName = payPlayerName, landName = landName, price = price})
    -- 跨服发送土地付费消息
    MessagingService:PublishAsync(IsLandPayTag, {jobId = game.jobId, userId = data.userId, data = _IsLandPayInfos[data.userId]})
    if _isMainServer then
        AddPayInfoToMainServer()
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
    pcall(function()
        return ActiveServers:SetAsync(_serverId, _serverStartTime, 60)
    end)
    task.wait(30)
end)

local function CheckMainServer()
    local servers = ActiveServers:GetRangeAsync(Enum.SortDirection.Descending, 1)
    if #servers > 0 then
        if servers[1].key == _serverId then
            _isMainServer = true

            local ownersInfo = nil
            -- 主服务器从数据库获取所有岛主数据
            local success = pcall(function()
                ownersInfo = SystemStore:GetAsync("IsLandOwners")
            end)
            if success then
                _IsLandOwners = ownersInfo
            else
                warn('无法连接数据库: SystemStore')
            end
            print("IsLandOwners", _IsLandOwners)

            local payInfos = nil
            -- 主服务器从数据库获取土地付费数据
            success = pcall(function()
                payInfos = SystemStore:GetAsync("IsLandPayInfo")
            end)
            if success then
                _IsLandPayInfos = payInfos or {}
            else
                warn('无法连接数据库: SystemStore')
            end
            print("IsLandPayInfos", _IsLandPayInfos)
        end
    end
end

-- 玩家登陆时调用，获取服务器缓存的跨服玩家交费数据
function SystemService:PlayerAdded(player)
    if _IsLandPayInfos[player.UserId] then
        local gold = player:GetAttribute("Gold")
        for _, info in ipairs(_IsLandPayInfos[player.UserId]) do
            gold += info.price
            self:SendTip(player, 10045, info.payPlayerName, info.landName, info.price)
        end
        player:SetAttribute("Gold", gold)
        _IsLandPayInfos[player.UserId] = nil

        MessagingService:PublishAsync(IsLandPayEndedTag, player.UserId)
    end
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
        _IsLandOwners[message.Data.landName] = {userId = message.Data.userId, playerName = message.Data.playerName}
        self:SendToAllPlayer(function(player)
            self:SendIsLandOwnerChanged(player, {landName = message.Data.landName, userId = message.Data.userId, playerName = message.Data.playerName})
            if player.UserId ~= message.Data.userId then
                self:SendTip(player, 10039, message.Data.playerName, message.Data.landName)
            end
        end)
    end)
    -- 跨服接收土地付费消息
    MessagingService:SubscribeAsync(IsLandPayTag, function(message)
        local userId = message.Data.userId
        local data = message.Data.data

        local player = Players:GetPlayerByUserId(userId)
        if player then
            local gold = player:GetAttribute("Gold")
            for _, info in ipairs(data) do
                gold += info.price
                self:SendTip(player, 10045, data.payPlayerName, info.landName, info.price)
            end
            player:SetAttribute("Gold", gold)

            MessagingService:PublishAsync(IsLandPayEndedTag, userId)
            return
        else
            local jobId = message.Data.jobId
            if jobId == game.jobId then
                return
            end

            if not _IsLandPayInfos[data.userId] then
                _IsLandPayInfos[data.userId] = {}
            end
            table.insert(_IsLandPayInfos[data.userId], {payPlayerName = data.payPlayerName, landName = data.landName, price = data.price})
            if _isMainServer then
                AddPayInfoToMainServer()
                return
            end
        end
    end)
    -- 跨服接收玩家交费完成消息
    MessagingService:SubscribeAsync(IsLandPayEndedTag, function(message)
        local userId = message.Data
        _IsLandPayInfos[userId] = nil
        print("玩家收费完成", userId)
    end)
end

function SystemService:KnitStart()
    print('SystemService started')
end

return SystemService