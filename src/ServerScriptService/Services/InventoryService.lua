print('InventoryService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local InventoryService = Knit.CreateService({
    Name = 'InventoryService',
    Client = {
        AddItem = Knit.CreateSignal(),
        RemoveItem = Knit.CreateSignal(),
    },
    playersInventory = {},
})

-- 从DataStoreService初始化玩家库存数据
function InventoryService:InitPlayerInventory(player, inventoryStore)
    local userId = player.UserId
    if not self.playersInventory[userId] then
        self.playersInventory[userId] = {}
    end

    for itemName, itemData in pairs(inventoryStore) do
        self.playersInventory[userId][itemName] = itemData
    end
    -- if inventoryStore and string.len(inventoryStore) > 0 then
    --     local inventory = HttpService:JSONDecode(inventoryStore)
    --     for itemName, itemData in pairs(inventory) do
    --         self.playersInventory[userId][itemName] = itemData
    --     end
    -- end
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
        icon = "rbxassetid://12345678",
        isUsed = false
    }
    
    Knit.GetService('DBService'):Set(userId, "PlayerInventory", self.playersInventory[userId])
    self.Client.AddItem:Fire(player, self.playersInventory[userId][itemName])
    
    return true
end

function InventoryService:RemoveItemFromInventory(player, itemName)
    local userId = player.UserId
    if not self.playersInventory[userId] then
        self.playersInventory[userId] = {}
    end

    if self.playersInventory[userId][itemName] then
        self.playersInventory[userId][itemName].num = math.max(0, self.playersInventory[userId][itemName].num - 1)
        if self.playersInventory[userId][itemName].num == 0 then
            self.playersInventory[userId][itemName] = nil
        end
        
        Knit.GetService('DBService'):Set(userId, "PlayerInventory", self.playersInventory[userId])
        self.Client.RemoveItem:Fire(player, self.playersInventory[userId][itemName])
    end
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
                itemData.isUsed = true
            end
        end
    end
end

function InventoryService:GetUnusedParts(player, modelName)
    local userId = player.UserId
    local unused = {}
    if self.playersInventory[userId] then
        for _, itemData in pairs(self.playersInventory[userId]) do
            if itemData.modelName == modelName and not itemData.isUsed then
                table.insert(unused, itemData)
            end
        end
    end
    return unused
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