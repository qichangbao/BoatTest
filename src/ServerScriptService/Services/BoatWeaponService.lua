local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
local BoatWeaponConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatWeaponConfig"))
local BoatConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BoatConfig"))

local BoatWeaponService = Knit.CreateService({
    Name = 'BoatWeaponService',
    Client = {
    },
})

-- 存储所有激活的船炮
local _activeBoatWeapons = {}

-- 初始化船炮
function BoatWeaponService:InitializeBoatWeapons(userId, islandName)
    local boat = Interface.GetBoatByPlayerUserId(userId)
    if not boat then return end
    
    -- 如果已经有该玩家的船炮记录，先清除
    if _activeBoatWeapons[userId] then
        self:DeactivateBoatWeapons(userId)
    end
    
    -- 初始化该玩家的船炮记录
    _activeBoatWeapons[userId] = {
        weapons = {},
        targets = {},
        attackConnection = nil
    }
    
    -- 获取船只配置
    local modelName = boat:GetAttribute("ModelName")
    local curBoatConfig = BoatConfig.GetBoatConfig(modelName)
    
    -- 遍历船只上的所有部件，找出武器部件
    for _, part in ipairs(boat:GetChildren()) do
        if part:IsA("BasePart") and curBoatConfig[part.Name] and curBoatConfig[part.Name].PartType == "WeaponPart" then
            local weaponConfig = BoatWeaponConfig.GetWeaponConfig(part.Name)
            if weaponConfig then
                table.insert(_activeBoatWeapons[userId].weapons, {
                    part = part,
                    config = weaponConfig,
                    lastAttackTime = 0
                })
            end
        end
    end
    
    -- 如果有武器，创建攻击心跳
    if #_activeBoatWeapons[userId].weapons > 0 then
        _activeBoatWeapons[userId].attackConnection = RunService.Heartbeat:Connect(function()
            self:BoatWeaponAttackTick(userId, islandName)
        end)
        print("船炮系统已激活，玩家ID:", userId)
    end
end

-- 停用船炮
function BoatWeaponService:DeactivateBoatWeapons(userId)
    local boatWeapons = _activeBoatWeapons[userId]
    if boatWeapons and boatWeapons.attackConnection then
        boatWeapons.attackConnection:Disconnect()
        _activeBoatWeapons[userId] = nil
        print("船炮系统已停用，玩家ID:", userId)
    end
end

-- 船炮攻击心跳
function BoatWeaponService:BoatWeaponAttackTick(userId, islandName)
    local boatWeapons = _activeBoatWeapons[userId]
    if not boatWeapons then return end
    
    local player = Players:GetPlayerByUserId(userId)
    if not player then
        self:DeactivateBoatWeapons(userId)
        return
    end
    
    local boat = Interface.GetBoatByPlayerUserId(userId)
    if not boat or not boat.PrimaryPart then
        self:DeactivateBoatWeapons(userId)
        return
    end
    
    -- 寻找目标
    self:FindTargets(userId, islandName)
    
    -- 对每个武器执行攻击
    for _, weaponData in ipairs(boatWeapons.weapons) do
        self:WeaponAttackTick(userId, weaponData)
    end
end

-- 寻找攻击目标
function BoatWeaponService:FindTargets(userId, islandName)
    local boatWeapons = _activeBoatWeapons[userId]
    if not boatWeapons then return end
    
    -- 清空当前目标列表
    boatWeapons.targets = {}
    
    if islandName then
        -- 寻找岛屿箭塔目标
        local islandActiveInfo = Knit.GetService("TowerService"):GetIslandActiveInfo(islandName)
        if islandActiveInfo then
            -- 检查玩家是否正在占领该岛屿
            if islandActiveInfo.occupierUserId and islandActiveInfo.occupierUserId == userId and islandActiveInfo.towers then
                for _, towerData in pairs(islandActiveInfo.towers) do
                    table.insert(boatWeapons.targets, {
                        type = "Tower",
                        model = towerData.model,
                        islandName = islandName,
                        towerIndex = towerData.index
                    })
                end
            end
        end
    end
    
    -- 寻找怪物目标
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:GetAttribute("Type") == "Monster" then
            if obj.Humanoid.Health > 0 then
                table.insert(boatWeapons.targets, {
                    type = "Monster",
                    model = obj
                })
            end
        end
    end
end

