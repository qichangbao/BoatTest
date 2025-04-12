print("加载CreatePartAction")
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))

local CreatePartAction = {}
setmetatable(CreatePartAction, ActionBase)
CreatePartAction.__index = CreatePartAction

function CreatePartAction.new(config)
    local self = setmetatable(ActionBase.new(config), CreatePartAction)
    return self
end

function CreatePartAction:Execute()
    ActionBase.Execute(self)

    print("执行CreatePartAction")
    self.part = Instance.new("Part")
    self.part.Size = self.config.Size or Vector3.new(5,5,5)
    self.part.Position = self.position
    self.part.Anchored = true
    self.part.BrickColor = BrickColor.new(self.config.Color or "Bright blue")
    self.part.Material = Enum.Material.Neon
    self.part.Transparency = self.config.Transparency or 0.5
    self.part.Parent = workspace
end

function CreatePartAction:Destroy()
    ActionBase.Destroy(self)
    
    if self.part then
        self.part:Destroy()
    end
end

return CreatePartAction