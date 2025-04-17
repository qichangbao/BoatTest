print('Wave.lua loaded')
local TweenService = game:GetService('TweenService')
local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))
local TriggerService = Knit.GetService('TriggerService')

-- 创建波浪
TriggerService.CreateWave:Connect(function(data)
    local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local distance = (humanoidRootPart.Position - data.Position).Magnitude
        if distance > 400 then
            return
        end
    end

    -- 加载波浪特效预制体
    local waveTemplate = Instance.new('MeshPart')--game.ReplicatedStorage:WaitForChild('Effects'):WaitForChild('WaveEffect')
    local waveInstance = waveTemplate:Clone()
    waveInstance.Parent = workspace
    
    -- 设置初始位置和大小
    waveInstance:PivotTo(CFrame.new(data.Position))
    -- 增加波浪尺寸，使其更加壮观
    waveInstance.Size = data.Size
    waveInstance.Material = Enum.Material.Water
    
    -- 启用碰撞并设置碰撞组
    waveInstance.CanCollide = false
    waveInstance.CollisionGroup = 'WaveCollisionGroup'
    
    -- 碰撞检测逻辑
    local hitProcessed = {}
    waveInstance.Touched:Connect(function(hit)
        if hitProcessed[game.Players.LocalPlayer.UserId] then return end
        
        local boat = game.Workspace:FindFirstChild('PlayerBoat_' .. game.Players.LocalPlayer.UserId)
        if boat and boat:IsAncestorOf(hit) then
            hitProcessed[game.Players.LocalPlayer.UserId] = true
            -- -- 添加震动效果
            -- local humanoid = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
            -- if humanoid then
            --     game:GetService("TweenService"):Create(
            --         humanoid.CameraOffset,
            --         TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            --         {X = math.random(-0.5, 0.5), Y = math.random(-0.5, 0.5), Z = math.random(-0.5, 0.5)}
            --     ):Play()
            -- end
            TriggerService:WaveHitBoat(data.ChangeHp)
        end
    end)

    -- 配置半透明渐变材质
    waveInstance.Transparency = 0.2  -- 适当增加透明度
    waveInstance.Material = Enum.Material.Water
    waveInstance.Color = Color3.fromRGB(0, 180, 255)
    waveInstance.MaterialVariant = "Water2"
    
    -- 添加多层动态网格
    local waveMesh = Instance.new('SpecialMesh', waveInstance)
    waveMesh.MeshType = Enum.MeshType.FileMesh
    waveMesh.MeshId = 'rbxassetid://9756367685'
    waveMesh.TextureId = 'rbxassetid://8768189980'
    waveMesh.Scale = Vector3.new(1.2, 1.5, 1.2)  -- 调整网格尺寸
    
    -- -- 添加粒子系统
    -- local particles = Instance.new('ParticleEmitter', waveInstance)
    -- particles.Texture = 'rbxassetid://8042819935'  -- 更新为水花飞溅纹理
    -- particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 8)})  -- 增大粒子尺寸
    -- particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.7)})  -- 降低透明度
    -- particles.Lifetime = NumberRange.new(1, 5)
    -- particles.Rate = 250  -- 增加粒子发射率
    -- particles.LightEmission = 1.0
    -- particles.Speed = NumberRange.new(8, 15)  -- 增加粒子速度
    -- particles.Color = ColorSequence.new(Color3.fromRGB(0, 120, 220))
    
    -- -- 添加第二层细碎浪花粒子
    -- local sprayParticles = Instance.new('ParticleEmitter', waveInstance)
    -- sprayParticles.Texture = 'rbxassetid://6444378528'  -- 更新为水波纹理
    -- sprayParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5)})  -- 增大粒子尺寸
    -- sprayParticles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.9)})
    -- sprayParticles.Lifetime = NumberRange.new(0.5, 2.5)  -- 延长粒子寿命
    -- sprayParticles.Rate = 300  -- 增加粒子发射率
    -- sprayParticles.VelocitySpread = 70  -- 增加粒子扩散范围
    -- sprayParticles.Speed = NumberRange.new(8, 20)  -- 增加粒子速度
    -- sprayParticles.Rotation = NumberRange.new(-180, 180)
    -- sprayParticles.LightEmission = 0.8
    -- sprayParticles.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
    
    -- -- 添加第三层雾气粒子
    -- local mistParticles = Instance.new('ParticleEmitter', waveInstance)
    -- mistParticles.Texture = 'rbxassetid://8042819935'  -- 更新为水花飞溅纹理
    -- mistParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 12), NumberSequenceKeypoint.new(1, 20)})  -- 增大粒子尺寸
    -- mistParticles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.95)})
    -- mistParticles.Lifetime = NumberRange.new(3, 8)  -- 延长粒子寿命
    -- mistParticles.Rate = 80  -- 增加粒子发射率
    -- mistParticles.Speed = NumberRange.new(3, 7)  -- 增加粒子速度
    -- mistParticles.LightEmission = 0.5
    -- mistParticles.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    
    -- 波浪动画参数
    -- 改用Tween实现波动动画，增强波动效果
    local waveTween1 = TweenService:Create(
        waveInstance,
        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),  -- 加快动画速度
        {CFrame = waveInstance.CFrame * CFrame.new(0, 0.5, 0)}  -- 增大波动幅度
    )
    
    local waveTween2 = TweenService:Create(
        waveInstance,
        TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1),  -- 加快动画速度
        {CFrame = waveInstance.CFrame * CFrame.Angles(0, 0, math.rad(8))}  -- 增大旋转角度
    )
    
    waveTween1:Play()
    waveTween2:Play()

    -- 位置移动动画，增加加速度效果
    local moveTween = TweenService:Create(
        waveInstance,
        TweenInfo.new(
            data.Lifetime,  -- 减少移动时间，使波浪移动更快
            Enum.EasingStyle.Quad,  -- 使用Quad缓动使波浪有加速效果
            Enum.EasingDirection.In
        ),
        {CFrame = CFrame.new(data.TargetPosition)}
    )
    moveTween:Play()
    
    moveTween.Completed:Connect(function()
        waveInstance:Destroy()
    end)
end)