-- 武器攻击逻辑
function BoatWeaponService:WeaponAttackTick(userId, weaponData)
    local boatWeapons = _activeBoatWeapons[userId]
    if not boatWeapons or #boatWeapons.targets == 0 then return end
    
    local currentTime = tick()
    local attackCooldown = 1 / weaponData.config.AttackSpeed -- 攻击间隔
    
    -- 检查攻击冷却
    if currentTime - weaponData.lastAttackTime < attackCooldown then
        return
    end
    
    local weaponPart = weaponData.part
    if not weaponPart or not weaponPart.Parent then return end
    
    -- 获取武器朝向（默认炮头朝向Z轴负方向）
    local weaponCFrame = weaponPart.CFrame
    -- 尝试不同的朝向向量，根据船炮的实际朝向调整
    local weaponForward = weaponCFrame.LookVector  -- 先尝试正向
    -- local weaponForward = -weaponCFrame.LookVector  -- Z轴负方向
    -- local weaponForward = weaponCFrame.RightVector  -- X轴正方向
    -- local weaponForward = -weaponCFrame.RightVector  -- X轴负方向
    
    -- 寻找在攻击范围和角度内的目标
    local targetModel = nil
    local minDistance = math.huge
    
    for _, targetData in ipairs(boatWeapons.targets) do
        local target = targetData.model
        if target and target.PrimaryPart then
            -- 计算距离
            local targetPos = target.PrimaryPart.Position
            local weaponPos = weaponCFrame.Position
            local toTarget = (targetPos - weaponPos).Unit
            local distance = (targetPos - weaponPos).Magnitude
            
            -- 计算角度（点积）
            local dotProduct = weaponForward:Dot(toTarget)
            local angleRad = math.acos(math.clamp(dotProduct, -1, 1))
            local angleDeg = math.deg(angleRad)
            
            -- 检查是否在攻击范围和角度内
            if distance <= weaponData.config.AttackRange and angleDeg <= weaponData.config.AttackAngle / 2 and distance < minDistance then
                targetModel = target
                minDistance = distance
            end
        end
    end
    
    -- 如果找到目标，执行攻击（炮弹按直线轨迹发射）
    if targetModel then
        self:FireProjectile(userId, weaponData)
        weaponData.lastAttackTime = currentTime
    end
end

-- 发射炮弹（每帧设置位置模式）
-- @param userId 用户ID
-- @param weaponData 武器数据
function BoatWeaponService:FireProjectile(userId, weaponData)
    local player = Players:GetPlayerByUserId(userId)
    if not player then return end
    
    local weaponPart = weaponData.part
    if not weaponPart or not weaponPart.Parent then return end
    
    -- 克隆炮弹模型
    local projectileTemplate = ServerStorage:FindFirstChild(weaponData.config.ProjectileName)
    if not projectileTemplate then
        warn("找不到炮弹模型:", weaponData.config.ProjectileName)
        return
    end
    
    local projectileOffsetPos = weaponPart:FindFirstChild("ProjectileOffsetPos")
    if not projectileOffsetPos then
        warn("武器部件缺少ProjectileOffsetPos:", weaponPart.Name)
        return
    end
    
    -- 计算发射起始位置和方向
    local weaponCFrame = weaponPart.CFrame
    local startPos = weaponPart.Position + weaponCFrame:VectorToWorldSpace(projectileOffsetPos.Value)
    local weaponForward = weaponCFrame.LookVector -- 与目标检测保持一致的朝向
    
    -- 计算炮弹飞行的终点位置（按直线轨迹）
    local maxRange = weaponData.config.AttackRange
    local endPos = startPos + weaponForward * maxRange
    
    local projectile = projectileTemplate:Clone()
    projectile.Parent = workspace
    projectile.Name = weaponData.part.Name .. tick()
    projectile.CanCollide = false
    projectile.Anchored = true -- 锚定炮弹，完全由脚本控制位置
    -- 设置炮弹物理属性
    projectile.TopSurface = Enum.SurfaceType.Smooth
    projectile.BottomSurface = Enum.SurfaceType.Smooth
    projectile.Material = Enum.Material.Neon
    projectile.Scale = projectile:FindFirstChild("ScaleValue"):GetValue()
    -- 设置炮弹初始位置和朝向（朝向直线轨迹方向）
    projectile:PivotTo(CFrame.lookAt(startPos, endPos))
        
    -- 计算飞行参数
    local speed = weaponData.config.ProjectileSpeed
    local direction = (endPos - startPos).Unit
    
    -- 炮弹飞行状态
    local maxFlightDistance = weaponData.config.AttackRange -- 使用武器射程作为最大飞行距离
    local maxFlightTime = maxFlightDistance / speed -- 根据速度计算最大飞行时间
    
    local projectileData = {
        startTime = tick(),
        startPos = startPos,
        endPos = endPos,
        direction = direction,
        speed = speed,
        explosionRadius = weaponData.config.ExplosionRadius or 5,
        damage = weaponData.config.Damage or 10,
        hasExploded = false,
        maxFlightDistance = maxFlightDistance,
        maxFlightTime = maxFlightTime,
        projectile = projectile
    }
    
    -- 添加尾迹效果
    task.spawn(function()
        local attachment0 = Instance.new("Attachment")
        attachment0.Position = Vector3.new(-projectile.Size.X/2, 0, 0) -- 炮弹后部
        attachment0.Parent = projectile
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Position = Vector3.new(0, 0, 0) -- 炮弹中心
        attachment1.Parent = projectile
        
        local trail = Instance.new("Trail")
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Lifetime = 0.8
        trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
        trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 150, 0))
        trail.Parent = projectile
    end)
    
    -- 启动炮弹飞行循环
    task.spawn(function()
        self:UpdateProjectilePosition(projectileData)
    end)
    
    -- 自动销毁时间
    Debris:AddItem(projectile, maxFlightTime + 2)
