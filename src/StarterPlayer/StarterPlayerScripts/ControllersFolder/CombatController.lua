local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- 战斗控制器
local CombatController = Knit.CreateController({
    Name = 'CombatController'
})

-- 武器类型
local WeaponTypes = {
    "Sword",   -- 剑（近战）
    "Bow",     -- 弓（远程）
    "Magic"    -- 魔法（范围攻击）
}

-- 当前选择的武器
local currentWeapon = "Sword"
local isAttacking = false
local lastAttackTime = 0

-- 武器冷却时间配置（与服务端保持一致）
local WeaponCooldowns = {
    ["Sword"] = 0.3,
    ["Bow"] = 0.4,
    ["Magic"] = 0.5
}

-- UI元素
local weaponUI = nil
local crosshair = nil
local damageNumbers = {}

-- 创建武器选择UI
function CombatController:CreateWeaponUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- 主UI容器
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CombatUI"
    screenGui.Parent = playerGui
    
    -- 武器选择面板
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Name = "WeaponFrame"
    weaponFrame.Size = UDim2.new(0, 200, 0, 60)
    weaponFrame.Position = UDim2.new(0, 20, 1, -80)
    weaponFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    weaponFrame.BorderSizePixel = 0
    weaponFrame.Parent = screenGui
    
    -- 圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = weaponFrame
    
    -- 武器按钮容器
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -10, 1, -10)
    buttonContainer.Position = UDim2.new(0, 5, 0, 5)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = weaponFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 5)
    layout.Parent = buttonContainer
    
    -- 创建武器按钮
    for i, weaponType in ipairs(WeaponTypes) do
        local button = Instance.new("TextButton")
        button.Name = weaponType .. "Button"
        button.Size = UDim2.new(0, 50, 0, 50)
        button.BackgroundColor3 = weaponType == currentWeapon and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 60)
        button.Text = weaponType:sub(1, 1) -- 显示首字母
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSansBold
        button.BorderSizePixel = 0
        button.Parent = buttonContainer
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- 按钮点击事件
        button.MouseButton1Click:Connect(function()
            self:SelectWeapon(weaponType)
        end)
        
        -- 键盘快捷键
        local keyNames = {"One", "Two", "Three"}
        local keyCode = Enum.KeyCode[keyNames[i]]
        if keyCode then
            UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == keyCode then
                    self:SelectWeapon(weaponType)
                end
            end)
        end
    end
    
    weaponUI = weaponFrame
end

-- 创建准星
function CombatController:CreateCrosshair()
    local playerGui = player:WaitForChild("PlayerGui")
    
    local crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "CrosshairUI"
    crosshairGui.Parent = playerGui
    
    local crosshairFrame = Instance.new("Frame")
    crosshairFrame.Name = "Crosshair"
    crosshairFrame.Size = UDim2.new(0, 20, 0, 20)
    crosshairFrame.Position = UDim2.new(0.5, -10, 0.5, -10)
    crosshairFrame.BackgroundTransparency = 1
    crosshairFrame.Parent = crosshairGui
    
    -- 十字准星线条
    local function createLine(size, position)
        local line = Instance.new("Frame")
        line.Size = size
        line.Position = position
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BorderSizePixel = 0
        line.Parent = crosshairFrame
        return line
    end
    
    -- 水平线
    createLine(UDim2.new(0, 8, 0, 2), UDim2.new(0.5, -4, 0.5, -1))
    -- 垂直线
    createLine(UDim2.new(0, 2, 0, 8), UDim2.new(0.5, -1, 0.5, -4))
    
    crosshair = crosshairFrame
end

-- 选择武器
function CombatController:SelectWeapon(weaponType)
    if currentWeapon == weaponType then return end
    
    currentWeapon = weaponType
    print("切换武器:", weaponType)
    
    -- 更新UI
    if weaponUI then
        local buttonContainer = weaponUI:FindFirstChild("Frame")
        if buttonContainer then
            for _, button in pairs(buttonContainer:GetChildren()) do
                if button:IsA("TextButton") then
                    local isSelected = button.Name:find(weaponType)
                    button.BackgroundColor3 = isSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 60)
                end
            end
        end
    end
end

-- 检查攻击冷却
function CombatController:IsOnCooldown()
    local currentTime = tick()
    local cooldown = WeaponCooldowns[currentWeapon] or 1.5
    return (currentTime - lastAttackTime) < cooldown
end

-- 执行攻击
function CombatController:Attack(targetPosition)
    if isAttacking or self:IsOnCooldown() then
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    isAttacking = true
    lastAttackTime = tick()
    
    -- 播放攻击动画
    self:PlayAttackAnimation()
    
    -- 向服务器发送攻击请求
    local CombatService = Knit.GetService('CombatService')
    local success = CombatService:AttackMonster(currentWeapon, targetPosition)
    
    if success then
        print("攻击成功:", currentWeapon, "目标位置:", targetPosition)
        
        -- 播放攻击特效
        self:PlayAttackEffect(targetPosition)
    else
        print("攻击失败")
    end
    
    -- 攻击动画结束
    task.wait(0.5)
    isAttacking = false
end

