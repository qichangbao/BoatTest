local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 初始化组装事件
local ASSEMBLE_BOAT_RE_NAME = 'AssembleBoatEvent'
local assembleEvent = Instance.new('RemoteEvent')
assembleEvent.Name = ASSEMBLE_BOAT_RE_NAME
assembleEvent.Parent = ReplicatedStorage

-- 初始化库存绑定函数
local INVENTORY_BF_NAME = 'InventoryBindableFunction'
local inventoryBF = Instance.new('BindableFunction')
inventoryBF.Name = INVENTORY_BF_NAME
inventoryBF.Parent = ReplicatedStorage

-- 创建控制船事件
local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
local controlEvent = Instance.new('RemoteEvent')
controlEvent.Name = BOAT_CONTROL_RE_NAME
controlEvent.Parent = ReplicatedStorage

-- 初始化止航事件
local STOP_BOAT_RE_NAME = 'StopBoatEvent'
local stopEvent = Instance.new('RemoteEvent')
stopEvent.Name = STOP_BOAT_RE_NAME
stopEvent.Parent = ReplicatedStorage

-- 初始化更新UI事件
local UPDATE_MAINUI_RE_NAME = 'UpdateMainUIEvent'
local updateMainUIEvent = Instance.new('RemoteEvent')
updateMainUIEvent.Name = UPDATE_MAINUI_RE_NAME
updateMainUIEvent.Parent = ReplicatedStorage

-- 通知客户端更新UI
local INVENTORY_UPDATE_RE_NAME = 'InventoryUpdateEvent'
local updateInventoryEvent = Instance.new('RemoteEvent')
updateInventoryEvent.Name = INVENTORY_UPDATE_RE_NAME
updateInventoryEvent.Parent = ReplicatedStorage

-- 请求库存数据
local GET_INVENTORY_RE_NAME = 'RequestInventoryData'
local requestInventoryEvent = Instance.new('RemoteEvent')
requestInventoryEvent.Name = GET_INVENTORY_RE_NAME
requestInventoryEvent.Parent = ReplicatedStorage

-- 库存数据
local LOOT_RE_NAME = 'LootEvent'
local lootEvent = Instance.new('RemoteEvent')
lootEvent.Name = LOOT_RE_NAME
lootEvent.Parent = ReplicatedStorage

-- 初始化金币更新远程事件
local GOLD_UPDATE_RE_NAME = 'GoldUpdateEvent'
local goldEvent = Instance.new('RemoteEvent')
goldEvent.Name = GOLD_UPDATE_RE_NAME
goldEvent.Parent = ReplicatedStorage

-- 初始化库存界面远程事件
local INVENTORY_BE_NAME = 'InventoryEvent'
local inventoryEvent = Instance.new('BindableEvent')
inventoryEvent.Name = INVENTORY_BE_NAME
inventoryEvent.Parent = ReplicatedStorage

-- 初始化止航按钮绑定函数
local STOP_BOAT_BE_NAME = 'StopBoatEventBE'
local stopEventBE = Instance.new('BindableEvent')
stopEventBE.Name = STOP_BOAT_BE_NAME
stopEventBE.Parent = ReplicatedStorage

print("服务器脚本初始化完成")
return {}