end

-- 更新炮弹位置（每帧移动模式）
-- @param projectileData 炮弹数据
function BoatWeaponService:UpdateProjectilePosition(projectileData)
    local projectile = projectileData.projectile
    if not projectile or not projectile.Parent then return end
    
    local startTime = projectileData.startTime
    local startPos = projectileData.startPos
    local direction = projectileData.direction
    local speed = projectileData.speed
    local maxFlightTime = projectileData.maxFlightTime
    local maxFlightDistance = projectileData.maxFlightDistance
    
    -- 连接到渲染步进事件，每帧更新位置
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if projectileData.hasExploded then
            connection:Disconnect()
            return
        end
        
        if not projectile or not projectile.Parent then
            connection:Disconnect()
            return
        end
        
        local currentTime = tick()
        local elapsedTime = currentTime - startTime
        
        -- 检查是否超过最大飞行时间
        if elapsedTime >= maxFlightTime then
            self:ExplodeProjectile(projectile, projectileData, projectile.Position)
            connection:Disconnect()
            return
        end
        
        -- 计算当前应该到达的位置
        local travelDistance = speed * elapsedTime
        
        -- 检查是否超过最大飞行距离
        if travelDistance >= maxFlightDistance then
            local finalPos = startPos + direction * maxFlightDistance
            projectile:PivotTo(CFrame.lookAt(finalPos, finalPos + direction))
            self:ExplodeProjectile(projectile, projectileData, finalPos)
            connection:Disconnect()
            return
        end
        
        -- 更新炮弹位置
        local currentPos = startPos + direction * travelDistance
        projectile:PivotTo(CFrame.lookAt(currentPos, currentPos + direction))
        
        -- 检查碰撞
        self:CheckProjectileCollision(projectile, projectileData, currentPos)
        
        -- 如果已经爆炸，断开连接
        if projectileData.hasExploded then
            connection:Disconnect()
            return
        end
    end)
end

-- 检测炮弹碰撞
function BoatWeaponService:CheckProjectileCollision(projectile, projectileData, currentPos)
    if projectileData.hasExploded then return end
    
    local collisionRadius = 4 -- 基础碰撞检测半径
    local maxCheckDistance = collisionRadius * 3 -- 最大检测距离
    local objectsToCheck = {}
    
    -- 收集附近的潜在目标
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= projectile and obj.PrimaryPart then
            local targetPos = obj.PrimaryPart.Position
            local distance = (currentPos - targetPos).Magnitude
            
            -- 预筛选：只检查距离较近的目标
            if distance <= maxCheckDistance then
                -- 排除船只本身
                local isBoat = obj:FindFirstChild("Seat") or obj:GetAttribute("BoatType")
                if not isBoat then
                    table.insert(objectsToCheck, {model = obj, distance = distance, position = targetPos})
                end
            end
        end
    end
    
    -- 按距离排序，优先检查最近的目标
    table.sort(objectsToCheck, function(a, b) return a.distance < b.distance end)
    
    -- 检查碰撞
    for _, objData in ipairs(objectsToCheck) do
        local obj = objData.model
        local isValidTarget = false
        
        -- 检查是否为怪物
        if obj:FindFirstChild("Humanoid") and obj:GetAttribute("Type") == "Monster" then
            if obj.Humanoid.Health > 0 then
                isValidTarget = true
            end
        -- 检查是否为箭塔
        elseif obj:GetAttribute("TowerType") then
            isValidTarget = true
        end
        
        -- 如果是有效目标，进行精确碰撞检测
        if isValidTarget then
            local distance = objData.distance
            
            -- 考虑目标的大小进行碰撞检测
            local targetSize = obj.PrimaryPart.Size
            local effectiveRadius = math.max(targetSize.X, targetSize.Z) / 2 + collisionRadius
            
            if distance <= effectiveRadius then
                self:ExplodeProjectile(projectile, projectileData, currentPos)
                return
            end
        end
    end
end

