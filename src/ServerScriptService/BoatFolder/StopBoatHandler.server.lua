--[[
模块功能：止航请求处理模块
版本：1.0.0
作者：Trea
修改记录：
2024-05-20 创建基础服务端处理逻辑
--]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- 初始化远程事件
local STOP_EVENT_NAME = 'StopBoatEvent'
local stopEvent = ReplicatedStorage:FindFirstChild(STOP_EVENT_NAME)
if not stopEvent then
    stopEvent = Instance.new('RemoteEvent')
    stopEvent.Name = STOP_EVENT_NAME
    stopEvent.Parent = ReplicatedStorage
end

local INVENTORY_BF_NAME = 'InventoryBindableFunction'
local inventoryBF = ReplicatedStorage:WaitForChild(INVENTORY_BF_NAME)
if not inventoryBF then
    inventoryBF = Instance.new('BindableFunction')
    inventoryBF.Name = INVENTORY_BF_NAME
    inventoryBF.Parent = ReplicatedStorage
end

local function resetPlayerPosition(player)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = false
        end
    end
    require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface")):InitPlayerPos(player)
end

local function destroyBoatAssets(player)
    local playerBoat = workspace:WaitForChild('PlayerBoat')
    if playerBoat then
        for _, instance in ipairs(playerBoat:GetChildren()) do
            if instance:IsA('MeshPart') then
                if instance:GetAttribute("BoatName") then
                    inventoryBF:Invoke(player, 'AddItem', instance.Name)
                end
                instance:Destroy()
            end
        end
        playerBoat:Destroy()
    end
end

local function handleStopBoatRequest(player)
    resetPlayerPosition(player)
    destroyBoatAssets(player)
end

stopEvent.OnServerEvent:Connect(handleStopBoatRequest)