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
    local part = Instance.new("Part")
    part.Size = self.config.Size or Vector3.new(5,5,5)
    part.Position = self.config.Position or Vector3.new(0,10,0)
    part.Anchored = true
    part.BrickColor = BrickColor.new(self.config.Color or "Bright blue")
    part.Material = Enum.Material.Neon
    part.Transparency = self.config.Transparency or 0.5
    part.Parent = workspace
    
    if self.config.Lifetime then
        delay(self.config.Lifetime, function()
            part:Destroy()
        end)
    end
    
    return part
end

return CreatePartAction