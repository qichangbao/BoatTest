print('Wave.lua loaded')
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
    local waveTemplate = game.ReplicatedStorage:WaitForChild('Effects'):WaitForChild('WaveEffect')
    local waveInstance = waveTemplate:Clone()
    waveInstance.Parent = workspace
    
    -- 设置初始位置和大小
    waveInstance:PivotTo(CFrame.new(data.Position))
    waveInstance.Size = data.Size
    
    -- 启用碰撞并设置碰撞组
    waveInstance.CanCollide = true
    
    -- 碰撞检测逻辑
    waveInstance.Touched:Connect(function(hit)
        if hit:FindFirstAncestorWhichIsA('Model') and hit:FindFirstAncestorWhichIsA('Model').Name:find('船') then
            waveInstance.CanCollide = false
            TriggerService.WaveHitBoat:Connect(data.ChangeHp)
        end
    end)

    -- 添加多层动态网格
    local waveMesh = Instance.new('SpecialMesh', waveInstance)
    waveMesh.MeshType = Enum.MeshType.FileMesh
    waveMesh.MeshId = 'rbxassetid://9756367685'  -- 使用波浪形网格
    waveMesh.TextureId = 'rbxassetid://9756372136'
    
    -- 配置半透明渐变材质
    waveInstance.Transparency = 0.7
    waveInstance.Material = Enum.Material.Neon
    
    -- 添加粒子系统
    local particles = Instance.new('ParticleEmitter', waveInstance)
    particles.Texture = 'rbxassetid://2486742877'
    particles.Size = NumberSequence.new(0.5)
    particles.Transparency = NumberSequence.new(0.3, 0.8)
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 50
    
    local TweenService = game:GetService('TweenService')
    -- 波浪动画参数
    -- 改用Tween实现波动动画
    local waveTween1 = TweenService:Create(
        waveInstance,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
        {CFrame = waveInstance.CFrame * CFrame.new(0, 0.3, 0)}
    )
    
    local waveTween2 = TweenService:Create(
        waveInstance,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1),
        {CFrame = waveInstance.CFrame * CFrame.Angles(0, 0, math.rad(5))}
    )
    
    waveTween1:Play()
    waveTween2:Play()
    
    -- 浮动动画
    local floatGoal = { Position = Vector3.new(0, 0.5, 0) }
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)
    local floatTween = TweenService:Create(waveInstance, tweenInfo, floatGoal)
    floatTween:Play()

    -- 位置移动动画
    local moveTween = TweenService:Create(
        waveInstance,
        TweenInfo.new(
            data.Lifetime,
            Enum.EasingStyle.Linear
        ),
        {CFrame = CFrame.new(data.TargetPosition)}
    )
    moveTween:Play()
    
    moveTween.Completed:Connect(function()
        waveInstance:Destroy()
    end)
end)