local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local ClientData = {}

ClientData.Gold = 0  -- 玩家金币
ClientData.InventoryItems = {}   -- 玩家背包物品
ClientData.IsAdmin = false  -- 是否为管理员
ClientData.IsLandOwners = {}  -- 所有土地的拥有者

Knit:OnStart():andThen(function()
    local SystemService = Knit.GetService('SystemService')
    SystemService.IsLandBelong:Connect(function(data)
        ClientData.IsLandOwners = data
    end)

    local PlayerAttributeService = Knit.GetService('PlayerAttributeService')
    PlayerAttributeService.ChangeGold:Connect(function(gold)
        ClientData.Gold = gold
        Knit.GetController('UIController').UpdateGoldUI:Fire()
    end)

    PlayerAttributeService:IsAdmin():andThen(function(isAdmin)
        if isAdmin then
            ClientData.IsAdmin = true
            Knit.GetController('UIController').IsAdmin:Fire()
        end
    end)

    local InventoryService = Knit.GetService('InventoryService')
    InventoryService.AddItem:Connect(function(itemData)
        local isExist = false
        for _, item in pairs(ClientData.InventoryItems) do
            if item.itemName == itemData.itemName and item.modelName == itemData.modelName then
                item.num = itemData.num
                isExist = true
                break
            end
        end
    
        if not isExist then
            ClientData.InventoryItems[itemData.itemName] = itemData
        end
        Knit.GetController('UIController').ShowTip:Fire(string.format(LanguageConfig:Get(10011), itemData.itemName))
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
    InventoryService.RemoveItem:Connect(function(modelName, itemName)
        local isExist = false
        for name, item in pairs(ClientData.InventoryItems) do
            if item.itemName == itemName and item.modelName == modelName then
                ClientData.InventoryItems[name] = nil
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
        ClientData.InventoryItems = inventoryData
        Knit.GetController('UIController').UpdateInventoryUI:Fire()
    end)
    InventoryService:GetInventory(Players.LocalPlayer):andThen(function(inventoryData)
        ClientData.InventoryItems = inventoryData
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
end):catch(warn)

return ClientData