print('BoatAssemblingService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local BOAT_PARTS_FOLDER_NAME = '船'

local BoatAssemblingService = Knit.CreateService({
    Name = 'BoatAssemblingService',
    Client = {
        UpdateMainUI = Knit.CreateSignal(),
        UpdateInventory = Knit.CreateSignal(),
        DestroyBoat = Knit.CreateSignal(),
    },
})

local function CreateBoat(player)
    local InventoryService = Knit.GetService("InventoryService")
    -- 获取玩家库存中的船部件
    local inventory = InventoryService:Inventory(player, 'GetInventory')
    -- 检查库存有效性并收集船部件
    local boatParts = {}
    for itemName, itemData in pairs(inventory) do
        table.insert(boatParts, {
            Name = itemName,
            Data = itemData
        })
    end

    if #boatParts == 0 then
        return "玩家没有可用的船部件"
    end

    -- 确保ServerStorage中存在船舶模板
    local boatTemplate = ServerStorage:FindFirstChild(BOAT_PARTS_FOLDER_NAME)
    -- 校验服务器预置的船只模板是否存在
    if not boatTemplate then
        return '没有在ServerStorage找到船模板'
    end

    local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]
    local primaryPartName = ''
    for name, data in pairs(curBoatConfig) do
        if data.isPrimaryPart then
            primaryPartName = name
            break
        end
    end
    if primaryPartName == '' then
        return '找不到主船体部件'
    end

    -- 克隆模板并定位部件
    -- 创建新模型容器并保持模板原始坐标关系
    -- 使用模板的CFrame保持部件相对位置，确保物理模拟准确性
    local boat = Instance.new('Model')
    boat.Name = 'PlayerBoat_'..player.UserId
    boat.Parent = workspace
    boat:SetAttribute('ModelName', boatTemplate.Name)
    boat.Destroying:Connect(function()
        print('船被销毁')
        Knit.GetService('BoatMovementService'):OnBoat(player, false)
    end)
    
    local primaryPart = nil
    -- 先收集所有部件偏移量
    local templatePrimaryPart = boatTemplate:FindFirstChild(primaryPartName)
    local partOffsets = {}
    
    for _, partInfo in ipairs(boatParts) do
        for _, templatePart in ipairs(boatTemplate:GetChildren()) do
            if templatePart:IsA('MeshPart') and partInfo.Name == templatePart.Name then
                -- 记录部件相对于模板主船体的偏移
                local offsetCFrame = templatePrimaryPart.CFrame:ToObjectSpace(templatePart.CFrame)
                partOffsets[partInfo.Name] = offsetCFrame
                break
            end
        end
    end

    local boatHP = 0
    local boatSpeed = 0
    -- 创建主船体
    for _, partInfo in ipairs(boatParts) do
        if partInfo.Name == primaryPartName then
            primaryPart = boatTemplate:FindFirstChild(partInfo.Name):Clone()
            primaryPart.CFrame = templatePrimaryPart.CFrame
            primaryPart.Parent = boat
            boat.PrimaryPart = primaryPart
            boatHP += curBoatConfig[partInfo.Name].HP
            boatSpeed += curBoatConfig[partInfo.Name].speed
            break
        end
    end

    -- 统一创建其他部件
    for _, partInfo in ipairs(boatParts) do
        if partInfo.Name ~= primaryPartName then
            local templatePart = boatTemplate:FindFirstChild(partInfo.Name)
            if templatePart then
                local partClone = templatePart:Clone()
                -- 应用主船体位置+模板偏移
                partClone.CFrame = primaryPart.CFrame * partOffsets[partInfo.Name]
                partClone.Parent = boat
                partClone.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Wood)
                boatHP += curBoatConfig[partInfo.Name].HP
                boatSpeed += curBoatConfig[partInfo.Name].speed

                -- 创建焊接约束
                local weldConstraint = Instance.new('WeldConstraint')
                weldConstraint.Part0 = primaryPart
                weldConstraint.Part1 = partClone
                weldConstraint.Parent = partClone
            end
        end
    end

    boat:SetAttribute('Health', boatHP)
    boat:SetAttribute('Speed', boatSpeed)
    return boat
end

