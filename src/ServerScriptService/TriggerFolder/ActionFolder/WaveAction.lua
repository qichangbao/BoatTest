local ActionBase = require(script.Parent:WaitForChild("ActionBase"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local WaveAction = {}
setmetatable(WaveAction, ActionBase)
WaveAction.__index = WaveAction

function WaveAction.new(config, condition)
    local self = setmetatable(ActionBase.new(config, condition), WaveAction)
    return self
end

function WaveAction:Execute(data)
    ActionBase.Execute(self)
    print("执行WaveAction")
    
    -- 确定宝箱生成位置
    local position = self.position
    local targetPosition = self.config.TargetPosition
    if self.config.UsePlayerPosition and self.config.PositionOffset and data and data.Player and data.Player.Character then
        local player = data.Player
        local frame = player.Character:GetPivot()
        position = frame.Position
        -- 获取船只的朝向，在船头前方50米位置生成宝箱
        local baseOffset = frame.LookVector * self.config.PositionOffset -- 船头前方偏移
        position = Vector3.new(position.X + baseOffset.X, 50, position.Z + baseOffset.Z)
        
        baseOffset = -frame.LookVector * 200 -- 船头前方偏移
        targetPosition = Vector3.new(position.X + baseOffset.X, 50, position.Z + baseOffset.Z)
    end
	
	-- 创建波浪
	local wave = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('OceanWaves'):Clone()
    wave.Material = Enum.Material.Water
    wave.CanCollide = false
	wave.Parent = workspace
	
	-- 设置初始位置和朝向
	local direction = (targetPosition - position).Unit
	-- 使用CFrame.lookAt并添加90度旋转来修正朝向
	local initialCFrame = CFrame.lookAt(position, targetPosition) * CFrame.Angles(0, math.rad(270), 0)
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
                
                local hp = model:GetAttribute('Health')
                local curHp = math.max(hp - self.config.ChangeHp, 0)
                model:SetAttribute('Health', curHp)
            end
        end
    end)
	
	-- 创建移动动画
	local targetCFrame = CFrame.lookAt(targetPosition, targetPosition + direction) * CFrame.Angles(0, math.rad(270), 0)
	
	-- 动画信息
	local tweenInfo = TweenInfo.new(
		self.config.Lifetime, -- 持续时间
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
	
	if self.config.Lifetime > 0 then
		-- 使用Debris服务作为备用销毁机制
		Debris:AddItem(wave, self.config.Lifetime + 1)
	end
end

return WaveAction