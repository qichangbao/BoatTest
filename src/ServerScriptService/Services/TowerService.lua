print('TowerService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

local TowerService = Knit.CreateService({
    Name = 'TowerService',
    Client = {
        TowerDestroyed = Knit.CreateSignal(),
        TowerDamaged = Knit.CreateSignal(),
    },
})

-- 存储所有活跃的箭塔
local _activeTowers = {}
-- 存储箭塔的攻击连接
local _towerConnections = {}

-- 提供外部访问_activeTowers的接口
TowerService._activeTowers = _activeTowers

-- 初始化箭塔
function TowerService:InitializeTower(towerModel, islandName, towerIndex, towerType)
    if not towerModel or not islandName or not towerIndex or not towerType then
        warn("TowerService:InitializeTower - 参数不完整")
        return
    end
    
    local towerConfig = TowerConfig[towerType]
    if not towerConfig then
        warn("TowerService:InitializeTower - 未找到箭塔配置:", towerType)
        return
    end
    
    -- 设置箭塔的初始生命值
    local humanoid = towerModel:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.MaxHealth = towerConfig.Health or 100
        humanoid.Health = towerConfig.Health or 100
    end
    
    -- 创建箭塔数据
    local towerData = {
        model = towerModel,
        islandName = islandName,
        towerIndex = towerIndex,
        towerType = towerType,
        config = towerConfig,
        lastAttackTime = 0,
        isOccupied = false, -- 是否被占领
        occupierUserId = nil, -- 记录占领者的UserId
        attackConnection = nil
    }
    
    -- 存储箭塔数据
    local towerKey = islandName .. "_" .. towerIndex
    _activeTowers[towerKey] = towerData
    
    -- 监听生命值变化
    if humanoid then
        local healthConnection = humanoid.HealthChanged:Connect(function(health)
            self:OnTowerHealthChanged(towerKey, health)
        end)
        
        local diedConnection = humanoid.Died:Connect(function()
            self:OnTowerDestroyed(towerKey)
        end)
        
        _towerConnections[towerKey] = {
            health = healthConnection,
            died = diedConnection
        }
    end
    
    print("箭塔初始化完成:", towerKey, "类型:", towerType)
end

-- 设置岛屿箭塔占领状态
-- @param islandName 岛屿名称
-- @param isOccupied 是否被占领
-- @param occupierUserId 占领者用户ID
function TowerService:SetTowerOccupied(islandName, isOccupied, occupierUserId)
    -- 遍历该岛屿上的所有箭塔
    for towerKey, towerData in pairs(_activeTowers) do
        if towerData.islandName == islandName then
            towerData.isOccupied = isOccupied
            towerData.occupierUserId = isOccupied and occupierUserId or nil
            
            if isOccupied then
                -- 开始攻击
                self:StartTowerAttack(towerKey)
                print("箭塔被占领，开始攻击占领者的船只:", islandName, towerData.towerIndex, occupierUserId)
            else
                -- 停止攻击并恢复满血
                self:StopTowerAttack(towerKey)
                towerData.health = towerData.config.Health
                self:UpdateTowerHealthInDatabase(islandName, towerData.towerIndex, towerData.health)
                print("箭塔占领状态取消，血量恢复满血:", islandName, towerData.towerIndex)
            end
        end
    end
end

-- 开始箭塔攻击
function TowerService:StartTowerAttack(towerKey)
    local towerData = _activeTowers[towerKey]
    if not towerData or towerData.attackConnection then
        return
    end
    
    -- 创建攻击循环
    towerData.attackConnection = RunService.Heartbeat:Connect(function()
        if towerData.isOccupied then
            self:TowerAttackTick(towerKey)
        end
    end)
end

-- 停止箭塔攻击
function TowerService:StopTowerAttack(towerKey)
    local towerData = _activeTowers[towerKey]
    if not towerData then
        return
    end
    
    if towerData.attackConnection then
        towerData.attackConnection:Disconnect()
        towerData.attackConnection = nil
    end
    
    towerData.targetBoat = nil
end

-- 箭塔攻击逻辑
function TowerService:TowerAttackTick(towerKey)
    local towerData = _activeTowers[towerKey]
    if not towerData or not towerData.isOccupied or not towerData.occupierUserId then
        return
    end
    
    -- 检查占领者船只是否在100距离内
    local occupierBoat = workspace:FindFirstChild("PlayerBoat_" .. towerData.occupierUserId)
    if occupierBoat and occupierBoat.PrimaryPart then
        local distance = (occupierBoat.PrimaryPart.Position - towerData.model.PrimaryPart.Position).Magnitude
        if distance > 100 then
            -- 占领者船只超出100距离，取消占领状态
            self:SetTowerOccupied(towerData.islandName, false, nil)
            return
        end
    else
        -- 占领者船只不存在，取消占领状态
        self:SetTowerOccupied(towerData.islandName, false, nil)
        return
    end
    
    local currentTime = tick()
    local attackCooldown = 1 / (towerData.config.AttackSpeed or 1) -- 攻击间隔
    
    -- 检查攻击冷却
    if currentTime - towerData.lastAttackTime < attackCooldown then
        return
    end
    
    -- 寻找占领者的船只作为目标
    local targetBoat = self:FindOccupierBoat(towerData.model.PrimaryPart.Position, towerData.config.AttackRange or 50, towerData.occupierUserId)
    
    if targetBoat then
        -- 执行攻击
        self:ExecuteTowerAttack(towerData, targetBoat)
        towerData.lastAttackTime = currentTime
        
        print("箭塔攻击占领者船只:", towerData.occupierUserId)
    end
end

-- 寻找占领者的船只
function TowerService:FindOccupierBoat(towerPosition, attackRange, occupierUserId)
    local occupierBoat = workspace:FindFirstChild("PlayerBoat_" .. occupierUserId)
    
    if occupierBoat and occupierBoat.PrimaryPart then
        local distance = (occupierBoat.PrimaryPart.Position - towerPosition).Magnitude
        if distance <= attackRange then
            return occupierBoat
        end
    end
    
    return nil
end

-- 执行箭塔攻击
-- @param towerData 箭塔数据
-- @param targetBoat 目标船只
function TowerService:ExecuteTowerAttack(towerData, targetBoat)
    if not targetBoat or not targetBoat.PrimaryPart then
        return
    end
    
    -- 发射箭矢
    self:FireArrow(towerData, targetBoat)
end

-- 发射箭矢
-- @param towerData 箭塔数据
-- @param targetBoat 目标船只
function TowerService:FireArrow(towerData, targetBoat)
    if not towerData.model or not towerData.model.PrimaryPart or not targetBoat.PrimaryPart then
        return
    end
    
    local startPos = towerData.model.PrimaryPart.Position + Vector3.new(0, 15, 0)
    local endPos = targetBoat.PrimaryPart.Position
    
    -- 克隆箭矢模型
    local arrowTemplate = ServerStorage:WaitForChild(towerData.config.ArrowName)
    local arrow = arrowTemplate:Clone()
    arrow.Name = "Arrow_" .. tick()
    arrow.Parent = workspace
    
    -- 使用 PivotTo 设置箭矢位置和朝向
    local direction = (endPos - startPos).Unit
    local lookAtCFrame = CFrame.lookAt(startPos, endPos)
    arrow:PivotTo(lookAtCFrame)
    
    -- 设置箭矢属性
    if arrow.PrimaryPart then
        arrow.PrimaryPart.Anchored = false
        arrow.PrimaryPart.CanCollide = true
        
        -- 添加 BodyVelocity 让箭矢飞向目标
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Velocity = direction * 3 -- 箭矢飞行速度
        bodyVelocity.Parent = arrow.PrimaryPart
        
        -- 添加碰撞检测
        local connection
        connection = arrow.PrimaryPart.Touched:Connect(function(hit)
            local hitModel = hit.Parent
            
            -- 检查是否碰撞到目标船只
            if hitModel == targetBoat then
                connection:Disconnect()
                
                -- 对船只造成伤害
                self:AttackBoat(targetBoat, towerData.config.Damage or 10)
                
                -- 销毁箭矢
                --arrow:Destroy()
            elseif hit.Name == "Terrain" or hit.Parent.Name == "Terrain" then
                -- 碰撞到地形，销毁箭矢
                connection:Disconnect()
                --arrow:Destroy()
            end
        end)
        
        -- 1秒后自动销毁箭矢（防止箭矢永远存在）
        --Debris:AddItem(arrow, 1)
    end
end

-- 箭矢攻击船只
-- @param targetBoat 目标船只
-- @param damage 伤害值
function TowerService:AttackBoat(targetBoat, damage)
    if not targetBoat then
        return
    end
    
    -- 对船只造成伤害
    local currentHealth = targetBoat:GetAttribute("Health") or 0
    local newHealth = math.max(0, currentHealth - damage)
    targetBoat:SetAttribute("Health", newHealth)
    
    print("箭矢击中船只，造成", damage, "点伤害，船只剩余生命值:", newHealth)
    
    -- 如果船只生命值为0，可以在这里添加船只被摧毁的逻辑
    if newHealth <= 0 then
        print("船只被摧毁!")
        -- 这里可以添加船只被摧毁的特效和奖励逻辑
    end
end

-- 箭塔生命值变化处理
function TowerService:OnTowerHealthChanged(towerKey, health)
    local towerData = _activeTowers[towerKey]
    if not towerData then
        return
    end
    
    -- 通知客户端箭塔受损
    self.Client.TowerDamaged:FireAll({
        islandName = towerData.islandName,
        towerIndex = towerData.towerIndex,
        health = health,
        maxHealth = towerData.config.Health or 100
    })
    
    -- 更新数据库中的箭塔生命值
    self:UpdateTowerHealthInDatabase(towerData.islandName, towerData.towerIndex, health)
end

-- 箭塔被摧毁处理
function TowerService:OnTowerDestroyed(towerKey)
    local towerData = _activeTowers[towerKey]
    if not towerData then
        return
    end
    
    print("箭塔被摧毁:", towerKey)
    
    -- 停止攻击
    self:StopTowerAttack(towerKey)
    
    -- 断开连接
    local connections = _towerConnections[towerKey]
    if connections then
        if connections.health then
            connections.health:Disconnect()
        end
        if connections.died then
            connections.died:Disconnect()
        end
        _towerConnections[towerKey] = nil
    end
    
    -- 从数据库中移除箭塔
    self:RemoveTowerFromDatabase(towerData.islandName, towerData.towerIndex)
    
    -- 销毁箭塔模型
    if towerData.model then
        towerData.model:Destroy()
    end
    
    -- 移除箭塔数据
    _activeTowers[towerKey] = nil
    
    -- 通知客户端箭塔被摧毁
    self.Client.TowerDestroyed:FireAll({
        islandName = towerData.islandName,
        towerIndex = towerData.towerIndex
    })
end

-- 从数据库中移除箭塔
function TowerService:RemoveTowerFromDatabase(islandName, towerIndex)
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    local islandData = islandOwners[islandName]
    
    if islandData and islandData.towerData then
        islandData.towerData[towerIndex] = nil
        
        -- 通知SystemService更新数据
        SystemService:ChangeIsLandData(islandName, islandData)
    end
end

-- 获取箭塔信息（移除了弹药相关信息）
function TowerService:GetTowerInfo(islandName, towerIndex)
    local towerKey = islandName .. "_" .. towerIndex
    local towerData = _activeTowers[towerKey]
    
    if not towerData then
        return nil
    end
    
    return {
        health = towerData.health,
        maxHealth = towerData.config.Health,
        isOccupied = towerData.isOccupied,
        occupierUserId = towerData.occupierUserId,
        towerType = towerData.towerType
    }
end

-- 船只攻击箭塔
function TowerService:BoatAttackTower(boat, islandName, towerIndex, damage)
    local towerKey = islandName .. "_" .. towerIndex
    local towerData = _activeTowers[towerKey]
    
    if not towerData or not towerData.model then
        return false
    end
    
    -- 对箭塔造成伤害
    local attackDamage = damage or 10
    local currentHealth = towerData.health or 0
    local newHealth = math.max(0, currentHealth - attackDamage)
    towerData.health = newHealth
    
    print("船只攻击箭塔，造成", attackDamage, "点伤害，箭塔剩余生命值:", newHealth)
    
    -- 如果箭塔生命值为0，摧毁箭塔
    if newHealth <= 0 then
        self:DestroyTower(islandName, towerIndex)
        print("箭塔被摧毁!")
    else
        -- 更新数据库中的箭塔生命值
        self:UpdateTowerHealthInDatabase(islandName, towerIndex, newHealth)
    end
    
    return true
end

-- 摧毁箭塔
function TowerService:DestroyTower(islandName, towerIndex)
    local towerKey = islandName .. "_" .. towerIndex
    local towerData = _activeTowers[towerKey]
    
    if not towerData then
        return
    end
    
    -- 停止攻击
    self:StopTowerAttack(towerKey)
    
    -- 从活跃箭塔列表中移除
    _activeTowers[towerKey] = nil
    
    -- 摧毁箭塔模型
    if towerData.model then
        towerData.model:Destroy()
    end
    
    -- 从数据库中移除箭塔数据
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    local islandData = islandOwners[islandName]
    
    if islandData and islandData.towerData then
        -- 找到并移除对应的箭塔数据
        for i, towerInfo in ipairs(islandData.towerData) do
            if i == towerIndex then
                table.remove(islandData.towerData, i)
                break
            end
        end
        
        -- 更新数据库
        SystemService:ChangeIsLandOwnerData(islandOwners, {islandId = islandName, isLandData = islandData})
    end
    
    print("箭塔已被摧毁:", islandName, towerIndex)
end

-- 更新数据库中的箭塔生命值
function TowerService:UpdateTowerHealthInDatabase(islandName, towerIndex, newHealth)
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    local islandData = islandOwners[islandName]
    
    if islandData and islandData.towerData and islandData.towerData[towerIndex] then
        islandData.towerData[towerIndex].health = newHealth
        --SystemService:ChangeIsLandOwnerData(islandOwners, {islandId = islandName, isLandData = islandData})
    end
end

function TowerService:CreateTower(landName, towerData)
    local index = towerData.index
    local landData = GameConfig.FindIsLand(landName)
    if not landData then
        return
    end

    local towerConfig = TowerConfig[towerData.towerType]
    if not towerConfig then
        return
    end

    local towerOffsetPos = landData.TowerOffsetPos[index]
    if not towerOffsetPos then
        return
    end

    local land = workspace:FindFirstChild(landName)
    if not land then
        return
    end
    
    local towerName = towerConfig.ModelName .. index
    local tower = land:FindFirstChild(towerName)
    if tower then
        return tower
    end

    local towerModel = ServerStorage:WaitForChild(towerConfig.ModelName):Clone()
    towerModel.Name = towerName
    towerModel.Parent = land
    local newCFrame = CFrame.new(
        landData.Position.X + towerOffsetPos.X,
        towerOffsetPos.Y,
        landData.Position.Z + towerOffsetPos.Z
    )
    towerModel:PivotTo(newCFrame)
    return towerModel
end

function TowerService:RemoveTower(landName, towerName)
    local land = workspace:FindFirstChild(landName)
    if not land then
        return
    end
    local tower = land:FindFirstChild(towerName)
    if not tower then
        return
    end
    tower:Destroy()
end

function TowerService:CreateTowersByLandName(islandName)
    local isLandOwners = Knit.GetService("SystemService"):GetIsLandOwner()
    local isLandData = isLandOwners[islandName]
    if not isLandData or not isLandData.towerData then
        return
    end

    -- 创建箭塔
    for i, data in ipairs(isLandData.towerData) do
        local towerModel = self:CreateTower(islandName, data)
        if towerModel then
            data.towerName = towerModel.Name
            
            -- 初始化箭塔到TowerService
            self:InitializeTower(towerModel, islandName, i, data.towerType)
        end
    end
end

function TowerService:RemoveTowersByLandName(islandName)
    local isLandOwners = Knit.GetService("SystemService"):GetIsLandOwner()
    local isLandData = isLandOwners[islandName]
    if not isLandData or not isLandData.towerData then
        return
    end
    
    -- 移除箭塔
    for i, data in ipairs(isLandData.towerData) do
        -- 从TowerService中移除箭塔数据
        self:RemoveTower(islandName, data.towerName)
        local towerKey = islandName .. "_" .. i
        if self._activeTowers and self._activeTowers[towerKey] then
            self:StopTowerAttack(towerKey)
            self._activeTowers[towerKey] = nil
        end
    end
end

function TowerService:KnitStart()
    print('TowerService started')
end

function TowerService:KnitInit()
    print('TowerService initialized')
end

return TowerService