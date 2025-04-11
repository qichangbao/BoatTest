print('InventoryService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local InventoryService = Knit.CreateService({
    Name = 'InventoryService',
    Client = {
        UpdateInventory = Knit.CreateSignal(),
    },
    playersInventory = {},
})

function InventoryService:AddItemToInventory(player, itemType)
    if not self.playersInventory[player] then
        self.playersInventory[player] = {}
    end
    
    self.playersInventory[player][itemType] = {
        itemType = itemType,
        quantity = (self.playersInventory[player][itemType] and self.playersInventory[player][itemType].quantity or 0) + 1,
        icon = "rbxassetid://12345678", -- 临时图标，需替换为正式配置
    }
    
    self.Client.UpdateInventory:Fire(player, self.playersInventory[player], itemType)
    
    return true
end

function InventoryService:RemoveItemFromInventory(player, itemType)
    --[[
        从玩家库存中移除指定类型的物品
        @param player: 玩家实例
        @param itemType: 要移除的物品类型
        @return: 无返回值
    ]]--
    if self.playersInventory[player][itemType] then
        self.playersInventory[player][itemType].quantity = math.max(0, self.playersInventory[player][itemType].quantity - 1)
        if self.playersInventory[player][itemType].quantity == 0 then
            self.playersInventory[player][itemType] = nil
        end
        
        self.Client.UpdateInventory:Fire(player, self.playersInventory[player])
    end
end

function InventoryService:CheckExists(player, itemType)
    local inventory = self:GetPlayerInventory(player)
    return inventory[itemType] ~= nil
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
            - AddItem/RemoveItem: itemType (string) 物品类型
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