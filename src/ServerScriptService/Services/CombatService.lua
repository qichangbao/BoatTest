local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local MonsterConfig = require(game.ServerScriptService:WaitForChild("AIManagerFolder"):WaitForChild("MonsterConfig"))

local CombatService = Knit.CreateService({
    Name = 'CombatService',
    Client = {
        CreateDamageDisplay = Knit.CreateSignal(),
    },
})

-- 武器配置
local WeaponConfig = {
    ["Sword"] = {
        Damage = 25,
        Range = 10,
        Cooldown = 0.3,
        AttackType = "Melee"
    },
    ["Bow"] = {
        Damage = 20,
        Range = 100,
        Cooldown = 0.4,
        AttackType = "Ranged",
        ProjectileSpeed = 80
    },
    ["Magic"] = {
        Damage = 30,
        Range = 50,
        Cooldown = 0.5,
        AttackType = "Magic"
    }
}

-- 玩家攻击冷却时间记录
local playerCooldowns = {}

-- 初始化玩家数据
function CombatService:PlayerAdded(player)
    playerCooldowns[player.UserId] = {
        lastAttackTime = 0,
        currentWeapon = "Sword" -- 默认武器
    }
end

-- 清理玩家数据
function CombatService:PlayerRemoving(player)
    playerCooldowns[player.UserId] = nil
end

-- 检查攻击冷却
function CombatService:IsAttackOnCooldown(player, weaponType)
    local playerData = playerCooldowns[player.UserId]
    if not playerData then return true end
    
    local weaponConfig = WeaponConfig[weaponType]
    if not weaponConfig then return true end
    
    local currentTime = tick()
    local timeSinceLastAttack = currentTime - playerData.lastAttackTime
    
    return timeSinceLastAttack < weaponConfig.Cooldown
end

-- 设置攻击冷却
function CombatService:SetAttackCooldown(player, weaponType)
    local playerData = playerCooldowns[player.UserId]
    if playerData then
        playerData.lastAttackTime = tick()
    end
end

-- 寻找攻击范围内的怪物
function CombatService:FindMonstersInRange(position, range)
    local monsters = {}
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:GetAttribute("Type") == "Monster" and obj:FindFirstChild("Humanoid") then
            local humanoid = obj:FindFirstChild("Humanoid")
            local humanoidRootPart = obj:FindFirstChild("HumanoidRootPart")
            
            if humanoid.Health > 0 and humanoidRootPart then
                local distance = (position - humanoidRootPart.Position).Magnitude
                if distance <= range then
                    table.insert(monsters, {
                        model = obj,
                        distance = distance,
                        humanoid = humanoid,
                        humanoidRootPart = humanoidRootPart
                    })
                end
            end
        end
    end
    
    -- 按距离排序，最近的在前
    table.sort(monsters, function(a, b)
        return a.distance < b.distance
    end)
    
    return monsters
end

-- 创建伤害数字显示
function CombatService:CreateDamageDisplay(monster, damage)
    local humanoidRootPart = monster:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- 通知客户端显示伤害数字
    self.Client.CreateDamageDisplay:FireAll(monster, damage)
end

