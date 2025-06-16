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
    
    -- 获取武器朝向
    local weaponCFrame = weaponPart.CFrame
    local weaponForward = -weaponCFrame.RightVector
    
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
            -- print("angleDeg    ", angleDeg) -- 调试用，正式环境可注释
            
            -- 检查是否在攻击范围和角度内
            if distance <= weaponData.config.AttackRange and angleDeg <= weaponData.config.AttackAngle / 2 and distance < minDistance then
                targetModel = target
                minDistance = distance
            end
        end
    end
    
    -- 如果找到目标，执行攻击
    if targetModel then
        self:FireProjectile(userId, weaponData, targetModel)
        weaponData.lastAttackTime = currentTime
    end
end

-- 发射炮弹
function BoatWeaponService:FireProjectile(userId, weaponData, targetModel)
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
    local startPos = weaponPart.Position + projectileOffsetPos.Value
    local endPos = targetModel.PrimaryPart.Position
    
    local projectile = projectileTemplate:Clone()
    projectile.Name = weaponData.part.Name .. tick()
    projectile.Parent = workspace
    
    projectile:PivotTo(CFrame.new(startPos))
    -- 设置炮弹初始位置和朝向
    local lookAtCFrame = CFrame.lookAt(startPos, endPos)
    
    local part = nil
    if projectile:IsA("Model") then
        if projectile.PrimaryPart then
            projectile.PrimaryPart.Anchored = true
            projectile.PrimaryPart.CanCollide = false
        end
        part = projectile.PrimaryPart
    elseif projectile:IsA("BasePart") then
        projectile.Anchored = true
        projectile.CanCollide = false
        part = projectile
    end

    -- 设置炮弹属性
    if part then
        -- 计算飞行时间
        local distance = (endPos - startPos).Magnitude
        local flyTime = distance / weaponData.config.ProjectileSpeed
        
        -- 创建移动动画
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(
            flyTime,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out,
            0,
            false,
            0
        )
        
        -- 创建CFrame值对象进行动画
        local cframeValue = Instance.new("CFrameValue")
        cframeValue.Value = lookAtCFrame
        
        -- 监听CFrame值变化
        local connection
        connection = cframeValue.Changed:Connect(function(newCFrame)
            if projectile and projectile.Parent then
                projectile:PivotTo(newCFrame)
            end
        end)
        
        -- 计算目标CFrame
        local targetCFrame = CFrame.new(endPos) * (lookAtCFrame - lookAtCFrame.Position)
        local moveTween = TweenService:Create(cframeValue, tweenInfo, {Value = targetCFrame})
        
        -- 开始动画
        moveTween:Play()
        
        -- 动画完成后处理
        moveTween.Completed:Connect(function()
            -- 清理连接和临时对象
            if connection then connection:Disconnect() end
            if cframeValue then cframeValue:Destroy() end
            
            -- 检查是否击中目标
            if targetModel and targetModel.Parent and part then
                local cannonBallPos = part.Position
                local targetPos = targetModel.PrimaryPart.Position
                local hitDistance = (cannonBallPos - targetPos).Magnitude
                
                -- 如果炮弹在目标附近，认为击中
                if hitDistance <= weaponData.config.ExplosionRadius then
                    -- 创建爆炸效果
                    self:CreateExplosion(cannonBallPos, weaponData.config.ExplosionRadius)
                    
                    -- 对目标造成伤害
                    self:DamageTarget(targetModel, weaponData.config.Damage)
                end
            end
            
            -- 销毁炮弹
            projectile:Destroy()
        end)
        
        -- 5秒后自动销毁炮弹
        Debris:AddItem(projectile, 5)
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

-- 对目标造成伤害
function BoatWeaponService:DamageTarget(targetModel, damage)
    if not targetModel or not targetModel.Parent then return end
    
    local humanoid = targetModel:FindFirstChild("Humanoid")
    if humanoid then
        -- 对怪物造成伤害
        humanoid:TakeDamage(damage)
        print("炮弹击中怪物，造成", damage, "点伤害，剩余生命值:", humanoid.Health)
        
        -- 如果怪物死亡，可以在这里添加额外逻辑
        if humanoid.Health <= 0 then
            print("怪物被船炮击杀!")
        end
    elseif targetModel:GetAttribute("TowerType") then
        -- 对箭塔造成伤害
        local TowerService = Knit.GetService("TowerService")
        local towerKey = targetModel.Name
        
        -- 调用TowerService的伤害方法
        TowerService:DamageTower(towerKey, damage)
        print("炮弹击中箭塔", towerKey, "，造成", damage, "点伤害")
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
    -- 服务初始化逻辑
    print("BoatWeaponService 初始化完成")
end

function BoatWeaponService:KnitStart()
    -- 服务启动时的初始化逻辑
end

return BoatWeaponService