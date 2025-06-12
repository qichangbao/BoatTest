local ActionBase = require(script.Parent:WaitForChild("ActionBase"))

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
    -- 生成单个体积波浪
    -- 创建带动态网格的波浪
    -- 通过RemoteEvent通知客户端生成特效
    local Knit = require(game.ReplicatedStorage:WaitForChild('Packages'):WaitForChild("Knit"):WaitForChild("Knit"))
    local TriggerService = Knit.GetService('TriggerService')
    TriggerService.Client.CreateWave:FireAll({
        Position = position,
        TargetPosition = targetPosition,
        Lifetime = self.config.Lifetime,
        ChangeHp = self.config.ChangeHp,
    })
end

return WaveAction