-- 播放攻击动画
function CombatController:PlayAttackAnimation()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- 这里可以加载和播放具体的攻击动画
    -- local animator = humanoid:FindFirstChild("Animator")
    -- if animator then
    --     local attackAnim = Instance.new("Animation")
    --     attackAnim.AnimationId = "rbxassetid://攻击动画ID"
    --     local track = animator:LoadAnimation(attackAnim)
    --     track:Play()
    -- end
    
    print("播放攻击动画:", currentWeapon)
end

-- 播放攻击特效
function CombatController:PlayAttackEffect(targetPosition)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if currentWeapon == "Sword" then
        -- 近战特效：剑光
        self:CreateSlashEffect(humanoidRootPart.Position, targetPosition)
    elseif currentWeapon == "Bow" then
        -- 远程特效：弓箭轨迹（服务端会创建投射物）
        print("发射弓箭")
    elseif currentWeapon == "Magic" then
        -- 魔法特效：魔法光球
        self:CreateMagicEffect(targetPosition)
    end
end

-- 创建剑光特效
function CombatController:CreateSlashEffect(startPos, endPos)
    local effect = Instance.new("Part")
    effect.Name = "SlashEffect"
    effect.Size = Vector3.new(0.5, 0.5, (endPos - startPos).Magnitude)
    effect.Material = Enum.Material.Neon
    effect.BrickColor = BrickColor.new("Bright yellow")
    effect.CanCollide = false
    effect.Anchored = true
    effect.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -effect.Size.Z/2)
    effect.Parent = workspace
    
    -- 特效消失动画
    local tween = TweenService:Create(effect, TweenInfo.new(0.3), {
        Transparency = 1,
        Size = Vector3.new(0.1, 0.1, effect.Size.Z)
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        effect:Destroy()
    end)
end

-- 创建魔法特效
function CombatController:CreateMagicEffect(targetPosition)
    local effect = Instance.new("Part")
    effect.Name = "MagicEffect"
    effect.Size = Vector3.new(4, 4, 4)
    effect.Shape = Enum.PartType.Ball
    effect.Material = Enum.Material.Neon
    effect.BrickColor = BrickColor.new("Bright blue")
    effect.CanCollide = false
    effect.Anchored = true
    effect.Position = targetPosition
    effect.Parent = workspace
    
    -- 魔法爆炸特效
    local tween = TweenService:Create(effect, TweenInfo.new(0.5), {
        Transparency = 1,
        Size = Vector3.new(8, 8, 8)
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        effect:Destroy()
    end)
end

-- 创建伤害数字显示
function CombatController:CreateDamageNumber(monster, damage)
    local humanoidRootPart = monster:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local damageGui = Instance.new("BillboardGui")
    damageGui.Size = UDim2.new(0, 100, 0, 50)
    damageGui.StudsOffset = Vector3.new(0, 3, 0)
    damageGui.Parent = humanoidRootPart
    
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = "-" .. damage
    damageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    damageLabel.TextScaled = true
    damageLabel.Font = Enum.Font.SourceSansBold
    damageLabel.Parent = damageGui
    
    -- 伤害数字动画
    local tween = TweenService:Create(damageGui, TweenInfo.new(1.5), {
        StudsOffset = Vector3.new(0, 6, 0)
    })
    local fadeTween = TweenService:Create(damageLabel, TweenInfo.new(1.5), {
        TextTransparency = 1
    })
    
    tween:Play()
    fadeTween:Play()
    
    fadeTween.Completed:Connect(function()
        damageGui:Destroy()
    end)
end

-- 寻找最近的怪物
function CombatController:FindNearestMonster(maxDistance)
    local character = player.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local playerPosition = humanoidRootPart.Position
    local nearestMonster = nil
    local nearestDistance = maxDistance or 50
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:GetAttribute("Type") == "Monster" and obj:FindFirstChild("Humanoid") then
            local monsterHumanoid = obj:FindFirstChild("Humanoid")
            local monsterRootPart = obj:FindFirstChild("HumanoidRootPart")
            
            if monsterHumanoid.Health > 0 and monsterRootPart then
                local distance = (playerPosition - monsterRootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestMonster = obj
                end
            end
        end
    end
    
    return nearestMonster, nearestDistance
end

-- 控制器启动
function CombatController:KnitStart()
    -- 等待角色加载
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    
    -- 创建UI
    self:CreateWeaponUI()
    self:CreateCrosshair()
    
    -- 鼠标点击攻击
    mouse.Button1Down:Connect(function()
        local targetPosition = mouse.Hit.Position
        self:Attack(targetPosition)
    end)
    
    -- 键盘快捷攻击（空格键攻击最近的怪物）
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Space then
            local nearestMonster, distance = self:FindNearestMonster()
            if nearestMonster then
                local monsterRootPart = nearestMonster:FindFirstChild("HumanoidRootPart")
                if monsterRootPart then
                    self:Attack(monsterRootPart.Position)
                end
            end
        end
    end)
    
    -- 监听服务端的伤害显示事件
    local CombatService = Knit.GetService('CombatService')
    CombatService.CreateDamageDisplay:Connect(function(monster, damage)
        self:CreateDamageNumber(monster, damage)
    end)
    
    print("CombatController 已启动")
    print("控制说明:")
    print("- 鼠标左键: 攻击鼠标位置")
    print("- 空格键: 攻击最近的怪物")
    print("- 数字键1-3: 切换武器")
    print("- 当前武器:", currentWeapon)
end

return CombatController