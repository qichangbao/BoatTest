print("加载WaveAction")
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))

local WaveAction = {}
setmetatable(WaveAction, ActionBase)
WaveAction.__index = WaveAction

function WaveAction.new(config)
    local self = setmetatable(ActionBase.new(config), WaveAction)
    self.active = false
    return self
end

function WaveAction:Execute()
    ActionBase.Execute(self)

    print("执行WaveAction")
    local targetPosition = self.config.TargetPosition or Vector3.new(0, 0, -10)
    local size = self.config.Size or Vector3.new(10, 10, 10)
    local waveColor = self.config.Color or "Deep blue"
    
    self.active = true
    
    -- 生成单个体积波浪
    local wavePart = Instance.new("Part")
    wavePart.Size = size
    wavePart.Position = self.position
    wavePart.Anchored = false
    wavePart.BrickColor = BrickColor.new(waveColor)
    wavePart.Material = Enum.Material.Water
    wavePart.Transparency = 0.3
    wavePart.CanCollide = true
    wavePart.Parent = workspace
    
    self.wavePart = wavePart
    self.tween = nil
    
    -- 波浪运动逻辑
    local tweenService = game:GetService('TweenService')
    local tweenInfo = TweenInfo.new(
        self.lifetime,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        0,  -- 单次播放
        false,  -- reverses
        0  -- delayTime
    )
    
    self.tween = tweenService:Create(self.wavePart, tweenInfo, {
        Position = targetPosition
    })
    self.tween:Play()-- 添加碰撞检测

    wavePart.Touched:Connect(function(hit)
        if hit:FindFirstAncestorWhichIsA('Model') then
            local boatModel = hit:FindFirstAncestorWhichIsA('Model')
            if boatModel and boatModel.Name:find('PlayerBoat_') then
                local player = game:GetService('Players'):GetPlayerByUserId(tonumber(boatModel.Name:split('_')[2]))
                local health = require(game.ServerScriptService:WaitForChild('BoatFolder'):WaitForChild('BoatAttribute')):GetHealth(player)
                
                if health < 50 then
                    local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))
                    Knit.GetService('BoatAssemblingService'):DestroyBoat(player, boatModel)
                else
                    -- 穿透处理：暂时禁用碰撞
                    wavePart.CanCollide = false
                    wait(0.5)
                    wavePart.CanCollide = true
                end
            end
        end
    end)
end

function WaveAction:Destroy()
    ActionBase.Destroy(self)
    
    self.active = false
    if self.tween then
        self.tween:Cancel()
    end
    if self.wavePart then
        self.wavePart:Destroy()
    end
end

return WaveAction