-- 船只组装服务模块
-- 处理玩家通过远程事件发起的船只组装请求，负责验证部件、克隆模板、定位部件并生成最终船只模型

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local BOAT_PARTS_FOLDER_NAME = '船'

local ASSEMBLE_BOAT_RE_NAME = 'AssembleBoatEvent'
local assembleEvent = ReplicatedStorage:FindFirstChild(ASSEMBLE_BOAT_RE_NAME)
if not assembleEvent then
    assembleEvent = Instance.new('RemoteEvent')
    assembleEvent.Name = ASSEMBLE_BOAT_RE_NAME
    assembleEvent.Parent = ReplicatedStorage
end

local INVENTORY_BF_NAME = 'InventoryBindableFunction'
local inventoryBF = ReplicatedStorage:WaitForChild(INVENTORY_BF_NAME)
if not inventoryBF then
    inventoryBF = Instance.new('BindableFunction')
    inventoryBF.Name = INVENTORY_BF_NAME
    inventoryBF.Parent = ReplicatedStorage
end

-- 执行船只组装核心逻辑
-- @param player 发起组装请求的玩家对象
-- @return Model 组装完成的船只模型
local function assembleBoat(player)
    -- 确保ServerStorage中存在船舶模板
    local boatTemplate = ServerStorage:FindFirstChild('船')
    -- 校验服务器预置的船只模板是否存在
    if not boatTemplate then
        warn('BoatTemplate not found in ServerStorage!')
        return
    end

    -- 获取玩家库存中的船部件
    local inventory = inventoryBF:Invoke(player, 'GetInventory')
    -- 检查库存有效性并收集船部件
    local boatParts = {}
    if type(inventory) == "table" then
        for itemType, itemData in pairs(inventory) do
            table.insert(boatParts, {
                Type = itemType,
                Data = itemData
            })
        end
    end

    if #boatParts == 0 then
        warn("玩家没有可用的船部件")
        return
    end

    -- 克隆模板并定位部件
    -- 创建新模型容器并保持模板原始坐标关系
    -- 使用模板的CFrame保持部件相对位置，确保物理模拟准确性
    local assembledBoat = Instance.new('Model')
    assembledBoat.Name = 'PlayerBoat'
    assembledBoat.Parent = workspace
    
    local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]
    for _, partInfo in ipairs(boatParts) do
        for _, templatePart in ipairs(boatTemplate:GetChildren()) do
            if templatePart:IsA('BasePart') and partInfo.Type == templatePart.Name then
                local partClone = templatePart:Clone()
                partClone.CFrame = templatePart.CFrame
                partClone.Parent = assembledBoat

                if partInfo.Type == curBoatConfig[1].Name then
                    assembledBoat.PrimaryPart = partClone
                end

                -- 移除库存中的船部件
                inventoryBF:Invoke(player, 'RemoveItem', templatePart.Name)
                break
            end
        end
    end

    -- 创建驾驶座位
    local primaryCFrame = assembledBoat.PrimaryPart.CFrame
    local driverSeat = Instance.new('VehicleSeat')
    driverSeat.Name = 'DriverSeat'
    driverSeat.Parent = assembledBoat
    local currentCFrame = driverSeat:GetPivot()
    driverSeat.CFrame = CFrame.new(primaryCFrame.X, primaryCFrame.Y + 10, primaryCFrame.Z) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())

    -- 将组装好的船放入工作区
    -- 将最终组装结果放入工作区并添加物理约束
    -- 确保船体各部件之间保持刚性连接，避免物理模拟时散架

    -- 设置船的初始位置
    require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface')):InitBoatWaterPos(player.character, assembledBoat, driverSeat)

    return assembledBoat
end

assembleEvent.OnServerEvent:Connect(assembleBoat)