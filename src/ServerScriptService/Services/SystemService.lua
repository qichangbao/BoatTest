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

-- 客户端登陆时调用，获取跨服岛主数据
function SystemService.Client:GetIsLandOwner(player)
    local data = table.clone(self.Server.IsLandOwners)
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
        SystemConstant.IsLandOwnerTag,
        {
            landName = landName,
            userId = player.UserId,
            playerName = player.Name,
        }
    )

    self.IsLandOwners[landName] = {userId = player.UserId, playerName = player.Name}
    local DBService = Knit.GetService('DBService')
    Knit.GetService('DBService'):Set(DBService.SystemId, "IsLandOwners", self.IsLandOwners)
end

function SystemService:AddGoldFromIsLandPay(landName, price)
    local data = self.IsLandOwners[landName]
    if not data then
        return
    end

    local DBService = Knit.GetService('DBService')
    local isOnLine = DBService:GetToAllStore(data.userId, "IsOnLine")
    -- 如果玩家不在线，则更新玩家数据库金币，如果玩家在线，则通过跨服消息让玩家自己更新金币
    if not isOnLine then
        DBService:Update(data.userId, "Gold", function(gold)
            return gold + price
        end)
    else
        -- 跨服发送土地付费消息
        MessagingService:PublishAsync(
            SystemConstant.IsLandPayTag,
            {
                landName = landName,
                userId = data.userId,
                playerName = data.playerName,
                price = price,
            }
        )
    end
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

    -- 跨服接收土地付费消息
    MessagingService:SubscribeAsync(SystemConstant.IsLandPayTag, function(message)
        for _, player in pairs(Players:GetPlayers()) do
            if player.UserId == message.Data.userId then
                local gold = player:GetAttribute("Gold")
                player:SetAttribute("Gold", gold + message.Data.price)
                self:SendTip(player, 10045, message.Data.playerName, message.Data.landName, message.Data.price)
                return
            end
        end
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