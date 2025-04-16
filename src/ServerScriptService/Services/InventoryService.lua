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

function InventoryService:AddItemToInventory(player, itemName, modelName)
    if not self.playersInventory[player] then
        self.playersInventory[player] = {}
    end
    
    self.playersInventory[player][itemName] = {
        itemName = itemName,
        modelName = modelName,
        num = (self.playersInventory[player][itemName] and self.playersInventory[player][itemName].num or 0) + 1,
        icon = "rbxassetid://12345678",
        isUsed = false
    }
    
    self.Client.AddItem:Fire(player, self.playersInventory[player][itemName])
    
    return true
end

function InventoryService:RemoveItemFromInventory(player, itemName)
    if not self.playersInventory[player] then
        self.playersInventory[player] = {}
    end

    if self.playersInventory[player][itemName] then
        self.playersInventory[player][itemName].num = math.max(0, self.playersInventory[player][itemName].num - 1)
        if self.playersInventory[player][itemName].num == 0 then
            self.playersInventory[player][itemName] = nil
        end
        
        self.Client.RemoveItem:Fire(player, self.playersInventory[player][itemName])
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
    return self.playersInventory[player] or {}
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
    if self.playersInventory[player] then
        for _, itemData in pairs(self.playersInventory[player]) do
            if itemData.modelName == modelName then
                itemData.isUsed = true
            end
        end
    end
end

function InventoryService:GetUnusedParts(player, modelName)
    local unused = {}
    if self.playersInventory[player] then
        for itemName, itemData in pairs(self.playersInventory[player]) do
            if itemData.modelName == modelName and not itemData.isUsed then
                table.insert(unused, itemData)
            end
        end
    end
    return unused
end

function InventoryService:MarkAllBoatPartAsUsed(player, modelName)
    if self.playersInventory[player] then
        for _, itemData in pairs(self.playersInventory[player]) do
            if itemData.modelName == modelName then
                itemData.isUsed = true
            end
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