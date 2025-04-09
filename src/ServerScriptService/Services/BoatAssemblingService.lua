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
    local boat = Instance.new('Model')
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

    -- 创建驾驶座位
    local primaryCFrame = boat.PrimaryPart.CFrame
    local driverSeat = Instance.new('VehicleSeat')
    driverSeat.Name = 'DriverSeat'
    driverSeat.Parent = boat
    driverSeat.Anchored = false

    local currentCFrame = driverSeat:GetPivot()
    driverSeat.CFrame = CFrame.new(primaryCFrame.X, primaryCFrame.Y, primaryCFrame.Z) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
    
    -- 创建焊接约束
    if primaryPart then
        local weldConstraint = Instance.new('WeldConstraint')
        weldConstraint.Part0 = driverSeat
        weldConstraint.Part1 = primaryPart
        weldConstraint.Parent = driverSeat

        -- local SeatWeld = Instance.new('Weld')
        -- SeatWeld.Part0 = driverSeat
        -- SeatWeld.Part1 = player.Character:WaitForChild("HumanoidRootPart")
        -- SeatWeld.Parent = driverSeat
        -- SeatWeld.Archivable = false
    end

    -- 设置船的初始位置
    Interface:InitBoatWaterPos(player.character, boat, driverSeat)
    Knit.GetService('BoatMovementService').Client.isOnBoat:Fire(player, true)
    -- 触发客户端事件更新主界面UI
    self.UpdateMainUI:Fire(player, {explore = true})

    return "船组装成功"
end

function BoatAssemblingService.Client:StopBoat(player)
    Knit.GetService('BoatMovementService').Client.isOnBoat:Fire(player, false)
    -- 触发客户端事件更新主界面UI
    self.UpdateMainUI:Fire(player, {explore = false})

    Interface:InitPlayerPos(player)

    local playerBoat = workspace:FindFirstChild('PlayerBoat_'..player.UserId)
    if not playerBoat then
        return "船不存在"
    end

    playerBoat:Destroy()
    return "船已停止"
end

function BoatAssemblingService:KnitInit()
    print('BoatAssemblingService initialized')
end

function BoatAssemblingService:KnitStart()
    print('BoatAssemblingService started')
end

return BoatAssemblingService