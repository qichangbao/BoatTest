local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("ItemConfig"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))
local BadgeConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BadgeConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

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
    self.playersInventory[userId] = {}

    if inventoryStore then
        for itemName, itemData in pairs(inventoryStore) do
            local data = table.clone(itemData)
            data.isUsed = 0
            self.playersInventory[userId][itemName] = data
        end
    end
    self.Client.InitInventory:Fire(player, self.playersInventory[userId])
end

function InventoryService:ResetPlayerInventory(player, inventory)
    self.playersInventory[player.UserId] = inventory
    Knit.GetService('DBService'):Set(player.UserId, "PlayerInventory", inventory)
    self.Client.InitInventory:Fire(player, self.playersInventory[player.UserId])
end

function InventoryService:AddSingleItem(userId, itemType, itemName, modelName, num)
    local data = {itemType = itemType, itemName = itemName, modelName = modelName, num = num, isUsed = 0}
    self.playersInventory[userId][itemName] = {itemType = itemType, itemName = itemName, modelName = modelName, num = num, isUsed = 0}
    return data
end

function InventoryService:GetInitData(userId)
    local data = {}
    for i, v in pairs(self.playersInventory[userId]) do
        data[i] = {itemType = v.itemType, itemName = v.itemName, modelName = v.modelName, num = v.num}
    end

    return data
end

function InventoryService:CheckCompleteBoat(player, modelName)
    local boatConfig = BoatConfig.GetBoatConfig(modelName)
    if not boatConfig then
        return
    end

    for partName, _ in pairs(boatConfig) do
        if not self:CheckExists(player, partName) then
            return false
        end
    end
    return true
end

function InventoryService:AddItemToInventory(player, itemType, itemName, modelName)
    local userId = player.UserId
    if not self.playersInventory[userId] then
        self.playersInventory[userId] = {}
    end
    self:AddSingleItem(userId, itemType, itemName, modelName, (self.playersInventory[userId][itemName] and self.playersInventory[userId][itemName].num or 0) + 1)
    local data = self:GetInitData(userId)
    Knit.GetService('DBService'):Set(userId, "PlayerInventory", data)
    self.Client.AddItem:Fire(player, self.playersInventory[userId][itemName])
    
    if itemType == ItemConfig.BoatTag then
        local boatCount = 0
        -- 检查是否集齐了一整艘船的所有部件
        for _, boatData in pairs(BoatConfig) do
            if type(boatData) == "table" then
                local isAllExist = true
                for partName, _ in pairs(boatData) do
                    if not self:CheckExists(player, partName) then
                        isAllExist = false
                        break
                    end
                end

                if isAllExist then
                    boatCount += 1
                end
            end
        end

        if boatCount == 1 then
            Interface.AwardBadge(player.UserId, BadgeConfig["Shipbuilder"].id)
        elseif boatCount == 2 then
            Interface.AwardBadge(player.UserId, BadgeConfig["FleetBegins"].id)
        end
    end
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
        
        local data = self:GetInitData(userId)
        Knit.GetService('DBService'):Set(userId, "PlayerInventory", data)
        self.Client.RemoveItem:Fire(player, modelName, itemName)
        return true
    end
    return false
end

function InventoryService:CheckExists(player, itemName)
    local inventory = self:GetPlayerInventory(player)
    return inventory ~= {} and inventory[itemName] ~= nil
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
            if itemData.modelName == modelName and itemData.isUsed == 0 and not unused[itemData.itemName] then
                unused[itemData.itemName] = true
            end
        end
    end
    return unused
end

function InventoryService:GetInventoryFromDBService(userId, value)
    local player = game.Players:GetPlayerByUserId(userId)
    if not player then
        return
    end
    self:InitPlayerInventory(player, value)
end

function InventoryService.Client:GetInventory(player)
    return self.Server:GetPlayerInventory(player)
end

function InventoryService:KnitInit()
end

function InventoryService:KnitStart()
end

return InventoryService