-- 创建投射物（弓箭、魔法等）
function CombatService:CreateProjectile(startPosition, targetPosition, weaponType, player)
    local weaponConfig = WeaponConfig[weaponType]
    if not weaponConfig or weaponConfig.AttackType ~= "Ranged" then return end
    
    -- 创建投射物模型
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(0.2, 0.2, 2)
    projectile.Material = Enum.Material.Neon
    projectile.BrickColor = BrickColor.new("Bright yellow")
    projectile.CanCollide = false
    projectile.Anchored = true
    
    -- 设置投射物位置和朝向
    local direction = (targetPosition - startPosition).Unit
    projectile.CFrame = CFrame.lookAt(startPosition, targetPosition)
    projectile.Parent = workspace
    
    -- 投射物移动
    local speed = weaponConfig.ProjectileSpeed
    local maxDistance = weaponConfig.Range
    local traveledDistance = 0
    
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        local moveDistance = speed * dt
        traveledDistance = traveledDistance + moveDistance
        
        if traveledDistance >= maxDistance then
            connection:Disconnect()
            projectile:Destroy()
            return
        end
        
        local newPosition = projectile.Position + direction * moveDistance
        projectile.Position = newPosition
        
        -- 检测碰撞
        local monsters = self:FindMonstersInRange(newPosition, 3)
        if #monsters > 0 then
            local monster = monsters[1].model
            self:DamageMonster(monster, weaponConfig.Damage, player)
            connection:Disconnect()
            projectile:Destroy()
        end
    end)
    
    -- 5秒后自动销毁投射物
    Debris:AddItem(projectile, 5)
end

-- 对怪物造成伤害
function CombatService:DamageMonster(monster, damage, attacker)
    local humanoid = monster:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    -- 造成伤害
    humanoid.Health = math.max(0, humanoid.Health - damage)
    
    -- 显示伤害数字
    self:CreateDamageDisplay(monster, damage)
    
    -- 如果怪物死亡，处理死亡逻辑
    if humanoid.Health <= 0 then
        self:HandleMonsterDeath(monster, attacker)
    else
        -- 怪物受到攻击，设置攻击者为目标
        local aiManager = monster:GetAttribute("AIManager")
        if aiManager then
            -- 这里需要与AI系统集成，让怪物攻击玩家
            print("怪物受到攻击，开始追击玩家:", attacker.Name)
        end
    end
end

-- 处理怪物死亡
function CombatService:HandleMonsterDeath(monster, killer)
    print("怪物被击杀:", monster.Name, "击杀者:", killer.Name)
    
    -- 给予玩家经验和奖励
    local DBService = Knit.GetService("DBService")
    if DBService then
        -- 这里可以添加经验和奖励逻辑
        -- DBService:AddExperience(killer, 10)
        -- DBService:AddCoins(killer, 5)
    end
    
    -- 播放死亡效果
    --self.Client.PlayDeathEffect:FireAll(monster)
    
    -- -- 延迟销毁怪物（给动画时间播放）
    -- task.wait(2)
    -- monster:Destroy()
end

-- 客户端攻击请求处理
function CombatService.Client:AttackMonster(player, weaponType, targetPosition)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- 检查攻击冷却
    if self.Server:IsAttackOnCooldown(player, weaponType) then
        return false
    end
    
    local weaponConfig = WeaponConfig[weaponType]
    if not weaponConfig then return false end
    
    local playerPosition = humanoidRootPart.Position
    local distance = (targetPosition - playerPosition).Magnitude
    
    -- 检查攻击距离
    if distance > weaponConfig.Range then
        return false
    end
    
    -- 设置攻击冷却
    self.Server:SetAttackCooldown(player, weaponType)
    
    if weaponConfig.AttackType == "Melee" or weaponConfig.AttackType == "Magic" then
        -- 近战或魔法攻击：直接伤害范围内的怪物
        local monsters = self.Server:FindMonstersInRange(targetPosition, 5)
        if #monsters > 0 then
            local monster = monsters[1].model
            self.Server:DamageMonster(monster, weaponConfig.Damage, player)
        end
    elseif weaponConfig.AttackType == "Ranged" then
        -- 远程攻击：创建投射物
        self.Server:CreateProjectile(playerPosition, targetPosition, weaponType, player)
    end
    
    return true
end

-- 服务启动
function CombatService:KnitStart()
    -- 监听玩家加入和离开
    Players.PlayerAdded:Connect(function(player)
        self:PlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:PlayerRemoving(player)
    end)
    
    -- 为已经在游戏中的玩家初始化数据
    for _, player in pairs(Players:GetPlayers()) do
        self:PlayerAdded(player)
    end
    
    print("CombatService 已启动")
end

return CombatService