-- 创建船的驾驶座位
local function CreateVehicleSeat(boat)
    local driverSeat = boat:FindFirstChild('DriverSeat')
    if driverSeat then
        return
    end

    local primaryPart = boat.PrimaryPart
    -- 创建驾驶座位
    local primaryCFrame = primaryPart.CFrame
    driverSeat = Instance.new('VehicleSeat')
    driverSeat.Name = 'DriverSeat'
    driverSeat.Parent = boat
    driverSeat.Anchored = false
    
    -- 设置座位权限，仅允许创建者坐下
    driverSeat:GetPropertyChangedSignal('Occupant'):Connect(function()
        local occupant = driverSeat.Occupant
        if occupant and occupant.Parent then
            local humanoid = occupant.Parent:FindFirstChildOfClass('Humanoid')
            if humanoid and humanoid.Parent:IsA('Model') then
                local playerTemp = game.Players:GetPlayerFromCharacter(humanoid.Parent)
                if playerTemp and playerTemp.UserId ~= tonumber(string.match(boat.Name, 'PlayerBoat_(%d+)')) then
                    driverSeat.Disabled = false
                    task.wait(0.1)
                    driverSeat.Disabled = true
                    driverSeat.Occupant = nil
                    return
                end
            end
        end
    end)

    local currentCFrame = driverSeat:GetPivot()
    driverSeat.CFrame = CFrame.new(primaryCFrame.X, primaryCFrame.Y, primaryCFrame.Z) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())

    -- 创建焊接约束
    local weldConstraint = Instance.new('WeldConstraint')
    weldConstraint.Part0 = primaryPart
    weldConstraint.Part1 = driverSeat
    weldConstraint.Parent = driverSeat
end

-- 创建船的移动性和旋转性
local function CreateMoveVelocity(primaryPart)
    local boatBodyVelocity = primaryPart:FindFirstChild("BoatBodyVelocity")
    if not boatBodyVelocity then
        -- 创建船的移动性
        boatBodyVelocity = Instance.new("BodyVelocity")
        boatBodyVelocity.Name = "BoatBodyVelocity"
        boatBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
        boatBodyVelocity.P = 1250
        boatBodyVelocity.Parent = primaryPart
        boatBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end

    local bodyAngularVelocity = primaryPart:FindFirstChild("BoatBodyAngularVelocity")
    if not bodyAngularVelocity then
        -- 创建船的旋转性
        bodyAngularVelocity = Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.Name = "BoatBodyAngularVelocity"
        bodyAngularVelocity.MaxTorque = Vector3.new(0, 500000, 0)
        bodyAngularVelocity.P = 500
        bodyAngularVelocity.Parent = primaryPart
        bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    end
end

-- 创建船的稳定器
local function CreateStabilizer(boat)
    local function createPart(name, size, cFrame)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.Material = Enum.Material.Wood
        part.Anchored = false
        part.CanCollide = true
        part.Transparency = 1
        local offsetCFrame = boat.PrimaryPart.CFrame:ToObjectSpace(cFrame)
        part.CFrame = boat.PrimaryPart.CFrame * offsetCFrame
        part.Parent = boat
        -- 创建焊接约束
        local weldConstraint = Instance.new('WeldConstraint')
        weldConstraint.Part0 = boat.PrimaryPart
        weldConstraint.Part1 = part
        weldConstraint.Parent = part
    end
    local size = Vector3.new(4, 1, 20)
    createPart("BoatStabilizerPart1", size,
    CFrame.new(boat.PrimaryPart.Position.X + boat.PrimaryPart.Size.X / 2 - 5,
    boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    boat.PrimaryPart.Position.Z))
    createPart("BoatStabilizerPart2", size,
    CFrame.new(boat.PrimaryPart.Position.X - boat.PrimaryPart.Size.X / 2 + 5,
    boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    boat.PrimaryPart.Position.Z))
    size = Vector3.new(10, 1, 4)
    createPart("BoatStabilizerPart3", size,
    CFrame.new(boat.PrimaryPart.Position.X,
    boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    boat.PrimaryPart.Position.Z - boat.PrimaryPart.Size.Z / 2 + 12))
    createPart("BoatStabilizerPart4", size,
    CFrame.new(boat.PrimaryPart.Position.X,
    boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    boat.PrimaryPart.Position.Z + boat.PrimaryPart.Size.Z / 2 - 12))
end

function BoatAssemblingService.Client:AssembleBoat(player)
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..player.UserId)
    if boat then
        return "船已存在"
    end

    boat = CreateBoat(player)
    if not boat or not boat.primaryPart then
        return "玩家没有可用的船主部件"
    end

    CreateVehicleSeat(boat)
    CreateStabilizer(boat)
    CreateMoveVelocity(boat.primaryPart)

    -- 设置船的初始位置
    Interface:InitBoatWaterPos(player.character, boat)
    Knit.GetService('BoatMovementService'):OnBoat(player, true)
    Knit.GetService('InventoryService'):BoatAssemblySuccess(player, boat:GetAttribute('ModelName'))
    -- 触发客户端事件更新主界面UI
    self.UpdateMainUI:Fire(player, {explore = true})
    self.UpdateInventory:Fire(player, boat:GetAttribute('ModelName'))

    return "船组装成功"
