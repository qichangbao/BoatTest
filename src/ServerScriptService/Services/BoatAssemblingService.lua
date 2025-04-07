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

    -- -- 触发客户端事件传递座位引用
    -- controlEvent:FireClient(player, 'SetDriverSeat')
    
    -- -- 添加座位占用监听
    -- -- 监听玩家入座事件
    -- driverSeat:GetPropertyChangedSignal('Occupant'):Connect(function()
    --     local humanoid = driverSeat.Occupant
    --     if humanoid then
    --         -- 监听玩家离座事件
    --         humanoid.Seated:Connect(function(isSeated)
    --             if not isSeated then
    --                 controlEvent:FireClient(player, 'ClearDriverSeat')
    --             end
    --         end)
    --     end
    -- end)

    -- 创建双层防渗透碰撞体
    local function createWaterproofCollider(offsetY, sizeMultiplier)
        local collider = Instance.new('Part')
        collider.Size = boat.PrimaryPart.Size * sizeMultiplier
        collider.Transparency = 0.5
        collider.Color = Color3.new(0, 0.5, 1)
        collider.CanCollide = true
        collider.Anchored = false
        collider.Parent = boat
        collider.CFrame = boat.PrimaryPart.CFrame * CFrame.new(0, offsetY, 0)
        
        -- 添加船体焊接约束
        if primaryPart and collider then
            local weldConstraint = Instance.new('WeldConstraint')
            weldConstraint.Part0 = primaryPart
            weldConstraint.Part1 = collider
            weldConstraint.Parent = collider
        end

        -- game:GetService("RunService").Heartbeat:Connect(function()
        --     if not boat or not collider then
        --         return
        --     end
            
        -- --     local waterSpawn = workspace:WaitForChild('WaterSpawnLocation')
        -- --     local newPosition = Vector3.new(position.X, waterSpawn.Position.Y + boat.PrimaryPart.size.y, position.Z)
        -- --     local newCFrame = CFrame.new(newPosition) * CFrame.Angles(boatInitPivot:ToEulerAnglesXYZ())
        -- --     boat:PivotTo(newCFrame)
        --     local waterSpawn = workspace:WaitForChild('WaterSpawnLocation')
        --     local newCFrame = collider.CFrame
        --     collider.CFrame = CFrame.new(Vector3.new(newCFrame.Position.X, waterSpawn.Position.Y, newCFrame.Position.Z))
        -- end)
        
        return collider
    end

    -- 创建底部防渗水
    --createWaterproofCollider(-5, Vector3.new(1.1, 1.1, 1.1))

    -- 设置船的初始位置
    Interface:InitBoatWaterPos(player.character, boat, driverSeat)
    local boatInitPivot = boat:GetPivot()
    
    local function addBuoyancyConstraint(part)
        -- local buoyancy = Instance.new("BodyForce")
        -- buoyancy.Name = "BuoyancyForce"
        
        -- -- 假设水面高度��
        -- local waterLevel = 0
        
        -- -- 设置浮力常�
        -- local buoyancyForce = part.AssemblyMass * workspace.Gravity
        
        -- 连接到心��
        game:GetService("RunService").Heartbeat:Connect(function()
            if not boat or not boat.PrimaryPart then
                return
            end
            -- 获取
            --local position = part.Position
            
            -- 计算有�
            -- local submergedRatio = math.clamp((waterLevel - (position.Y - part.Size.Y/2)) / part.Size.Y, 0, 1)
            
            -- -- 如果部件
            -- if submergedRatio > 0 then
            --     buoyancy.Force = Vector3.new(0, buoyancyForce * submergedRatio * 1.5, 0)
            -- else
            --     buoyancy.Force = Vector3.new(0, 0, 0)
            -- end
            -- print(buoyancy.Force)
            local waterSpawn = workspace:WaitForChild('WaterSpawnLocation')
            local newPosition = Vector3.new(boat:GetPivot().Position.X, waterSpawn.Position.Y + boat.PrimaryPart.size.y, boat:GetPivot().Position.Z)
            local newCFrame = CFrame.new(newPosition) * CFrame.Angles(boatInitPivot:ToEulerAnglesXYZ())
            boat:PivotTo(newCFrame)
            -- local newCFrame = boat.PrimaryPart.CFrame
            -- boat.PrimaryPart.CFrame = CFrame.new(Vector3.new(newCFrame.Position.X, waterSpawn.Position.Y, newCFrame.Position.Z))
        end)
        
        --buoyancy.Parent = part
        return buoyancy
    end
    --addBuoyancyConstraint(primaryPart)
    
    -- local buoyancy = Instance.new('BodyForce')
    -- buoyancy.Name = 'BuoyancyForce'
    -- buoyancy.Force = Vector3.new(0, primaryPart.Mass * 9.81, 0)
    -- buoyancy.Parent = primaryPart

    -- local buoyancy1 = Instance.new('BodyForce')
    -- buoyancy1.Name = 'BuoyancyForce'
    -- buoyancy1.Force = Vector3.new(0, driverSeat.Mass * 9.81, 0)
    -- buoyancy1.Parent = driverSeat
    
    -- 应用动态浮力计算
    --BuoyantController.applyBuoyancy(primaryPart, boat)

    -- 触发客户端事件更新主界面UI
    self.UpdateMainUI:Fire(player, {explore = true})

    return "船组装成功"
end

function BoatAssemblingService.Client:StopBoat(player)
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

    -- self.Client.AssembleBoat = function(player)
    --     return self:AssembleBoat(player)
    -- end
    
    -- self.Client.StopBoat = function(player)
    --     return self:StopBoat(player)
    -- end
end

function BoatAssemblingService:KnitStart()
    print('BoatAssemblingService started')
end

return BoatAssemblingService