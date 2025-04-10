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

-- 执行船只组装核心逻辑
-- @param player 发起组装请求的玩家对象
-- @return Model 组装完成的船只模型
function BoatAssemblingService.Client:AssembleBoat(player)
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..player.UserId)
    if boat then
        return "船已存在"
    end
    -- 确保ServerStorage中存在船舶模板
    local boatTemplate = ServerStorage:FindFirstChild('船')
    -- 校验服务器预置的船只模板是否存在
    if not boatTemplate then
        return 'BoatTemplate not found in ServerStorage!'
    end

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

    -- 克隆模板并定位部件
    -- 创建新模型容器并保持模板原始坐标关系
    -- 使用模板的CFrame保持部件相对位置，确保物理模拟准确性
    boat = Instance.new('Model')
    boat.Name = 'PlayerBoat_'..player.UserId
    boat.Parent = workspace
    
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

    if not primaryPart then
        return "玩家没有可用的船主部件"
    end

    -- 创建驾驶座位
    local primaryCFrame = boat.PrimaryPart.CFrame
    local driverSeat = Instance.new('VehicleSeat')
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

    -- 创建船的移动性
    local boatBodyVelocity = Instance.new("BodyVelocity")
    boatBodyVelocity.Name = "BoatBodyVelocity"
    boatBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    boatBodyVelocity.P = 1250
    boatBodyVelocity.Parent = primaryPart
    boatBodyVelocity.Velocity = Vector3.new(0, 0, 0)

    -- 创建船的旋转性
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.Name = "BoatBodyAngularVelocity"
    bodyAngularVelocity.MaxTorque = Vector3.new(0, 300000, 0)
    bodyAngularVelocity.P = 50000
    bodyAngularVelocity.Parent = primaryPart
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)

    -- 设置船的初始位置
    Interface:InitBoatWaterPos(player.character, boat, driverSeat)
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