end

function BoatAssemblingService:AttachPartToBoat(boat, partType)
    if not boat or not boat.PrimaryPart then
        return '无效的船只模型'
    end
    
    local modelName = boat:GetAttribute('ModelName')
    local boatTemplate = ServerStorage:FindFirstChild(modelName)
    local templatePart = boatTemplate:FindFirstChild(partType)
    if not templatePart then
        return '找不到部件模板'
    end
    
    local curBoatConfig = BoatConfig[modelName]
    local primaryPartName = ''
    for name, data in pairs(curBoatConfig) do
        if data.isPrimaryPart then
            primaryPartName = name
            break
        end
    end
    if primaryPartName == '' then
        return '找不到主船体部件'
    end
    local templatePrimaryPart = boatTemplate:FindFirstChild(primaryPartName)
    -- 计算模板部件相对主船体的偏移
    local offset = templatePrimaryPart.CFrame:ToObjectSpace(templatePart.CFrame)
    -- 应用当前主船体实际位置
    local partClone = templatePart:Clone()
    partClone.CFrame = boat.PrimaryPart.CFrame * offset
    partClone.Parent = boat
    partClone.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Wood)
    
    local weldConstraint = Instance.new('WeldConstraint')
    weldConstraint.Part0 = boat.PrimaryPart
    weldConstraint.Part1 = partClone
    weldConstraint.Parent = partClone
end

function BoatAssemblingService:AddUnusedPartsToBoat(player)
    local boat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not boat then
        return '添加部件失败，船不存在'
    end
    
    local curBoatConfig = BoatConfig[boat:GetAttribute('ModelName')]
    local boatHP = boat:GetAttribute('Health')
    local boatSpeed = boat:GetAttribute('Speed')
    local InventoryService = Knit.GetService("InventoryService")
    local unusedParts = InventoryService:GetUnusedParts(player, boat:GetAttribute('ModelName'))
    for _, partInfo in pairs(unusedParts) do
        self:AttachPartToBoat(boat, partInfo.itemName)
        boatHP += curBoatConfig[partInfo.itemName].HP
        boatSpeed += curBoatConfig[partInfo.itemName].speed
    end
    boat:SetAttribute('Health', boatHP)
    boat:SetAttribute('Speed', boatSpeed)
    InventoryService:MarkAllBoatPartAsUsed(player, boat:GetAttribute('ModelName'))
    
    self.Client.UpdateInventory:Fire(player, boat:GetAttribute('ModelName'))
    return '部件添加成功'
end

-- 执行船只组装核心逻辑
-- @param player 发起组装请求的玩家对象
-- @return Model 组装完成的船只模型
function BoatAssemblingService.Client:AddUnusedPartsToBoat(player)
    return self.Server:AddUnusedPartsToBoat(player)
end

function BoatAssemblingService:DestroyBoat(player, boat)
    -- 断开所有焊接约束
    for _, part in ipairs(boat:GetDescendants()) do
        if part:IsA('WeldConstraint') or part:IsA('VehicleSeat') then
            part:Destroy()
        end
    end

    -- 10秒后清理
    task.delay(10, function()
        -- 原部件清理逻辑
        for _, part in ipairs(boat:GetChildren()) do
            if part:IsA('BasePart') then
                part:Destroy()
            end
        end
        boat:Destroy()
    end)

    -- 移除主船体关联
    self.Client.UpdateMainUI:Fire(player, {explore = false})
    Knit.GetService('BoatMovementService'):OnBoat(player, false)
end

function BoatAssemblingService.Client:StopBoat(player)
    Knit.GetService('BoatMovementService'):OnBoat(player, false)
    self.UpdateMainUI:Fire(player, {explore = false})

    Interface:InitPlayerPos(player)

    local playerBoat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not playerBoat then
        return "船不存在"
    end

    playerBoat:Destroy()
    return "船已销毁"
end

function BoatAssemblingService:KnitInit()
    print('BoatAssemblingService initialized')
end

function BoatAssemblingService:KnitStart()
    print('BoatAssemblingService started')
end

return BoatAssemblingService