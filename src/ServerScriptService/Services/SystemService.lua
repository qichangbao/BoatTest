print('SystemService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SystemStore = DataStoreService:GetDataStore("SystemStore")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

local AllPlayersDataTag = "AllPlayersDataTag"
local IsLandOwnerTag = "IsLandOwnerTag"
local IsLandPayTag = "IsLandPayTag"

local SystemService = Knit.CreateService {
    Name = "SystemService",
    Client = {
        Tip = Knit.CreateSignal(),
        IsLandBelong = Knit.CreateSignal(),
    },
}

local _CurPlayersData = {}
local _OtherServePlayersData = {}
local _IsLandOwners = {}
local _isPlayerChanged = false

function SystemService:SendTip(player, tipId, ...)
    self.Client.Tip:Fire(player, tipId, ...)
end

function SystemService:SendIsLandOwner(player)
    local data = table.clone(_IsLandOwners)
    self.Client.IsLandBelong:Fire(player, data)
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
    SystemStore:SetAsync("IsLandOwners", _IsLandOwners)
end

function SystemService:AddGoldFromIsLandPay(landName, price)
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

    local playerData = _OtherServePlayersData[data.userId]
    -- 如果其他服玩家不在线，则更新玩家数据库金币，如果玩家在线，则通过跨服消息让玩家自己更新金币
    if not playerData then
        self:OperateDataStroe(player, function(Profile)
            Profile.Data["Gold"] += price
            return Profile
        end)
    else
        -- 跨服发送土地付费消息
        MessagingService:PublishAsync(IsLandPayTag,
            {
                jobId = playerData.jobId,
                landName = landName,
                userId = data.userId,
                playerName = data.playerName,
            }
        )
    end
end

function SystemService:OperateDataStroe(player, callFunc)
    local PlayerProfile = game.DataStoreService:GetDataStore("PlayerProfile")
    PlayerProfile:UpdateAsync("Player_".. player.UserId, function(Profile)
        return callFunc(Profile)
    end)
end

function SystemService:KnitInit()
    print('SystemService initialized')
    
    -- 跨服接收玩家数据同步消息
    MessagingService:SubscribeAsync(AllPlayersDataTag, function(message)
        local systemData = message.Data
        if systemData["服务器ID:"] == game.JobId then
            return
        end

        local offlinePlayers = systemData.offlinePlayers
        for _, userId in pairs(offlinePlayers) do
            _OtherServePlayersData[userId] = nil
        end
        local playersData = systemData.playersData
        for userId, data in pairs(playersData) do
            _OtherServePlayersData[userId] = data
        end
    end)
    
    -- 跨服接收土地更新领主消息
    MessagingService:SubscribeAsync(IsLandOwnerTag, function(message)
        print("Received message for IsLandOwnerTag",  message)
        _IsLandOwners[message.Data.landName] = {userId = message.Data.userId, playerName = message.Data.playerName}
        self:SendToAllPlayer(function(player)
            self:SendIsLandOwner(player)
        end)
        self:SendToAllPlayer(function(player)
            self:SendTip(player, 10039, message.Data.playerName, message.Data.landName)
        end, message.Data.userId)
    end)

    -- 跨服接收土地付费消息
    MessagingService:SubscribeAsync(IsLandPayTag, function(message)
        local data = message.Data
        if data.jobId ~= game.JobId then
            return
        end

        local land = GameConfig.findIsLand(message.Data.landName)
        if not land then
            return
        end

        local player = Players:GetPlayerByUserId(message.Data.userId)
        if not player then
            DataStoreService:GetDataStore("Player_" .. data.userId):UpdateAsync("Gold", function(gold)
                return gold + land.Price
            end)
            return
        end
        local gold = player:GetAttribute("Gold")
        player:SetAttribute("Gold", gold + land.Price)
        self:SendTip(player, 10045, message.Data.playerName, message.Data.landName, land.Price)
    end)

    _IsLandOwners = SystemStore:GetAsync("IsLandOwners") or {}
    print("IsLandOwners", _IsLandOwners)
    
    local function playerAdded(player)
        _isPlayerChanged = true
    end

    local function playerRemoving(player)
        _isPlayerChanged = true
    end

	for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end

    Players.PlayerAdded:Connect(function(player)
        playerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        playerRemoving(player)
    end)
end

function SystemService:KnitStart()
    print('SystemService started')
    
    -- 定时同步全服玩家数据
    while true do
        task.wait(30) -- 每30秒同步一次
        if not _isPlayerChanged then
            continue
        end

        _isPlayerChanged = false
        local systemData = {}
        systemData["服务器ID:"] = game.JobId
        systemData.playersData = {}
        systemData.offlinePlayers = {}
        for _, player in pairs(Players:GetPlayers()) do
            if not _CurPlayersData[player.UserId] then
                table.insert(systemData.offlinePlayers, player.UserId)
            end
            systemData.playersData[player.UserId] = {
                name = player.Name,
                online = true,
                jobId = game.JobId,
            }
        end

        _CurPlayersData = {}
        for _, player in pairs(Players:GetPlayers()) do
            _CurPlayersData[player.UserId] = true
        end
        
        -- 发布跨服消息
        MessagingService:PublishAsync(AllPlayersDataTag, systemData)
    end
end

return SystemService