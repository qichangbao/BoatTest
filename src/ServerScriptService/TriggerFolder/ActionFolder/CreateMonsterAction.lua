print("加载CreateMonsterAction")
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

function CreateMonsterAction:Execute()
    ActionBase.Execute(self)

    print("执行CreateMonsterAction")
    local aiManager = AIManager.new(self.config.MonsterName, self.config.Position)
    aiManager:Start()

    local function MonsterDead()
        -- 执行死亡处理
        if self.destroyToResetCondition then
            if self.ResetConditionDelayTime[1] > 0 and self.ResetConditionDelayTime[2] > 0 then
                local delay = math.random(self.ResetConditionDelayTime[1], self.ResetConditionDelayTime[2])
                task.delay(delay, function()
                    self.condition:Reset()
                end)
            end
        end
        
        aiManager:SetState('Dead')
    end
    local character = aiManager.NPC
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    -- 监听部件移除事件
    character.ChildRemoved:Connect(function(child)
        if child == humanoidRootPart then
            print("HumanoidRootPart被移除")
            MonsterDead()
        end
    end)

    if aiManager.Humanoid then
        -- 监听死亡状态
        aiManager.Humanoid.Died:Connect(function()
            print("怪物死亡")
            MonsterDead()
        end)
    end
end

function CreateMonsterAction:Destroy()
    ActionBase.Destroy(self)
end

return CreateMonsterAction