-- 炮弹爆炸处理
-- @param projectile 炮弹模型
-- @param projectileData 炮弹数据
-- @param explosionPos 爆炸位置
function BoatWeaponService:ExplodeProjectile(projectile, projectileData, explosionPos)
    if projectileData.hasExploded then return end
    projectileData.hasExploded = true
    
    -- 创建爆炸效果
    self:CreateExplosion(explosionPos, projectileData.explosionRadius)
    
    -- 检查爆炸范围内的所有目标并造成伤害
    self:CheckExplosionDamage(explosionPos, projectileData.explosionRadius, projectileData.damage)
    
    -- 延迟销毁炮弹，让爆炸效果先显示
    if projectile and projectile.Parent then
        task.spawn(function()
            task.wait(0.2) -- 稍长的延迟让爆炸效果更明显
            if projectile and projectile.Parent then
                projectile:Destroy()
            end
        end)
    end
end

-- 创建爆炸效果
function BoatWeaponService:CreateExplosion(position, radius)
    -- 创建爆炸特效
    local explosion = Instance.new("Explosion")
    explosion.Position = position
    explosion.BlastRadius = radius
    explosion.BlastPressure = 0 -- 不产生物理力
    explosion.DestroyJointRadiusPercent = 0 -- 不破坏关节
    explosion.Parent = workspace
    
    -- 禁用爆炸伤害（我们自己处理伤害）
    explosion.Hit:Connect(function()
        return
    end)
end

-- 检查爆炸范围内的目标并造成伤害
function BoatWeaponService:CheckExplosionDamage(explosionPos, radius, damage)
    if not explosionPos or not radius or not damage then
        warn("CheckExplosionDamage: 参数无效")
        return
    end
    
    -- 直接在workspace中搜索所有可能的目标
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.PrimaryPart then
            local isValidTarget = false
            
            -- 检查是否为怪物
            if obj:FindFirstChild("Humanoid") and obj:GetAttribute("Type") == "Monster" then
                if obj.Humanoid.Health > 0 then
                    isValidTarget = true
                end
            -- 检查是否为箭塔
            elseif obj:GetAttribute("TowerType") then
                isValidTarget = true
            end
            
            -- 如果是有效目标，检查距离
            if isValidTarget then
                local targetPos = obj.PrimaryPart.Position
                local targetSize = obj.PrimaryPart.Size
                
                -- 计算目标包围盒的半径（取最大边的一半）
                local targetRadius = math.max(targetSize.X, targetSize.Y, targetSize.Z) / 2
                
                -- 计算爆炸中心到目标中心的距离
                local distance = (explosionPos - targetPos).Magnitude
                
                -- 如果爆炸球体与目标包围盒相交，则判定目标在爆炸范围内
                -- 相交条件：距离 <= 爆炸半径 + 目标包围盒半径
                if distance <= (radius + targetRadius) then
                    print(string.format("目标 %s 在爆炸范围内 - 距离: %.1f, 爆炸半径: %.1f, 目标半径: %.1f", 
                        obj.Name, distance, radius, targetRadius))
                    self:DamageTarget(obj, damage)
                end
            end
        end
    end
end

-- 对目标造成伤害
function BoatWeaponService:DamageTarget(targetModel, damage)
    if not targetModel or not targetModel.Parent or not damage or damage <= 0 then 
        return 
    end
    
    local humanoid = targetModel:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        -- 对怪物造成伤害
        local oldHealth = humanoid.Health
        humanoid:TakeDamage(damage)
        local actualDamage = oldHealth - humanoid.Health
        
        print(string.format("炮弹击中怪物 %s，造成 %.1f 点伤害，剩余生命值: %.1f", 
            targetModel.Name, actualDamage, humanoid.Health))
        
        -- 如果怪物死亡，可以在这里添加额外逻辑
        if humanoid.Health <= 0 then
            print("怪物", targetModel.Name, "被船炮击杀!")
        end
    elseif targetModel:GetAttribute("TowerType") then
        -- 对箭塔造成伤害
        local success, TowerService = pcall(function()
            return Knit.GetService("TowerService")
        end)
        
        if success and TowerService then
            local towerKey = targetModel.Name
            local damageSuccess = pcall(function()
                TowerService:DamageTower(towerKey, damage)
            end)
            
            if damageSuccess then
                print(string.format("炮弹击中箭塔 %s，造成 %.1f 点伤害", towerKey, damage))
            else
                warn("对箭塔造成伤害时发生错误:", towerKey)
            end
        else
            warn("无法获取TowerService")
        end
    end
end

function BoatWeaponService:Active(player, active, islandName)
    if active then
        self:InitializeBoatWeapons(player.UserId, islandName)
    else
        self:DeactivateBoatWeapons(player.UserId)
    end
end

function BoatWeaponService:KnitInit()
end

function BoatWeaponService:KnitStart()
end

return BoatWeaponService