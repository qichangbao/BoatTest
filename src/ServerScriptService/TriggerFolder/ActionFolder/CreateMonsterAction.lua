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
    AIManager.new(self.config.MonsterName, self.config.Position):Start()
end

function CreateMonsterAction:Destroy()
    ActionBase.Destroy(self)
end

return CreateMonsterAction