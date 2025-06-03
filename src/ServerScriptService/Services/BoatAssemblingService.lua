print('BoatAssemblingService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService('ServerStorage')
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))

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

function BoatAssemblingService:CreateBoat(player)
    if not player or not player.Character or not player.Character.Humanoid then
        return
    end

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
        return
    end

    -- 确保ServerStorage中存在船舶模板
    local boatTemplate = ServerStorage:FindFirstChild(BOAT_PARTS_FOLDER_NAME)
    -- 校验服务器预置的船只模板是否存在
    if not boatTemplate then
        return
    end

    local curBoatConfig = BoatConfig.GetBoatConfig(BOAT_PARTS_FOLDER_NAME)
    local primaryPartName = ''
    for name, data in pairs(curBoatConfig) do
        if data.isPrimaryPart then
            primaryPartName = name
            break
        end
    end
    if primaryPartName == '' then
        return
    end

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
    
    local primaryPart = nil
    local boatHP = 0
    local boatSpeed = 0
    -- 创建主船体
    for _, partInfo in ipairs(boatParts) do
        if partInfo.Name == primaryPartName then
            primaryPart = boatTemplate:FindFirstChild(partInfo.Name):Clone()
            boatHP += curBoatConfig[partInfo.Name].HP
            boatSpeed += curBoatConfig[partInfo.Name].speed
            break
        end
    end

    if not primaryPart then
        return
    end

    -- 克隆模板并定位部件
    -- 创建新模型容器并保持模板原始坐标关系
    -- 使用模板的CFrame保持部件相对位置，确保物理模拟准确性
    local boat = Instance.new('Model')
    boat.Name = 'PlayerBoat_'..player.UserId
    boat.Parent = workspace
    boat:SetAttribute('ModelName', boatTemplate.Name)
    boat:SetAttribute('ModelType', 'Boat')
    boat:SetAttribute('Destroying', false)
    CollectionService:AddTag(boat, "Boat")

    primaryPart.CFrame = templatePrimaryPart.CFrame
    primaryPart.Parent = boat
    boat.PrimaryPart = primaryPart

    -- 监听船的销毁事件
    boat.Destroying:Connect(function()
        print('船被销毁')
        if not player or not player.Character or not player.Character.Humanoid then
            return
        end
        -- 移除主船体关联
        self.Client.UpdateMainUI:Fire(player, {explore = false})
        Knit.GetService('BoatMovementService'):OnBoat(player, false)
        CollectionService:RemoveTag(boat, "Boat")
    end)

    boat:GetAttributeChangedSignal('Health'):Connect(function()
        local health = boat:GetAttribute('Health')
        local maxHealth = boat:GetAttribute('MaxHealth')
        Knit.GetService('BoatAttributeService'):ChangeBoatHealth(player, health, maxHealth)
        
        if health <= 0 then
            self:DestroyBoat(player)
            return
        end
    end)

    boat:GetAttributeChangedSignal('Speed'):Connect(function()
        local speed = boat:GetAttribute('Speed')
        local maxSpeed = boat:GetAttribute('MaxSpeed')
        Knit.GetService('BoatAttributeService'):ChangeBoatSpeed(player, speed, maxSpeed)
    end)

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

    boat:SetAttribute('Health', math.max(boatHP, 0))
    boat:SetAttribute('MaxHealth', math.max(boatHP, 0))
    boat:SetAttribute('Speed', math.max(boatSpeed, 0))
    boat:SetAttribute('MaxSpeed', math.max(boatSpeed, 0))
    return boat
end

-- 创建船的驾驶座位
function BoatAssemblingService:CreateVehicleSeat(boat)
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
                local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
                if player and player.UserId ~= tonumber(string.sub(boat.Name, 12)) then
                    driverSeat.Disabled = false
                    task.wait(0.1)
                    driverSeat.Disabled = true
                    humanoid.Jump = true
                    return
                end
            end
        end
    end)

    local currentCFrame = driverSeat:GetPivot()
    driverSeat.CFrame = CFrame.new(primaryCFrame.X, primaryCFrame.Y + 6, primaryCFrame.Z + 5) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())

    -- 创建焊接约束
    local weldConstraint = Instance.new('WeldConstraint')
    weldConstraint.Part0 = primaryPart
    weldConstraint.Part1 = driverSeat
    weldConstraint.Parent = driverSeat
end

