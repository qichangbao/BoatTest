--[[
库存管理系统服务器端模块
功能：负责管理玩家物品的添加、移除和查询操作，通过远程事件与客户端同步数据
版本:v1.0.0
最后修改：2025/3/20
]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local InventoryManager = {}
InventoryManager.__index = InventoryManager

-- 通知客户端更新UI
local INVENTORY_UPDATE_RE_NAME = 'InventoryUpdateEvent'
local updateEvent = ReplicatedStorage:FindFirstChild(INVENTORY_UPDATE_RE_NAME)
if not updateEvent then
    updateEvent = Instance.new('RemoteEvent')
    updateEvent.Name = INVENTORY_UPDATE_RE_NAME
    updateEvent.Parent = ReplicatedStorage
end

local INVENTORY_BF_NAME = 'InventoryBindableFunction'
local inventoryBF = ReplicatedStorage:FindFirstChild(INVENTORY_BF_NAME)
if not inventoryBF then
    inventoryBF = Instance.new('BindableFunction')
    inventoryBF.Name = INVENTORY_BF_NAME
    inventoryBF.Parent = ReplicatedStorage
end

-- 创建新的库存管理器实例
function InventoryManager.new()
    local self = setmetatable({}, InventoryManager)
    self.playersInventory = {}
    
    -- 绑定远程函数调用处理
    inventoryBF.OnInvoke = function(player, action, ...)
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
    
    return self
end

function InventoryManager:AddItemToInventory(player, itemType)
    if not self.playersInventory[player] then
        self.playersInventory[player] = {}
    end
    
    self.playersInventory[player][itemType] = {
        itemType = itemType,
        quantity = (self.playersInventory[player][itemType] and self.playersInventory[player][itemType].quantity or 0) + 1,
        icon = "rbxassetid://12345678", -- 临时图标，需替换为正式配置
    }
    
    updateEvent:FireClient(player, 'Update', self.playersInventory[player])
    
    return true
end

function InventoryManager:RemoveItemFromInventory(player, itemType)
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
        
        updateEvent:FireClient(player, 'Update', self.playersInventory[player])
    end
end

function InventoryManager:CheckExists(player, itemType)
    local inventory = self:GetPlayerInventory(player)
    return inventory[itemType] ~= nil
end

function InventoryManager:GetPlayerInventory(player)
    --[[
        获取指定玩家的完整库存数据
        @param player: 玩家实例
        @return: 包含玩家所有物品的table
    ]]--
    return self.playersInventory[player] or {}
end

return InventoryManager.new()