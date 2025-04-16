print("加载WaveAction")
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))

local WaveAction = {}
setmetatable(WaveAction, ActionBase)
WaveAction.__index = WaveAction

function WaveAction.new(config)
    local self = setmetatable(ActionBase.new(config), WaveAction)
    return self
end

function WaveAction:Execute()
    ActionBase.Execute(self)
    print("执行WaveAction")
    
    -- 生成单个体积波浪
    -- 创建带动态网格的波浪
    -- 通过RemoteEvent通知客户端生成特效
    local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))
    local TriggerService = Knit.GetService('TriggerService')
    TriggerService.Client.CreateWave:FireAll({
        Position = self.config.Position,
        Size = self.config.Size,
        TargetPosition = self.config.TargetPosition,
        Lifetime = self.config.Lifetime,
        ChangeHp = self.config.ChangeHp,
    })
end

function WaveAction:Destroy()
    ActionBase.Destroy(self)

    if self.tween then
        self.tween:Cancel()
    end
    if self.wavePart then
        self.wavePart:Destroy()
    end
    if self.particles then
        self.particles:Destroy()
    end
end

return WaveAction