-- 创建船的移动性和旋转性
function BoatAssemblingService:CreateMoveVelocity(primaryPart)
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
function BoatAssemblingService:CreateStabilizer(boat)
    -- local function createPart(name, size, cFrame)
    --     local part = Instance.new("Part")
    --     part.Name = name
    --     part.Size = size
    --     part.Material = Enum.Material.Wood
    --     part.Anchored = false
    --     part.CanCollide = true
    --     part.Transparency = 1
    --     local offsetCFrame = boat.PrimaryPart.CFrame:ToObjectSpace(cFrame)
    --     part.CFrame = boat.PrimaryPart.CFrame * offsetCFrame
    --     part.Parent = boat
    --     -- 创建焊接约束
    --     local weldConstraint = Instance.new('WeldConstraint')
    --     weldConstraint.Part0 = boat.PrimaryPart
    --     weldConstraint.Part1 = part
    --     weldConstraint.Parent = part

    --     part.CollisionGroup = "BoatStabilizerCollisionGroup"
    -- end

    -- local size = Vector3.new(10, 5, 20)
    -- createPart("BoatStabilizerPart1", size,
    --     CFrame.new(boat.PrimaryPart.Position.X + boat.PrimaryPart.Size.X / 2 + 5,
    --         boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    --         boat.PrimaryPart.Position.Z))
    -- createPart("BoatStabilizerPart2", size,
    --     CFrame.new(boat.PrimaryPart.Position.X - boat.PrimaryPart.Size.X / 2 - 5,
    --         boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    --         boat.PrimaryPart.Position.Z))
    -- size = Vector3.new(20, 5, 10)
    -- createPart("BoatStabilizerPart3", size,
    --     CFrame.new(boat.PrimaryPart.Position.X,
    --         boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    --         boat.PrimaryPart.Position.Z - boat.PrimaryPart.Size.Z / 2 + 12))
    -- createPart("BoatStabilizerPart4", size,
    --     CFrame.new(boat.PrimaryPart.Position.X,
    --         boat.PrimaryPart.Position.Y - boat.PrimaryPart.Size.Y / 2,
    --         boat.PrimaryPart.Position.Z + boat.PrimaryPart.Size.Z / 2 - 12))

    -- 为船只添加现代约束稳定系统
    if not boat.PrimaryPart then return end
    
    -- 创建锚点
    local anchor = Instance.new("Part")
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.Position = boat.PrimaryPart.Position
    anchor.Parent = workspace
    
    -- 创建 Attachment
    local boatAttachment = Instance.new("Attachment")
    boatAttachment.Parent = boat.PrimaryPart
    
    local anchorAttachment = Instance.new("Attachment")
    anchorAttachment.Parent = anchor
    
    -- 方向约束（只限制X和Z轴旋转，允许Y轴旋转）
    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Attachment0 = boatAttachment
    alignOrientation.Attachment1 = anchorAttachment
    alignOrientation.MaxTorque = 3000 -- 降低扭矩
    alignOrientation.Responsiveness = 8 -- 降低响应速度
    alignOrientation.RigidityEnabled = false -- 关闭刚性模式
    alignOrientation.Parent = boat.PrimaryPart
    
    -- 位置约束（保持浮力）
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Attachment0 = boatAttachment
    alignPosition.Attachment1 = anchorAttachment
    alignPosition.MaxForce = 4000
    alignPosition.Responsiveness = 5
    alignPosition.RigidityEnabled = false
    alignPosition.Parent = boat.PrimaryPart
end

-- 动态重心平衡系统
local function addDynamicBalance(boat)
    if not boat.PrimaryPart then return end
    
    -- 创建隐形的平衡重物
    local balanceWeight = Instance.new("Part")
    balanceWeight.Name = "BalanceWeight"
    balanceWeight.Anchored = false
    balanceWeight.CanCollide = false
    balanceWeight.Transparency = 1
    balanceWeight.Size = Vector3.new(1, 1, 1)
    balanceWeight.Parent = boat
    
    -- 设置平衡重物的物理属性
    balanceWeight.CustomPhysicalProperties = PhysicalProperties.new(
        2.0, -- 高密度作为配重
        0.5,
        0.5,
        1,
        1
    )
    
    -- 将平衡重物焊接到船体左侧（补偿右倾）
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = boat.PrimaryPart
    weld.Part1 = balanceWeight
    weld.Parent = boat.PrimaryPart
    
    -- 设置平衡重物位置（船体左侧下方）
    balanceWeight.CFrame = boat.PrimaryPart.CFrame * CFrame.new(-2, -1, 0)
end

-- 检查船只平衡状态
local function checkBoatBalance(boat)
    if not boat.PrimaryPart then return end
    
    local totalMass = 0
    local centerOfMass = Vector3.new(0, 0, 0)
    local partCount = 0
    
    -- 计算质心
    for _, part in pairs(boat:GetDescendants()) do
        if part:IsA("BasePart") then
            local mass = part.Mass
            totalMass = totalMass + mass
            centerOfMass = centerOfMass + (part.Position * mass)
            partCount = partCount + 1
        end
    end
    
    if totalMass > 0 then
        centerOfMass = centerOfMass / totalMass
        print("船只质心位置:", centerOfMass)
        print("船只总质量:", totalMass)
        print("部件数量:", partCount)
        
        -- 如果质心偏右，添加左侧配重
        local boatCenter = boat.PrimaryPart.Position
        if centerOfMass.X > boatCenter.X + 0.5 then
            print("检测到右倾，建议添加左侧配重")
            addDynamicBalance(boat)
        end
    end
