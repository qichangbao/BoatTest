print('InventoryService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local ItemConfig = require(ServerScriptService:WaitForChild('ConfigFolder'):WaitForChild('ItemConfig'))

local InventoryService = Knit.CreateService({
    Name = 'InventoryService',
    Client = {
        AddItem = Knit.CreateSignal(),
        RemoveItem = Knit.CreateSignal(),
        InitInventory = Knit.CreateSignal(),
    },
    playersInventory = {},
})

-- 从DataStoreService初始化玩家库存数据
function InventoryService:InitPlayerInventory(player, inventoryStore)
    local userId = player.UserId
    if not self.playersInventory[userId] then
        self.playersInventory[userId] = {}
    end

    print('InitPlayerInventory', userId, inventoryStore)
    for itemName, itemData in pairs(inventoryStore) do
        itemData.isUsed = 0
        itemData.icon = ItemConfig[itemName].icon
        itemData.sellPrice = ItemConfig[itemName].sellPrice
        self.playersInventory[userId][itemName] = itemData
    end
    -- if inventoryStore and string.len(inventoryStore) > 0 then
    --     local inventory = HttpService:JSONDecode(inventoryStore)
    --     for itemName, itemData in pairs(inventory) do
    --         self.playersInventory[userId][itemName] = itemData
    --     end
    -- end
    self.Client.InitInventory:Fire(player, self.playersInventory[userId])
end

function InventoryService:AddItemToInventory(player, itemName, modelName)
    local userId = player.UserId
    if not self.playersInventory[userId] then
        self.playersInventory[userId] = {}
    end
    
    self.playersInventory[userId][itemName] = {
        itemName = itemName,
        modelName = modelName,
        num = (self.playersInventory[userId][itemName] and self.playersInventory[userId][itemName].num or 0) + 1,
        icon = ItemConfig[itemName].icon,
        sellPrice = ItemConfig[itemName].sellPrice,
        isUsed = 0
    }
    
    local data = {}
    for i, v in pairs(self.playersInventory[userId]) do
        data[i] = {itemName = v.itemName, modelName = v.modelName, num = v.num}
    end
    Knit.GetService('DBService'):Set(userId, "PlayerInventory", data)
    self.Client.AddItem:Fire(player, self.playersInventory[userId][itemName])
    
    return true
end

function InventoryService:RemoveItemFromInventory(player, modelName, itemName)
    local userId = player.UserId
    if not self.playersInventory[userId] then
        self.playersInventory[userId] = {}
    end

    if self.playersInventory[userId][itemName] and self.playersInventory[userId][itemName].modelName == modelName 
    and self.playersInventory[userId][itemName].isUsed == 0 then
        self.playersInventory[userId][itemName].num = math.max(0, self.playersInventory[userId][itemName].num - 1)
        if self.playersInventory[userId][itemName].num == 0 then
            self.playersInventory[userId][itemName] = nil
        end
        
        local data = {}
        for i, v in pairs(self.playersInventory[userId]) do
            data[i] = {itemName = v.itemName, modelName = v.modelName, num = v.num}
        end
        Knit.GetService('DBService'):Set(userId, "PlayerInventory", data)
        self.Client.RemoveItem:Fire(player, modelName, itemName)
        return true
    end
    return false
end

function InventoryService:CheckExists(player, itemName)
    local inventory = self:GetPlayerInventory(player)
    return inventory[itemName] ~= nil
end

function InventoryService:GetPlayerInventory(player)
    --[[
        获取指定玩家的完整库存数据
        @param player: 玩家实例
        @return: 包含玩家所有物品的table
    ]]--
    local userId = player.UserId
    return self.playersInventory[userId] or {}
end

function InventoryService:Inventory(player, action, ...)
    --[[
        处理客户端发起的库存操作请求
        @param player: 发起请求的玩家实例
        @param action: 操作类型 ('AddItem'/'RemoveItem'/'GetInventory')
        @param ...: 可变参数，根据操作类型不同包含：
            - AddItem/RemoveItem: itemName (string) 物品类型
            - GetInventory: 无额外参数
        @return: 操作结果 (boolean) 或 当前库存数据 (table)
    ]]
    if action == 'AddItem' then
        return self:AddItemToInventory(player, ...)
    elseif action == 'RemoveItem' then
        return self:RemoveItemFromInventory(player, ...)
    elseif action == 'GetInventory' then
        return self:GetPlayerInventory(player)
    elseif action == 'CheckExists' then
        return self:CheckExists(player, ...)
    end
end

-- 船组装成功
function InventoryService:BoatAssemblySuccess(player, modelName)
    local userId = player.UserId
    if self.playersInventory[userId] then
        for _, itemData in pairs(self.playersInventory[userId]) do
            if itemData.modelName == modelName then
                itemData.isUsed = 1
            end
        end
    end
end

function InventoryService:GetUnusedParts(player, modelName)
    local userId = player.UserId
    local unused = {}
    if self.playersInventory[userId] then
        for _, itemData in pairs(self.playersInventory[userId]) do
            if itemData.modelName == modelName and itemData.isUsed == 1 then
                table.insert(unused, itemData)
            end
        end
    end
    return unused
end

function InventoryService.Client:SellItem(player, modelName, itemName)
    if self.Server:RemoveItemFromInventory(player, modelName, itemName) then
        local itemConfig = ItemConfig[itemName]
        if itemConfig then
            player:SetAttribute('Gold', player:GetAttribute('Gold') + itemConfig.sellPrice)
        end
    end
end

function InventoryService.Client:GetInventory(player)
    return self.Server:GetPlayerInventory(player)
end

function InventoryService:KnitInit()
    print('InventoryService initialized')
end

function InventoryService:KnitStart()
    print('InventoryService started')
end

return InventoryService