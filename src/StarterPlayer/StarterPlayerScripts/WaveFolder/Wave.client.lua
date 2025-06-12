local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local function CreateWave(data)
	local startPosition = data.Position
	local targetPosition = data.TargetPosition
	local changeHp = data.ChangeHp
	local lifetime = data.Lifetime
	
	-- 创建波浪
	local wave = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('OceanWaves'):Clone()
    wave.Material = Enum.Material.Water
    wave.CanCollide = false
	wave.Parent = workspace
	
	-- 设置初始位置和朝向
	local direction = (targetPosition - startPosition).Unit
	-- 使用CFrame.lookAt并添加90度旋转来修正朝向
	local initialCFrame = CFrame.lookAt(startPosition, targetPosition) * CFrame.Angles(0, math.rad(270), 0)
	wave:PivotTo(initialCFrame)
	
	-- 用于避免重复伤害的表
	local hitTargets = {}
	
	-- Touched事件连接
    local connection = wave.Touched:Connect(function(hit)
        -- 检查是否是船只
        local model = hit.Parent
        while model and model.Parent ~= workspace do
            model = model.Parent
        end
        
        if model and model:GetAttribute("ModelType") == "Boat" then
            -- 避免重复伤害
            if not hitTargets[model] then
                hitTargets[model] = true
                print("波浪碰到船只:", model.Name)
                -- 对船只造成伤害，但不销毁波浪
                Knit.GetService('TriggerService'):WaveHitBoat(changeHp)
            end
        end
    end)
	
	-- 创建移动动画
	local targetCFrame = CFrame.lookAt(targetPosition, targetPosition + direction) * CFrame.Angles(0, math.rad(270), 0)
	
	-- 动画信息
	local tweenInfo = TweenInfo.new(
		lifetime, -- 持续时间
		Enum.EasingStyle.Linear, -- 缓动样式
		Enum.EasingDirection.InOut, -- 缓动方向
		0, -- 重复次数
		false, -- 反向
		0 -- 延迟
	)
	
	-- 创建补间动画
	local tween = TweenService:Create(wave, tweenInfo, {
		CFrame = targetCFrame
	})
	
	-- 播放动画
	tween:Play()
	
	-- 动画完成后销毁波浪
	tween.Completed:Connect(function()
		-- 断开所有连接
        connection:Disconnect()
		wave:Destroy()
	end)
	
	-- 使用Debris服务作为备用销毁机制
	Debris:AddItem(wave, lifetime + 1)
end

Knit:OnStart():andThen(function()
    -- 创建波浪
    Knit.GetService('TriggerService').CreateWave:Connect(function(data)
        local humanoidRootPart = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local distance = (humanoidRootPart.Position - data.Position).Magnitude
            if distance > 800 then
                return
            end
        end
        
        CreateWave(data)
    end)
end):catch(warn)