end

function BoatAssemblingService.Client:AssembleBoat(player)
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..player.UserId)
    if boat then
        return 10020
    end

    boat = self.Server:CreateBoat(player)
    if not boat or not boat.primaryPart then
        return 10021
    end

    self.Server:CreateVehicleSeat(boat)
    self.Server:CreateStabilizer(boat)
    self.Server:CreateMoveVelocity(boat.primaryPart)
    checkBoatBalance(boat)

    -- 设置船的初始位置
    Interface.InitBoatWaterPos(player, boat)
    Knit.GetService('BoatMovementService'):OnBoat(player, true)
    Knit.GetService('InventoryService'):BoatAssemblySuccess(player, boat:GetAttribute('ModelName'))
    -- 触发客户端事件更新主界面UI
    self.UpdateMainUI:Fire(player, {explore = true})
    self.UpdateInventory:Fire(player, boat:GetAttribute('ModelName'))

    return 10022
end

function BoatAssemblingService:AttachPartToBoat(boat, partType)
    if not boat or not boat.PrimaryPart then
        print('无效的船只模型')
        return
    end
    
    local modelName = boat:GetAttribute('ModelName')
    local boatTemplate = ServerStorage:FindFirstChild(modelName)
    local templatePart = boatTemplate:FindFirstChild(partType)
    if not templatePart then
        print('找不到部件模板')
        return
    end
    
    local curBoatConfig = BoatConfig.GetBoatConfig(modelName)
    local primaryPartName = ''
    for name, data in pairs(curBoatConfig) do
        if data.isPrimaryPart then
            primaryPartName = name
            break
        end
    end
    if primaryPartName == '' then
        print('找不到主船体部件')
        return
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
        return 10017
    end
    
    if not player or not player.Character or not player.Character.Humanoid then
        return 10018
    end
    local curBoatConfig = BoatConfig.GetBoatConfig(boat:GetAttribute('ModelName'))
    local boatHP = boat:GetAttribute('Health')
    local boatMaxHP = boat:GetAttribute('MaxHealth')
    local boatSpeed = boat:GetAttribute('Speed')
    local boatMaxSpeed = boat:GetAttribute('MaxSpeed')
    local InventoryService = Knit.GetService("InventoryService")
    local unusedParts = InventoryService:GetUnusedParts(player, boat:GetAttribute('ModelName'))
    for _, partInfo in pairs(unusedParts) do
        self:AttachPartToBoat(boat, partInfo.itemName)
        boatHP += curBoatConfig[partInfo.itemName].HP
        boatMaxHP += curBoatConfig[partInfo.itemName].HP
        boatSpeed += curBoatConfig[partInfo.itemName].speed
        boatMaxSpeed += curBoatConfig[partInfo.itemName].speed
    end
    boat:SetAttribute('Health', math.max(boatHP, 0))
    boat:SetAttribute('MaxHealth', math.max(boatHP, 0))
    boat:SetAttribute('Speed', math.max(boatSpeed, 0))
    boat:SetAttribute('MaxSpeed', math.max(boatMaxSpeed, 0))
    InventoryService:BoatAssemblySuccess(player, boat:GetAttribute('ModelName'))
    
    self.Client.UpdateInventory:Fire(player, boat:GetAttribute('ModelName'))
    return 10019
end

-- 执行船只组装核心逻辑
-- @param player 发起组装请求的玩家对象
-- @return Model 组装完成的船只模型
function BoatAssemblingService.Client:AddUnusedPartsToBoat(player)
    return self.Server:AddUnusedPartsToBoat(player)
end

function BoatAssemblingService:DestroyBoat(player)
    local boat = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface")).GetBoatByPlayerUserId(player.UserId)
    boat:SetAttribute('Destroying', true)
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
end

function BoatAssemblingService:StopBoat(player)
    local playerBoat = workspace:FindFirstChild('PlayerBoat_' .. player.UserId)
    if not playerBoat then
        local landName = Interface.InitPlayerPos(player)
        if landName then
            Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 'info', 10049, landName)
        end
        print("船不存在")
        return
    end

    playerBoat:Destroy()
    print("船已销毁")
    local landName = Interface.InitPlayerPos(player)
    if landName then
        Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 'info', 10049, landName)
    end
end

function BoatAssemblingService.Client:StopBoat(player)
    self.Server:StopBoat(player)
end

function BoatAssemblingService:KnitInit()
    print('BoatAssemblingService initialized')
end

function BoatAssemblingService:KnitStart()
    print('BoatAssemblingService started')
end

return BoatAssemblingService
