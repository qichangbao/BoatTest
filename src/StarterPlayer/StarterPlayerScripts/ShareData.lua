local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local ShareData = {}

ShareData.Gold = 0  -- 玩家金币
ShareData.InventoryItems = {}   -- 玩家背包物品
ShareData.IsAdmin = false  -- 是否为管理员

Knit:OnStart():andThen(function()
    local PlayerAttributeService = Knit.GetService('PlayerAttributeService')
    PlayerAttributeService.ChangeGold:Connect(function(gold)
        ShareData.Gold = gold
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end)

    PlayerAttributeService:IsAdmin():andThen(function(isAdmin)
        if isAdmin then
            ShareData.IsAdmin = true
            Knit.GetController('UIController').IsAdmin:Fire()
        end
    end)

    local InventoryService = Knit.GetService('InventoryService')
    InventoryService.AddItem:Connect(function(itemData)
        local isExist = false
        for _, item in pairs(ShareData.InventoryItems) do
            if item.itemName == itemData.itemName and item.modelName == itemData.modelName then
                item.num = itemData.num
                isExist = true
                break
            end
        end
    
        if not isExist then
            ShareData.InventoryItems[itemData.itemName] = itemData
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig:Get(10011), itemData.itemName))
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
    InventoryService.RemoveItem:Connect(function(modelName, itemName)
        local isExist = false
        for name, item in pairs(ShareData.InventoryItems) do
            if item.itemName == itemName and item.modelName == modelName then
                ShareData.InventoryItems[name] = nil
                isExist = true
                break
            end
        end
    
        if isExist then
            Knit.GetController('UIController').UpdateInventoryUI:Fire()
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig:Get(10012), itemName))
    end)
    InventoryService.InitInventory:Connect(function(inventoryData)
        ShareData.InventoryItems = inventoryData
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
    InventoryService:GetInventory(Players.LocalPlayer):andThen(function(inventoryData)
        ShareData.InventoryItems = inventoryData
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)

    Knit.GetService('BoatAssemblingService').UpdateInventory:Connect(function(modelName)
        for _, item in pairs(ShareData.InventoryItems) do
            if item.modelName == modelName then
                item.isUsed = 1
            end
        end
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
end):catch(warn)

return ShareData