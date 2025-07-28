local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))

local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BoatConfig'))
local ItemConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('ItemConfig'))
local BadgeConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('BadgeConfig'))

local BoatAssemblingService = Knit.CreateService({
    Name = 'BoatAssemblingService',
    Client = {
        UpdateMainUI = Knit.CreateSignal(),
        UpdateInventory = Knit.CreateSignal(),
        DestroyBoat = Knit.CreateSignal(),
    },
})

function BoatAssemblingService:CreateBoat(player, boatName)
    if not player or not player.Character or not player.Character.Humanoid then
        return
    end

    local InventoryService = Knit.GetService("InventoryService")
    -- 获取玩家库存中的船部件
    local inventory = InventoryService:Inventory(player, 'GetInventory')
    -- 检查库存有效性并收集船部件
    local boatParts = {}
    for itemName, itemData in pairs(inventory) do
        if itemData.itemType == ItemConfig.BoatTag then
            if itemData.modelName == boatName then
                table.insert(boatParts, {
                    Name = itemName,
                })
            end
        end
    end

    -- 确保ServerStorage中存在船舶模板
    local boatTemplate = ServerStorage:FindFirstChild(boatName)
    -- 校验服务器预置的船只模板是否存在
    if not boatTemplate then
        return
    end

    local curBoatConfig = BoatConfig.GetBoatConfig(boatName)
    local primaryPartName = ''
    for name, data in pairs(curBoatConfig) do
        if data.PartType == 'PrimaryPart' then
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
    
    -- 设置船只主部件的物理属性（超低密度确保船只浮在水面）
    primaryPart.CustomPhysicalProperties = PhysicalProperties.new(
        0.2,   -- 密度（超低密度，确保船只强力浮在水面）
        0.5,   -- 摩擦力
        0.1,   -- 弹性
        1,     -- 弹性权重
        1      -- 摩擦权重
    )

    -- 监听船的销毁事件
    boat.Destroying:Connect(function()
        print('船被销毁')
        if not player or not player.Character or not player.Character.Humanoid then
            return
        end
        
        -- 停止追踪玩家航行距离（全服排行榜）
        Knit.GetService('RankService'):StopTrackingPlayer(player)
        
        -- 移除主船体关联
        self.Client.UpdateMainUI:Fire(player, {explore = false})
        Knit.GetService('BoatWeaponService'):Active(player, false)
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

    -- 创建座位
    local templateSeatPart = boatTemplate:FindFirstChild("VehicleSeat")
    local offsetCFrame = templatePrimaryPart.CFrame:ToObjectSpace(templateSeatPart.CFrame)
    local seatPart = templateSeatPart:Clone()
    seatPart.CFrame = primaryPart.CFrame * offsetCFrame
    seatPart.Parent = boat
    seatPart.Anchored = false
    
    -- 设置座位权限，仅允许创建者坐下
    seatPart:GetPropertyChangedSignal('Occupant'):Connect(function()
        local occupant = seatPart.Occupant
        if occupant and occupant.Parent then
            local humanoid = occupant.Parent:FindFirstChildOfClass('Humanoid')
            if humanoid and humanoid.Parent:IsA('Model') then
                local playerTest = game.Players:GetPlayerFromCharacter(humanoid.Parent)
                if playerTest then
                    local start = string.find(boat.Name, tostring(playerTest.UserId))
                    if not start then
                        seatPart.Disabled = false
                        task.wait(0.1)
                        seatPart.Disabled = true
                        humanoid.Jump = true
                        return
                    end
                end
            end
        end
    end)

    -- 创建焊接约束
    local function createWeldConstraint(parent, part0, part1)
        local weldConstraint = Instance.new('WeldConstraint')
        weldConstraint.Part0 = part0
        weldConstraint.Part1 = part1
        weldConstraint.Parent = parent
    end

    createWeldConstraint(seatPart, primaryPart, seatPart)

    local hasWeapon = false
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

                createWeldConstraint(partClone, primaryPart, partClone)

                if curBoatConfig[partInfo.Name] and curBoatConfig[partInfo.Name].PartType == "WeaponPart" then
                    hasWeapon = true
                end
            end
        end
    end

    boat:SetAttribute('Health', math.max(boatHP, 0))
    boat:SetAttribute('MaxHealth', math.max(boatHP, 0))
    boat:SetAttribute('Speed', math.max(boatSpeed, 0))
    boat:SetAttribute('MaxSpeed', math.max(boatSpeed, 0))
    
    -- 是否激活船炮
    Knit.GetService("BoatWeaponService"):Active(player, hasWeapon)
    return boat
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

-- -- 创建船的稳定器
-- -- @param boat Model 船只模型
-- function BoatAssemblingService:CreateStabilizer(boat)
--     if not boat or not boat.PrimaryPart then
--         warn("CreateStabilizer: 船只或PrimaryPart不存在")
--         return
--     end
    
--     -- 获取船只的尺寸信息
--     local boatSize = boat.PrimaryPart.Size
--     local boatPosition = boat.PrimaryPart.Position
    
--     -- 根据船只重量计算稳定器浮力需求（船重量的一半）
--     local targetBuoyancy = boat.PrimaryPart.AssemblyMass * 0.3
    
--     -- 水的密度约为1（Roblox单位），稳定器需要的总体积来产生目标浮力
--     -- 4个稳定器平均分担浮力
--     local requiredVolumePerStabilizer = targetBuoyancy / 4
    
--     -- 根据船只大小计算稳定器参数
--     local stabilizerConfig = {
--         -- 左右稳定器配置
--         side = {
--             width = math.max(boatSize.X * 0.3, 1), -- 宽度为船宽的30%，最小1
--             length = math.max(boatSize.Z * 0.8, 3), -- 长度为船长的80%，最小3
--             offset = 0 -- 距离船体的偏移量
--         },
--         -- 前后稳定器配置
--         frontBack = {
--             width = math.max(boatSize.X * 2, 3), -- 宽度为船宽的200%，最小3
--             length = math.max(boatSize.Z * 0.3, 1), -- 长度为船长的30%，最小1
--             offset = 0 -- 距离船体的偏移量
--         }
--     }
    
--     -- 计算左右稳定器高度（基于所需体积）
--     local sideStabilizerArea = stabilizerConfig.side.width * stabilizerConfig.side.length
--     local sideStabilizerHeight = math.max(requiredVolumePerStabilizer / sideStabilizerArea, 0.5)
--     stabilizerConfig.side.height = sideStabilizerHeight
    
--     -- 计算前后稳定器高度（基于所需体积）
--     local frontBackStabilizerArea = stabilizerConfig.frontBack.width * stabilizerConfig.frontBack.length
--     local frontBackStabilizerHeight = math.max(requiredVolumePerStabilizer / frontBackStabilizerArea, 0.5)
--     stabilizerConfig.frontBack.height = frontBackStabilizerHeight
    
--     -- 创建稳定器Part的通用函数
--     -- @param name string 稳定器名称
--     -- @param size Vector3 稳定器大小
--     -- @param position Vector3 稳定器位置
--     local function createStabilizerPart(name, size, position)
--         local part = Instance.new("Part")
--         part.Name = name
--         part.Size = size
--         part.Material = Enum.Material.Wood
--         part.Anchored = false
--         part.CanCollide = true
--         part.Transparency = 1
--         part.Position = position
--         part.Parent = boat
        
--         -- 创建焊接约束连接到船体
--         local weldConstraint = Instance.new('WeldConstraint')
--         weldConstraint.Part0 = boat.PrimaryPart
--         weldConstraint.Part1 = part
--         weldConstraint.Parent = part
        
--         -- 设置碰撞组
--         part.CollisionGroup = "BoatStabilizerCollisionGroup"
        
--         return part
--     end
    
--     -- 计算稳定器的Y位置（船底下方）
--     local stabilizerY = boatPosition.Y - boatSize.Y / 2 - stabilizerConfig.side.height / 2
    
--     -- 创建左侧稳定器
--     local leftSize = Vector3.new(
--         stabilizerConfig.side.width,
--         stabilizerConfig.side.height,
--         stabilizerConfig.side.length
--     )
--     local leftPosition = Vector3.new(
--         boatPosition.X - boatSize.X / 2 - stabilizerConfig.side.offset,
--         stabilizerY,
--         boatPosition.Z
--     )
--     createStabilizerPart("BoatStabilizerLeft", leftSize, leftPosition)
    
--     -- 创建右侧稳定器
--     local rightSize = Vector3.new(
--         stabilizerConfig.side.width,
--         stabilizerConfig.side.height,
--         stabilizerConfig.side.length
--     )
--     local rightPosition = Vector3.new(
--         boatPosition.X + boatSize.X / 2 + stabilizerConfig.side.offset,
--         stabilizerY,
--         boatPosition.Z
--     )
--     createStabilizerPart("BoatStabilizerRight", rightSize, rightPosition)
    
--     -- 创建前方稳定器
--     local frontSize = Vector3.new(
--         stabilizerConfig.frontBack.width,
--         stabilizerConfig.frontBack.height,
--         stabilizerConfig.frontBack.length
--     )
--     local frontPosition = Vector3.new(
--         boatPosition.X,
--         stabilizerY,
--         boatPosition.Z - boatSize.Z / 2 - stabilizerConfig.frontBack.offset
--     )
--     createStabilizerPart("BoatStabilizerFront", frontSize, frontPosition)
    
--     -- 创建后方稳定器
--     local backSize = Vector3.new(
--         stabilizerConfig.frontBack.width,
--         stabilizerConfig.frontBack.height,
--         stabilizerConfig.frontBack.length
--     )
--     local backPosition = Vector3.new(
--         boatPosition.X,
--         stabilizerY,
--         boatPosition.Z + boatSize.Z / 2 + stabilizerConfig.frontBack.offset
--     )
--     createStabilizerPart("BoatStabilizerBack", backSize, backPosition)
    
--     print(string.format("为船只创建了4个稳定器，船只尺寸: %.1fx%.1fx%.1f，稳定器高度: 左右%.2f 前后%.2f", 
--         boatSize.X, boatSize.Y, boatSize.Z, sideStabilizerHeight, frontBackStabilizerHeight))
-- end

function BoatAssemblingService.Client:AssembleBoat(player, boatName, revivePos)
    return self.Server:AssembleBoat(player, boatName, revivePos)
end



-- -- 创建船的稳定器
-- -- @param boat Model 船只模型
-- function BoatAssemblingService:CreateStabilizer(boat)
--     if not boat or not boat.PrimaryPart then
--         warn("CreateStabilizer: 船只或PrimaryPart不存在")
--         return
--     end
    
--     -- 获取船只的尺寸信息
--     local boatSize = boat.PrimaryPart.Size
--     local boatPosition = boat.PrimaryPart.Position
    
--     -- 根据船只重量计算稳定器浮力需求（船重量的一半）
--     local targetBuoyancy = boat.PrimaryPart.AssemblyMass * 0.3
    
--     -- 水的密度约为1（Roblox单位），稳定器需要的总体积来产生目标浮力
--     -- 4个稳定器平均分担浮力
--     local requiredVolumePerStabilizer = targetBuoyancy / 4
    
--     -- 根据船只大小计算稳定器参数
--     local stabilizerConfig = {
--         -- 左右稳定器配置
--         side = {
--             width = math.max(boatSize.X * 0.3, 1), -- 宽度为船宽的30%，最小1
--             length = math.max(boatSize.Z * 0.8, 3), -- 长度为船长的80%，最小3
--             offset = 0 -- 距离船体的偏移量
--         },
--         -- 前后稳定器配置
--         frontBack = {
--             width = math.max(boatSize.X * 2, 3), -- 宽度为船宽的200%，最小3
--             length = math.max(boatSize.Z * 0.3, 1), -- 长度为船长的30%，最小1
--             offset = 0 -- 距离船体的偏移量
--         }
--     }
    
--     -- 计算左右稳定器高度（基于所需体积）
--     local sideStabilizerArea = stabilizerConfig.side.width * stabilizerConfig.side.length
--     local sideStabilizerHeight = math.max(requiredVolumePerStabilizer / sideStabilizerArea, 0.5)
--     stabilizerConfig.side.height = sideStabilizerHeight
    
--     -- 计算前后稳定器高度（基于所需体积）
--     local frontBackStabilizerArea = stabilizerConfig.frontBack.width * stabilizerConfig.frontBack.length
--     local frontBackStabilizerHeight = math.max(requiredVolumePerStabilizer / frontBackStabilizerArea, 0.5)
--     stabilizerConfig.frontBack.height = frontBackStabilizerHeight
    
--     -- 创建稳定器Part的通用函数
--     -- @param name string 稳定器名称
--     -- @param size Vector3 稳定器大小
--     -- @param position Vector3 稳定器位置
--     local function createStabilizerPart(name, size, position)
--         local part = Instance.new("Part")
--         part.Name = name
--         part.Size = size
--         part.Material = Enum.Material.Wood
--         part.Anchored = false
--         part.CanCollide = true
--         part.Transparency = 1
--         part.Position = position
--         part.Parent = boat
        
--         -- 创建弹簧约束连接到船只
--         local springConstraint = Instance.new("SpringConstraint")
        
--         -- 在船只和稳定器上创建Attachment
--         local boatAttachment = Instance.new("Attachment")
--         boatAttachment.Name = name .. "_BoatAttachment"
--         boatAttachment.Position = Vector3.new(position.X, -boatSize.Y/2, position.Z)
--         boatAttachment.Parent = boat.PrimaryPart
        
--         local stabilizerAttachment = Instance.new("Attachment")
--         stabilizerAttachment.Name = name .. "_StabilizerAttachment"
--         stabilizerAttachment.Position = Vector3.new(0, size.Y/2, 0)
--         stabilizerAttachment.Parent = part
        
--         -- 配置弹簧约束
--         springConstraint.Attachment0 = boatAttachment
--         springConstraint.Attachment1 = stabilizerAttachment
--         springConstraint.FreeLength = 3 -- 弹簧自然长度（增加）
--         springConstraint.Stiffness = 100 -- 弹簧刚度（进一步降低）
--         springConstraint.Damping = 30 -- 阻尼，防止震荡（进一步降低）
--         springConstraint.Parent = part
        
--         -- 设置碰撞组
--         part.CollisionGroup = "BoatStabilizerCollisionGroup"
        
--         return part
--     end
    
--     -- 计算稳定器的Y位置（船底下方）
--     local stabilizerY = boatPosition.Y - boatSize.Y / 2 - stabilizerConfig.side.height / 2
    
--     -- 创建左侧稳定器
--     local leftSize = Vector3.new(
--         stabilizerConfig.side.width,
--         stabilizerConfig.side.height,
--         stabilizerConfig.side.length
--     )
--     local leftPosition = Vector3.new(
--         boatPosition.X - boatSize.X / 2 - stabilizerConfig.side.offset,
--         stabilizerY,
--         boatPosition.Z
--     )
--     createStabilizerPart("BoatStabilizerLeft", leftSize, leftPosition)
    
--     -- 创建右侧稳定器
--     local rightSize = Vector3.new(
--         stabilizerConfig.side.width,
--         stabilizerConfig.side.height,
--         stabilizerConfig.side.length
--     )
--     local rightPosition = Vector3.new(
--         boatPosition.X + boatSize.X / 2 + stabilizerConfig.side.offset,
--         stabilizerY,
--         boatPosition.Z
--     )
--     createStabilizerPart("BoatStabilizerRight", rightSize, rightPosition)
    
--     -- 创建前方稳定器
--     local frontSize = Vector3.new(
--         stabilizerConfig.frontBack.width,
--         stabilizerConfig.frontBack.height,
--         stabilizerConfig.frontBack.length
--     )
--     local frontPosition = Vector3.new(
--         boatPosition.X,
--         stabilizerY,
--         boatPosition.Z - boatSize.Z / 2 - stabilizerConfig.frontBack.offset
--     )
--     createStabilizerPart("BoatStabilizerFront", frontSize, frontPosition)
    
--     -- 创建后方稳定器
--     local backSize = Vector3.new(
--         stabilizerConfig.frontBack.width,
--         stabilizerConfig.frontBack.height,
--         stabilizerConfig.frontBack.length
--     )
--     local backPosition = Vector3.new(
--         boatPosition.X,
--         stabilizerY,
--         boatPosition.Z + boatSize.Z / 2 + stabilizerConfig.frontBack.offset
--     )
--     createStabilizerPart("BoatStabilizerBack", backSize, backPosition)
    
--     print(string.format("为船只创建了4个稳定器，船只尺寸: %.1fx%.1fx%.1f，稳定器高度: 左右%.2f 前后%.2f", 
--         boatSize.X, boatSize.Y, boatSize.Z, sideStabilizerHeight, frontBackStabilizerHeight))
-- end

-- 创建船的水下浮力稳定器（使用水下Part+约束）
-- @param boat Model 船只模型
function BoatAssemblingService:CreateStabilizer(boat)
    if not boat or not boat.PrimaryPart then
        warn("CreateStabilizer: 船只或PrimaryPart不存在")
        return
    end
    
    local primaryPart = boat.PrimaryPart
    
    -- 清理旧的稳定器组件
    for _, child in pairs(boat:GetChildren()) do
        if child.Name:find("BoatStabilizer") then
            child:Destroy()
        end
    end
    
    -- 根据船只大小计算稳定器参数
    local boatSize = primaryPart.Size
    local boatPosition = primaryPart.Position
    
    -- 创建水下浮力块
    local function createUnderwaterStabilizer(name, size, offset)
        local stabilizer = Instance.new("Part")
        stabilizer.Name = name
        stabilizer.Size = size
        stabilizer.Material = Enum.Material.ForceField
        stabilizer.Transparency = 0.8
        stabilizer.CanCollide = false
        stabilizer.Anchored = false
        stabilizer.BrickColor = BrickColor.new("Bright blue")
        
        -- 设置浮力属性（适度密度让稳定器沉入水中）
        stabilizer.CustomPhysicalProperties = PhysicalProperties.new(
            0.5,    -- 略低于水的密度，减少下拉力
            0.5,    -- 适中的摩擦
            0.1,    -- 低弹性
            1,      -- 摩擦重量
            1       -- 弹性重量
        )
        
        -- 位置设置在船只下方水中
        stabilizer.CFrame = primaryPart.CFrame + offset
        stabilizer.Parent = boat
        
        -- 创建弹簧约束连接到船只
        local springConstraint = Instance.new("SpringConstraint")
        
        -- 在船只和稳定器上创建Attachment
        local boatAttachment = Instance.new("Attachment")
        boatAttachment.Name = name .. "_BoatAttachment"
        boatAttachment.Position = Vector3.new(offset.X, -boatSize.Y/2, offset.Z)
        boatAttachment.Parent = primaryPart
        
        local stabilizerAttachment = Instance.new("Attachment")
        stabilizerAttachment.Name = name .. "_StabilizerAttachment"
        stabilizerAttachment.Position = Vector3.new(0, size.Y/2, 0)
        stabilizerAttachment.Parent = stabilizer
        
        -- 配置弹簧约束
        springConstraint.Attachment0 = boatAttachment
        springConstraint.Attachment1 = stabilizerAttachment
        springConstraint.FreeLength = 3 -- 弹簧自然长度（增加）
        springConstraint.Stiffness = 100 -- 弹簧刚度（进一步降低）
        springConstraint.Damping = 30 -- 阻尼，防止震荡（进一步降低）
        springConstraint.Parent = stabilizer
        
        return stabilizer
    end
    
    -- 创建适度尺寸的稳定器系统
    local mainStabilizerSize = Vector3.new(boatSize.X * 0.4, 2, boatSize.Z * 0.4)
    
    -- 主稳定器（船只正下方，适度尺寸）
    createUnderwaterStabilizer(
        "BoatStabilizerMain",
        mainStabilizerSize,
        Vector3.new(0, -boatSize.Y/2 - 1.5, 0)
    )
    
    -- 船尾稳定器（适度浮力，防止下沉）
    local sternStabilizerSize = Vector3.new(boatSize.X * 0.3, 1.5, boatSize.Z * 0.3)
    createUnderwaterStabilizer(
        "BoatStabilizerStern",
        sternStabilizerSize,
        Vector3.new(0, -boatSize.Y/2 - 1.2, -boatSize.Z/2 - 0.5)
    )
    
    -- 船头稳定器（适度浮力，保持平衡）
    local bowStabilizerSize = Vector3.new(boatSize.X * 0.3, 1.5, boatSize.Z * 0.3)
    createUnderwaterStabilizer(
        "BoatStabilizerBow",
        bowStabilizerSize,
        Vector3.new(0, -boatSize.Y/2 - 1.2, boatSize.Z/2 + 0.5)
    )
    
    print(string.format("为船只创建了水下浮力稳定器系统，船只尺寸: %.1fx%.1fx%.1f", 
        boatSize.X, boatSize.Y, boatSize.Z))
end

function BoatAssemblingService:AssembleBoat(player, boatName, revivePos)
    player:SetAttribute("BoatName", boatName)
    local boat = game.Workspace:FindFirstChild("PlayerBoat_"..player.UserId)
    if boat then
        return 10020
    end

    boat = self:CreateBoat(player, boatName)
    if not boat or not boat.primaryPart then
        return 10021
    end

    self:CreateStabilizer(boat)
    self:CreateMoveVelocity(boat.primaryPart)

    -- 设置船的初始位置
    Interface.InitBoatWaterPos(player, boat, revivePos)
    Knit.GetService('BoatWeaponService'):Active(player, true)
    Knit.GetService('BoatMovementService'):OnBoat(player, true)
    Knit.GetService('InventoryService'):BoatAssemblySuccess(player, boat:GetAttribute('ModelName'))
    
    -- 开始追踪玩家航行距离（全服排行榜）
    Knit.GetService('RankService'):StartTrackingPlayer(player, revivePos ~= nil)
    
    -- 触发客户端事件更新主界面UI
    self.Client.UpdateMainUI:Fire(player, {explore = true})
    self.Client.UpdateInventory:Fire(player, boat:GetAttribute('ModelName'))

    Interface.AwardBadge(player.UserId, BadgeConfig["FirstVoyage"].id)
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
        if data.PartType == 'PrimaryPart' then
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
    local modelName = boat:GetAttribute('ModelName')
    local curBoatConfig = BoatConfig.GetBoatConfig(modelName)
    local boatHP = boat:GetAttribute('Health')
    local boatMaxHP = boat:GetAttribute('MaxHealth')
    local boatSpeed = boat:GetAttribute('Speed')
    local boatMaxSpeed = boat:GetAttribute('MaxSpeed')
    local InventoryService = Knit.GetService("InventoryService")
    local unusedParts = InventoryService:GetUnusedParts(player, modelName)
    for itemName, _ in pairs(unusedParts) do
        self:AttachPartToBoat(boat, itemName)
        boatHP += curBoatConfig[itemName].HP
        boatMaxHP += curBoatConfig[itemName].HP
        boatSpeed += curBoatConfig[itemName].speed
        boatMaxSpeed += curBoatConfig[itemName].speed
    end
    boat:SetAttribute('Health', math.max(boatHP, 0))
    boat:SetAttribute('MaxHealth', math.max(boatMaxHP, 0))
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
    Knit.GetService('BoatWeaponService'):Active(player, false)
    Knit.GetService('BoatMovementService'):OnBoat(player, false)
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
            local start = landName:find("_")
            if start then
                landName = landName:sub(1, start - 1)
            end
            Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 'info', 10049, landName)
        end
        print("船不存在")
        return
    end

    playerBoat:Destroy()
    print("船已销毁")
    task.wait(0.1)
    local landName = Interface.InitPlayerPos(player)
    if landName then
        local start = landName:find("_")
        if start then
            landName = landName:sub(1, start - 1)
        end
        Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 'info', 10049, landName)
    end
end

function BoatAssemblingService.Client:StopBoat(player)
    self.Server:StopBoat(player)
end

function BoatAssemblingService:KnitInit()
end

function BoatAssemblingService:KnitStart()
end

return BoatAssemblingService
