local ActionBase = require(script.Parent:WaitForChild("ActionBase"))
local AIManager = require(game:WaitForChild('ServerScriptService'):WaitForChild('AIManagerFolder'):WaitForChild("AIManager"))

local CreateMonsterAction = {}
setmetatable(CreateMonsterAction, ActionBase)
CreateMonsterAction.__index = CreateMonsterAction

function CreateMonsterAction.new(config, condition)
    local self = setmetatable(ActionBase.new(config, condition), CreateMonsterAction)
    self.destroyToResetCondition = config.DestroyToResetCondition or false
    self.ResetConditionDelayTime = config.ResetConditionDelayTime or {0, 0}

    return self
end

function CreateMonsterAction:Execute(data)
    ActionBase.Execute(self)

    -- 确定宝箱生成位置
    local position = self.position
    if self.config.UsePlayerPosition and self.config.PositionOffset and data and data.Player and data.Player.Character then
        local player = data.Player
        local frame = player.Character:GetPivot()
        position = frame.Position
        local baseOffset = frame.LookVector * self.config.PositionOffset -- 船头前方偏移
        
        -- 添加小范围随机偏移 (-5到5米的随机范围)
        local randomX = math.random(-100, 100)
        local randomZ = math.random(-100, 100)
        local randomOffset = Vector3.new(randomX, 1.5, randomZ)
        
        self.position = Vector3.new(position.X + baseOffset.X + randomOffset.X, randomOffset.Y, position.Z + baseOffset.Z + randomOffset.Z)
    end

    print("执行CreateMonsterAction")
    local aiManager = AIManager.new(self.config.MonsterName, self.position)
    if not aiManager then
        return
    end
    aiManager:Start()

    local function MonsterDead()
        -- 执行死亡处理
        if self.destroyToResetCondition then
            if self.ResetConditionDelayTime[1] > 0 and self.ResetConditionDelayTime[2] > 0 then
                local delay = math.random(self.ResetConditionDelayTime[1], self.ResetConditionDelayTime[2])
                task.delay(delay, function()
                    self.condition:Reset(data.Player)
                end)
            end
        end
        
        aiManager:SetState('Dead')
    end

    if aiManager.Humanoid then
        -- 监听死亡状态
        aiManager.Humanoid.Died:Connect(function()
            print("怪物死亡")
            MonsterDead()
        end)
    end
end

return CreateMonsterAction