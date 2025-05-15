print('GiftService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local GiftService = Knit.CreateService {
    Name = "GiftService",
    Client = {
        SendGift = Knit.CreateSignal()
    }
}

function GiftService:ValidateGift(sender, receiverUserId, itemId)
    -- 验证逻辑
end

function GiftService.Client:RequestSendGift(player, receiverUserId, itemId)
    -- 处理赠送请求
end

return GiftService