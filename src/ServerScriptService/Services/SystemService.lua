print('SystemService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local SystemConstant = require(script.Parent.Parent:WaitForChild("SystemConstant"))
local Players = game:GetService("Players")

local SystemService = Knit.CreateService {
    Name = "SystemService",
    Client = {
        Tip = Knit.CreateSignal(),
        IsLandBelong = Knit.CreateSignal(),
    },
    IsLandOwners = {},
}

function SystemService:SendTip(player, tipId, ...)
    self.Client.Tip:Fire(player, tipId, ...)
end

function SystemService:SendIsLandOwner(player)
    local data = table.clone(self.IsLandOwners)
    self.Client.IsLandBelong:Fire(player, data)
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
    MessagingService:PublishAsync(SystemConstant.IsLandOwnerTag, {landName = landName, userId = player.UserId, playerName = player.Name})

    self.IsLandOwners[landName] = {userId = player.UserId, playerName = player.Name}
    local DBService = Knit.GetService('DBService')
    Knit.GetService('DBService'):Set(DBService.SystemId, "IsLandOwners", self.IsLandOwners)
end

function SystemService:KnitInit()
    print('SystemService initialized')
    
    -- 跨服接收土地更新领主消息
    MessagingService:SubscribeAsync(SystemConstant.IsLandOwnerTag, function(message)
        print("Received message for IsLandOwnerTag",  message)
        self.IsLandOwners[message.Data.landName] = {userId = message.Data.userId, playerName = message.Data.playerName}
        self:SendToAllPlayer(function(player)
            self:SendIsLandOwner(player)
        end)
        self:SendToAllPlayer(function(player)
            self:SendTip(player, 10039, message.Data.playerName, message.Data.landName)
        end, message.Data.userId)
    end)

    local DBService = Knit.GetService('DBService')
    self.IsLandOwners = Knit.GetService('DBService'):GetToAllStore(DBService.SystemId, "IsLandOwners")
    print("IsLandOwners", self.IsLandOwners)
    
    local function playerAdded(player)
        self:SendIsLandOwner(player)
    end

	for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end

    Players.PlayerAdded:Connect(function(player)
        playerAdded(player)
    end)
end

function SystemService:KnitStart()
    print('SystemService started')
end

return SystemService