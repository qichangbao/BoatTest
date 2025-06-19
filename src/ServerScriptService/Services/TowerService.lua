local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local TowerService = Knit.CreateService({
    Name = 'TowerService',
    Client = {
        TowerDestroyed = Knit.CreateSignal(),
        TowerDamaged = Knit.CreateSignal(),
    },
})

-- 存储激活的岛屿及其箭塔数据
local _activeIslands = {}
-- 存储所有岛屿的箭塔数据（包括未激活的）
local _islandTowers = {}
-- 存储箭塔的攻击连接
local _towerConnections = {}

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
        lastAttackTime = 0
    }
    
    -- 存储箭塔数据到岛屿分组中
    if not _islandTowers[islandName] then
        _islandTowers[islandName] = {}
    end
    local towerKey = towerModel.Name
    _islandTowers[islandName][towerKey] = towerData
    
    -- 监听生命值变化
    if humanoid then
        _towerConnections[towerKey] = humanoid.HealthChanged:Connect(function(health)
            self:OnTowerHealthChanged(islandName, towerKey, health)
        end)
    end
end

-- 设置岛屿激活状态
-- @param islandName 岛屿名称
-- @param isActive 是否激活
-- @param occupierUserId 占领者用户ID
function TowerService:SetIslandActive(islandName, isActive, occupierUserId)
    if isActive then
        -- 激活岛屿，将该岛屿的箭塔数据复制到激活列表中
        local islandData = {
            occupierUserId = occupierUserId,
            activatedTime = tick(),
            towers = _islandTowers[islandName] or {}
        }
        _activeIslands[islandName] = islandData
        
        -- 为该岛屿创建统一的攻击心跳
        islandData.attackConnection = RunService.Heartbeat:Connect(function()
            self:IslandAttackTick(islandName)
        end)

        -- 岛屿箭塔激活的同时激活玩家的船炮系统
        local player = Players:GetPlayerByUserId(occupierUserId)
        Knit.GetService("BoatWeaponService"):Active(player, true, islandName)
        
        print("岛屿被激活，所有箭塔开始攻击:", islandName, "占领者:", occupierUserId)
    else
        -- 岛屿箭塔取消激活的同时取消激活玩家的船炮系统
        local player = Players:GetPlayerByUserId(occupierUserId)
        Knit.GetService("BoatWeaponService"):Active(player, false)

        -- 取消激活岛屿
        local islandData = _activeIslands[islandName]
        _activeIslands[islandName] = nil
        
        -- 断开岛屿的攻击心跳连接
        if islandData.attackConnection then
            islandData.attackConnection:Disconnect()
            islandData.attackConnection = nil
        end
        
        -- 恢复该岛屿上所有箭塔满血
        local islandTowers = _islandTowers[islandName]
        if islandTowers then
            for towerKey, towerData in pairs(islandTowers) do
                local humanoid = towerData.model:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = towerData.config.Health
                end
            end
        end
        
        print("岛屿激活状态取消，所有箭塔停止攻击并恢复满血:", islandName)
    end
end

-- 岛屿攻击心跳处理
-- @param islandName 岛屿名称
function TowerService:IslandAttackTick(islandName)
    local islandData = _activeIslands[islandName]
    if not islandData or not islandData.towers then
        return
    end
    
    local landData = GameConfig.FindIsLand(islandName)
    local islandPos = Vector3.new(
        landData.Position.X + landData.WharfInOffsetPos.X,
        landData.Position.Y,
        landData.Position.Z + landData.WharfInOffsetPos.Z
    )
    -- 检查占领者船只是否在100距离内
    local boat = Interface.GetBoatByPlayerUserId(islandData.occupierUserId)
    if boat and boat.PrimaryPart then
        local distance = (boat.PrimaryPart.Position - islandPos).Magnitude
        if distance > GameConfig.OccupyMaxDis then
            -- 占领者船只超出100距离，取消岛屿激活状态
            self:SetIslandActive(islandName, false, islandData.occupierUserId)
            
            Knit.GetService("LandService"):OccupyFail(islandData.occupierUserId, islandName)
            return
        end
    else
        -- 占领者船只不存在，取消岛屿激活状态
        self:SetIslandActive(islandName, false, islandData.occupierUserId)
        return
    end
    
    -- 遍历该岛屿上的所有箭塔进行攻击
    for towerKey, towerData in pairs(islandData.towers) do
        self:TowerAttackTick(islandName, towerKey)
    end
end

