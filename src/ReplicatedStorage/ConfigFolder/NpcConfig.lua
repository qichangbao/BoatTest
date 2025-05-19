local LanguageConfig = require(script.Parent:WaitForChild("LanguageConfig"))

local NpcConfig ={
    ["Spawn"] = {
        DialogText = LanguageConfig:Get(10024),
        Buttons = {
            Confirm = {
                Callback = "SetSpawnLocation"
            },
        }
    },
}

return NpcConfig