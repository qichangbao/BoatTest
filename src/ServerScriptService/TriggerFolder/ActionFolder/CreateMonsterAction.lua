print("加载CreateMonsterAction")
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))
local AIManager = require(game:WaitForChild('ServerScriptService'):WaitForChild('AIManagerFolder'):WaitForChild("AIManager"))

local CreateMonsterAction = {}
setmetatable(CreateMonsterAction, ActionBase)
CreateMonsterAction.__index = CreateMonsterAction

function CreateMonsterAction.new(config)
    local self = setmetatable(ActionBase.new(config), CreateMonsterAction)
    return self
end

function CreateMonsterAction:Execute()
    ActionBase.Execute(self)

    print("执行CreateMonsterAction")
    self.aiManager = AIManager.new(self.config.MonsterName, self.config.Position)
    self.aiManager:Start()

    if self.aiManager.Humanoid then
        -- 监听死亡状态
        self.aiManager.Humanoid.Died:Connect(function()
            print("NPC死亡")
            self.aiManager:SetState('Dead')
            task.wait(10)
    
            if self.aiManager then
                self.aiManager:Destroy()
                self.aiManager = nil
            end
        end)
    end
end

function CreateMonsterAction:Destroy()
    ActionBase.Destroy(self)
end

return CreateMonsterAction