-- 箭塔攻击逻辑
function TowerService:TowerAttackTick(islandName, towerKey)
    -- 检查岛屿是否仍然激活
    local islandData = _activeIslands[islandName]
    if not islandData or not islandData.occupierUserId or not islandData.towers then
        return
    end
    
    local towerData = islandData.towers[towerKey]
    if not towerData then
        return
    end
    
    local currentTime = tick()
    local attackCooldown = 1 / (towerData.config.AttackSpeed or 1) -- 攻击间隔
    
    -- 检查攻击冷却
    if currentTime - towerData.lastAttackTime < attackCooldown then
        return
    end
    
    -- 寻找敌方船只
    local targetBoat = nil
    local minDistance = math.huge

    local boat = Interface.GetBoatByPlayerUserId(islandData.occupierUserId)
    if boat and boat.PrimaryPart and boat:GetAttribute('Destroying') ~= true then
        local distance = (boat.PrimaryPart.Position - towerData.model.PrimaryPart.Position).Magnitude
        if distance <= (towerData.config.AttackRange or 50) and distance < minDistance then
            targetBoat = boat
            minDistance = distance
        end
    end
    
    if targetBoat then
        -- 执行攻击
        self:ExecuteTowerAttack(towerData, targetBoat, islandData.occupierUserId, islandName)
        towerData.lastAttackTime = currentTime
        
        print("箭塔攻击占领者船只:", islandData.occupierUserId)
    end
end

-- 寻找占领者的船只
-- 执行箭塔攻击
-- @param towerData 箭塔数据
-- @param targetBoat 目标船只
function TowerService:ExecuteTowerAttack(towerData, targetBoat, occupierUserId, islandName)
    if not targetBoat or not targetBoat.PrimaryPart then
        return
    end
    
    -- 发射箭矢
    self:FireArrow(towerData, targetBoat, occupierUserId, islandName)
end

-- 发射箭矢
-- @param towerData 箭塔数据
-- @param targetBoat 目标船只
function TowerService:FireArrow(towerData, targetBoat, occupierUserId, islandName)
    if not towerData.model or not towerData.model.PrimaryPart or not targetBoat.PrimaryPart then
        return
    end
    local startPos = towerData.model:GetPivot().Position + towerData.model:FindFirstChild("ArrowPos").Value
    local endPos = targetBoat.PrimaryPart.Position
    
    -- 克隆箭矢模型
    local arrowTemplate = ServerStorage:WaitForChild(towerData.config.ArrowName)
    local arrow = arrowTemplate:Clone()
    arrow.Name = "Arrow_" .. tick()
    arrow.Parent = workspace
    
    -- 获取箭矢原始朝向和方向
    local originalCFrame = arrow:GetPivot()
    
    -- 使用简单的lookAt方法设置朝向
    local lookAtCFrame = CFrame.lookAt(startPos, endPos)
    
    -- 使用lookAtCFrame设置位置和朝向，然后应用原始旋转
    -- 提取原始的旋转部分（去除位置信息）
    local originalRotation = originalCFrame - originalCFrame.Position
    local finalCFrame = lookAtCFrame * originalRotation
    arrow:PivotTo(finalCFrame)
    
    -- 设置箭矢属性
    if arrow.PrimaryPart then
        arrow.PrimaryPart.Anchored = true
        arrow.PrimaryPart.CanCollide = false
        
        -- 计算飞行时间（基于距离）
        local distance = (endPos - startPos).Magnitude
        local flyTime = distance / towerData.config.ArrowSpeed
        
        -- 使用TweenService创建移动动画
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(
            flyTime, -- 动画时间
            Enum.EasingStyle.Linear, -- 线性运动
            Enum.EasingDirection.Out,
            0, -- 重复次数
            false, -- 是否反向
            0 -- 延迟时间
        )
        
        -- 创建移动到目标位置的动画（保持朝向）
        -- 计算目标位置的CFrame，保持当前朝向
        local currentRotation = finalCFrame - finalCFrame.Position
        local targetCFrame = CFrame.new(endPos) * currentRotation
        
        -- 创建一个临时的CFrame值对象来进行动画
        local cframeValue = Instance.new("CFrameValue")
        cframeValue.Value = finalCFrame
        
        -- 监听CFrame值变化，更新整个箭矢模型的位置
        local connection
        connection = cframeValue.Changed:Connect(function(newCFrame)
            if arrow and arrow.Parent then
                arrow:PivotTo(newCFrame)
            end
        end)
        
        local moveTween = TweenService:Create(cframeValue, tweenInfo, {Value = targetCFrame})
        
        -- 开始动画
        moveTween:Play()
        
        -- 动画完成后检查是否击中目标
        moveTween.Completed:Connect(function()
            -- 清理连接和临时对象
            if connection then
                connection:Disconnect()
                connection = nil
            end
            if cframeValue then
                cframeValue:Destroy()
                cframeValue = nil
            end
            
            -- 检查箭矢是否到达目标船只附近
            if targetBoat and targetBoat.Parent and arrow.PrimaryPart then
                local arrowPos = arrow.PrimaryPart.Position
                local boatPos = targetBoat.PrimaryPart and targetBoat.PrimaryPart.Position or targetBoat:GetPivot().Position
                local hitDistance = (arrowPos - boatPos).Magnitude
                
                -- 如果箭矢在船只附近（容错范围10单位），认为击中
                if hitDistance <= 10 then
                    -- 对船只造成伤害
                    self:AttackBoat(targetBoat, towerData.config.Damage or 10, occupierUserId, islandName)
                end
            end
            
            -- 销毁箭矢
            arrow:Destroy()
        end)
        
        -- 5秒后自动销毁箭矢（防止箭矢永远存在）
        game:GetService("Debris"):AddItem(arrow, 5)
    end
