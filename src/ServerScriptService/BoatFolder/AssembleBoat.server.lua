-- 船只组装服务模块
-- 处理玩家通过远程事件发起的船只组装请求，负责验证部件、克隆模板、定位部件并生成最终船只模型

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local keyboardService = game:GetService("UserInputService")
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local BOAT_PARTS_FOLDER_NAME = '船'

-- 初始化远程事件
local ASSEMBLE_BOAT_RE_NAME = 'AssembleBoatEvent'
local assembleEvent = ReplicatedStorage:FindFirstChild(ASSEMBLE_BOAT_RE_NAME) or Instance.new('RemoteEvent')
assembleEvent.Name = ASSEMBLE_BOAT_RE_NAME
assembleEvent.Parent = ReplicatedStorage

-- 初始化库存绑定函数
local INVENTORY_BF_NAME = 'InventoryBindableFunction'
local inventoryBF = ReplicatedStorage:WaitForChild(INVENTORY_BF_NAME) or Instance.new('BindableFunction')
inventoryBF.Name = INVENTORY_BF_NAME
inventoryBF.Parent = ReplicatedStorage

-- 创建控制远程事件
local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
local controlEvent = ReplicatedStorage:FindFirstChild(BOAT_CONTROL_RE_NAME) or Instance.new('RemoteEvent')
controlEvent.Name = BOAT_CONTROL_RE_NAME
controlEvent.Parent = ReplicatedStorage

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
    assembledBoat.Name = 'PlayerBoat_'..player.UserId
    assembledBoat.Parent = workspace
    
    local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]
    local primaryPart = nil
    for _, partInfo in ipairs(boatParts) do
        for _, templatePart in ipairs(boatTemplate:GetChildren()) do
            if templatePart:IsA('MeshPart') and partInfo.Type == templatePart.Name then
                local partClone = templatePart:Clone()
                partClone.CFrame = templatePart.CFrame
                partClone.Parent = assembledBoat

                if partInfo.Type == curBoatConfig[1].Name then
                    assembledBoat.PrimaryPart = partClone
                    primaryPart = partClone  -- 保存主船体引用
                end

                -- 创建焊接约束
                if primaryPart and partClone ~= primaryPart then
                    local weld = Instance.new('WeldConstraint')
                    weld.Part0 = primaryPart
                    weld.Part1 = partClone
                    weld.Parent = partClone
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
    
    -- 创建焊接约束
    if primaryPart then
        local weldConstraint = Instance.new('WeldConstraint')
        weldConstraint.Part0 = primaryPart
        weldConstraint.Part1 = driverSeat
        weldConstraint.Parent = driverSeat

        local seatWeld = Instance.new('Weld')
        seatWeld.Name = 'SeatWeld'
        seatWeld.Part0 = driverSeat
        seatWeld.Part1 = player.Character:WaitForChild('HumanoidRootPart')
        seatWeld.Parent = driverSeat
    end

    -- 触发客户端事件传递座位引用
    controlEvent:FireClient(player, 'SetDriverSeat')
    
    -- 添加座位占用监听
    -- 监听玩家入座事件
    driverSeat:GetPropertyChangedSignal('Occupant'):Connect(function()
        local humanoid = driverSeat.Occupant
        if humanoid then
            local character = humanoid.Parent
            local seatedPlayer = Players:GetPlayerFromCharacter(character)
            
            -- 监听玩家离座事件
            humanoid.Seated:Connect(function(isSeated)
                if not isSeated then
                    controlEvent:FireClient(seatedPlayer, 'ClearDriverSeat')
                end
            end)
        end
    end)

    -- 设置船的初始位置
    require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface')):InitBoatWaterPos(player.character, assembledBoat, driverSeat)

    return assembledBoat
end

assembleEvent.OnServerEvent:Connect(assembleBoat)