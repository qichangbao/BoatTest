print('GiftService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService("Players")

local GiftService = Knit.CreateService {
    Name = "GiftService",
    Client = {
    }
}

function GiftService.Client:RequestSendGift(player, targetPlayerUserId, items)
    -- 处理赠送请求
    if player.UserId == targetPlayerUserId then
        return 10030
    end

    local InventoryService = Knit.GetService("InventoryService")
    local curInventory = InventoryService.playersInventory[player.UserId]
    local targetPlayer = Players:GetPlayerByUserId(targetPlayerUserId)
    if not targetPlayer then
        return 10032
    end
    local targetInventory = InventoryService.playersInventory[targetPlayerUserId]
    for _, itemData in ipairs(items) do
        if InventoryService:CheckExists(player, itemData.itemName) then
            curInventory[itemData.itemName].num -= itemData.itemNum
            if curInventory[itemData.itemName].num <= 0 then
                curInventory[itemData.itemName] = nil
            end
        end
    end

    for _, itemData in ipairs(items) do
        if targetInventory[itemData.itemName] then
            targetInventory[itemData.itemName].num += itemData.itemNum
        else
            targetInventory[itemData.itemName] = InventoryService:AddSingleItem(targetPlayerUserId, itemData.itemName, itemData.modelName, itemData.itemNum)
        end
    end
    InventoryService:ResetPlayerInventory(player, curInventory)
    InventoryService:ResetPlayerInventory(targetPlayer, targetInventory)
    Knit.GetService("SystemService"):SendTip(targetPlayer, 10031, player.name)

    return 10028
end

return GiftService