end

-- 箭矢攻击船只
-- @param targetBoat 目标船只
-- @param damage 伤害值
function TowerService:AttackBoat(targetBoat, damage, occupierUserId, islandName)
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
        Knit.GetService("LandService"):OccupyFail(occupierUserId, islandName)
    end
end

-- 箭塔生命值变化处理
function TowerService:OnTowerHealthChanged(islandName, towerKey, health)
    local islandTowers = _islandTowers[islandName]
    if not islandTowers then
        return
    end
    
    local towerData = islandTowers[towerKey]
    if not towerData then
        return
    end
    
    if health == towerData.config.Health then
        return
    end

    if health <= 0 then
        -- 断开连接
        local connections = _towerConnections[towerKey]
        if connections then
            connections:Disconnect()
            _towerConnections[towerKey] = nil
        end
        
        -- 从数据库中移除箭塔
        self:RemoveTowerFromDatabase(towerData.islandName, towerData.towerIndex)
        
        -- 销毁箭塔模型
        if towerData.model then
            towerData.model:Destroy()
        end
        
        -- 移除箭塔数据
        islandTowers[towerKey] = nil
        
        -- 通知客户端箭塔被摧毁
        self.Client.TowerDestroyed:FireAll({
            islandName = islandName,
            towerName = towerKey
        })
    else
        -- 通知客户端箭塔受损
        self.Client.TowerDamaged:FireAll({
            islandName = islandName,
            towerName = towerKey,
            health = health,
            maxHealth = towerData.config.Health or 100
        })
    end
end

-- 从数据库中移除箭塔
function TowerService:RemoveTowerFromDatabase(islandName, towerIndex)
    local SystemService = Knit.GetService("SystemService")
    local islandOwners = SystemService:GetIsLandOwner()
    local islandData = islandOwners[islandName]
    
    if islandData and islandData.towerData then
        islandData.towerData[towerIndex] = nil
        
        -- 通知SystemService更新数据
        SystemService:ChangeIsLandOwnerData(islandOwners, {islandId = islandName, isLandData = islandData})
    end
end

-- 获取箭塔信息
function TowerService:GetTowerInfo(islandName, towerIndex)
    local towerKey = islandName .. "_" .. towerIndex
    local islandTowers = _islandTowers[islandName]
    if not islandTowers then
        return nil
    end
    
    local towerData = islandTowers[towerKey]
    if not towerData then
        return nil
    end
    
    -- 从 _activeIslands 中获取占领信息
    local islandData = _activeIslands[towerData.islandName]
    local isOccupied = islandData ~= nil
    local occupierUserId = islandData and islandData.occupierUserId or nil
    
    return {
        health = towerData.health,
        maxHealth = towerData.config.Health,
        isOccupied = isOccupied,
        occupierUserId = occupierUserId,
        towerType = towerData.towerType
    }
end

-- 获取岛屿激活信息
-- @param islandName 岛屿名称
-- @return 岛屿激活数据或nil
function TowerService:GetIslandActiveInfo(islandName)
    return _activeIslands[islandName]
end

-- 检查岛屿是否激活
-- @param islandName 岛屿名称
-- @return boolean 是否激活
function TowerService:IsIslandActive(islandName)
    return _activeIslands[islandName] ~= nil
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

    self:InitializeTower(towerModel, landName, index, towerData.towerType)
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

    if _islandTowers[landName] then
        _islandTowers[landName][towerName] = nil
    end
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
        end
    end
end

function TowerService:RemoveTowersByLandName(islandName)
    local isLandOwners = Knit.GetService("SystemService"):GetIsLandOwner()
    local isLandData = isLandOwners[islandName]
    if not isLandData or not isLandData.towerData then
        return
    end
    
    -- 取消岛屿激活状态
    if _activeIslands[islandName] then
        self:SetIslandActive(islandName, false, _activeIslands[islandName].occupierUserId)
    end
    
    -- 移除箭塔
    for i, data in ipairs(isLandData.towerData) do
        -- 从TowerService中移除箭塔数据
        self:RemoveTower(islandName, data.towerName)
        if _islandTowers[islandName] then
            _islandTowers[islandName][data.towerName] = nil
        end
    end
end

function TowerService:KnitStart()
end

function TowerService:KnitInit()
end

return TowerService