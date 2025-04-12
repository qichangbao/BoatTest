print('BoatAssemblingService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local ServerStorage = game:GetService('ServerStorage')

local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
--local BuoyantController = require(game.ServerScriptService:WaitForChild("BoatFolder"):WaitForChild('buoyantController'))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local BOAT_PARTS_FOLDER_NAME = '船'

local BoatAssemblingService = Knit.CreateService({
    Name = 'BoatAssemblingService',
    Client = {
        UpdateMainUI = Knit.CreateSignal(),
    },
})

local function CreateBoat(player)
    -- 获取玩家库存中的船部件
    local InventoryService = Knit.GetService("InventoryService")
    local inventory = InventoryService:Inventory(player, 'GetInventory')
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
        return "玩家没有可用的船部件"
    end

    -- 确保ServerStorage中存在船舶模板
    local boatTemplate = ServerStorage:FindFirstChild('船')
    -- 校验服务器预置的船只模板是否存在
    if not boatTemplate then
        return '没有在ServerStorage找到船模板'
    end

    -- 克隆模板并定位部件
    -- 创建新模型容器并保持模板原始坐标关系
    -- 使用模板的CFrame保持部件相对位置，确保物理模拟准确性
    local boat = Instance.new('Model')
    boat.Name = 'PlayerBoat_'..player.UserId
    boat.Parent = workspace
    boat.Destroying:Connect(function()
        print('船被销毁')
        Knit.GetService('BoatMovementService'):OnBoat(player, false)
    end)
    
    local curBoatConfig = BoatConfig[BOAT_PARTS_FOLDER_NAME]
    local primaryPart = nil
    for _, partInfo in ipairs(boatParts) do
        for _, templatePart in ipairs(boatTemplate:GetChildren()) do
            if templatePart:IsA('MeshPart') and partInfo.Type == templatePart.Name then
                local partClone = templatePart:Clone()
                partClone.CFrame = templatePart.CFrame
                partClone.Parent = boat
                partClone.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Wood)

                if partInfo.Type == curBoatConfig[1].Name then
                    boat.PrimaryPart = partClone
                    primaryPart = boat.PrimaryPart  -- 保存主船体引用
                end

                -- 创建焊接约束
                if primaryPart and partClone ~= primaryPart then
                    local weldConstraint = Instance.new('WeldConstraint')
                    weldConstraint.Part0 = primaryPart
                    weldConstraint.Part1 = partClone
                    weldConstraint.Parent = partClone
                end
                break
            end
        end
    end
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
    weldConstraint.Part0 = driverSeat
    weldConstraint.Part1 = primaryPart
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
local function CreateStabilizer(primaryPart)
    -- 创建或获取稳定用的AlignOrientation和必要的Attachment
    local stabilizer = primaryPart:FindFirstChild("BoatStabilizer")
    local originAttachment = primaryPart:FindFirstChild("OriginAttachment")
    local targetAttachment = primaryPart:FindFirstChild("TargetAttachment")
    -- 如果不存在，创建稳定组件和附件
    if not stabilizer then
        -- 创建源附件（固定在船体上）
        originAttachment = Instance.new("Attachment")
        originAttachment.Name = "OriginAttachment"
        originAttachment.Parent = primaryPart
        
        -- 创建目标附件（表示理想方向）
        targetAttachment = Instance.new("Attachment")
        targetAttachment.Name = "TargetAttachment"
        targetAttachment.Parent = primaryPart
        
        -- 创建AlignOrientation约束
        stabilizer = Instance.new("AlignOrientation")
        stabilizer.Name = "BoatStabilizer"
        stabilizer.MaxTorque = 150000 -- 减少最大扭矩防止过度矫正
        stabilizer.MaxAngularVelocity = 5 
        stabilizer.Responsiveness = 20 -- 提高响应性加速稳定
        stabilizer.RigidityEnabled = false -- 禁用刚性，允许更自然的物理行为
        
        -- 只在X和Z轴上应用稳定（保持Y轴自由旋转）
        stabilizer.PrimaryAxisOnly = false
        stabilizer.AlignType = Enum.AlignType.Parallel
        
        -- 连接附件
        stabilizer.Attachment0 = originAttachment
        stabilizer.Attachment1 = targetAttachment
        stabilizer.Parent = primaryPart
        -- 提取当前的Y轴旋转（船头方向）
        local _, yRot, _ = primaryPart.CFrame:ToEulerAnglesYXZ()
        -- 更新源附件位置（保持在船体中心）
        originAttachment.CFrame = CFrame.new()
        -- 更新目标附件方向（只保留Y轴旋转，X和Z轴归零）
        targetAttachment.CFrame = CFrame.Angles(0, yRot, 0)
    end
end

-- 执行船只组装核心逻辑
-- @param player 发起组装请求的玩家对象
-- @return Model 组装完成的船只模型
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
    CreateMoveVelocity(boat.primaryPart)
    --CreateStabilizer(boat.primaryPart)

    -- 设置船的初始位置
    Interface:InitBoatWaterPos(player.character, boat)
    Knit.GetService('BoatMovementService'):OnBoat(player, true)
    -- 触发客户端事件更新主界面UI
    self.UpdateMainUI:Fire(player, {explore = true})

    return "船组装成功"
end

function BoatAssemblingService.Client:StopBoat(player)
    Knit.GetService('BoatMovementService'):OnBoat(player, false)
    -- 触发客户端事件更新主界面UI
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