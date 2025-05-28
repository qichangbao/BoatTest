print('Wave.lua loaded')
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))

Knit:OnStart():andThen(function()
    -- 创建波浪
    Knit.GetService('TriggerService').CreateWave:Connect(function(data)
        local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local distance = (humanoidRootPart.Position - data.Position).Magnitude
            if distance > 400 then
                return
            end
        end

        local wave = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('Wave'):Clone()
        wave.Parent = workspace
        wave:PivotTo(CFrame.new(data.Position))
        for _, part in ipairs(wave:GetDescendants()) do
            if part:IsA('BasePart') then
                part.CollisionGroup = 'WaveCollisionGroup'
            end
        end

        local direction = (data.TargetPosition - data.Position).Unit
        local speed = 50 -- 你可以调整波浪的移动速度

        -- 碰撞检测和伤害
        local connection
        connection = wave.Touched:Connect(function(hit)
            local character = hit.Parent
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- 在这里你可以调用一个服务来处理伤害，或者直接操作Humanoid
                -- 例如: Knit.GetService("DamageService"):DealDamage(character, data.ChangeHp)
                -- 为了简单起见，我们直接修改Health，但请注意这通常应该在服务器端处理以保证安全
                -- humanoid:TakeDamage(data.ChangeHp) -- 客户端不应该直接操作其他玩家的血量
                print(string.format("Wave hit %s, intended damage: %s", character.Name, data.ChangeHp))
                
                -- 假设波浪碰到玩家后就消失
                wave:Destroy()
                if connection then
                    connection:Disconnect()
                end
            end
        end)

        -- 生命周期和移动
        local startTime = tick()
        local moveConnection
        moveConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if not wave or not wave.Parent then
                if moveConnection then
                    moveConnection:Disconnect()
                end
                if connection then
                    connection:Disconnect()
                end
                return
            end

            if tick() - startTime > data.Lifetime then
                wave:Destroy()
                if moveConnection then
                    moveConnection:Disconnect()
                end
                if connection then
                    connection:Disconnect()
                end
                return
            end

            wave.CFrame = CFrame.lookAt(wave.Position, data.TargetPosition)
            wave.Position = wave.Position + direction * speed * dt
        end)

        -- 确保在波浪被意外销毁时断开连接
        wave.AncestryChanged:Connect(function(_, parent)
            if not parent then
                if moveConnection then
                    moveConnection:Disconnect()
                end
                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)
end):catch(warn)