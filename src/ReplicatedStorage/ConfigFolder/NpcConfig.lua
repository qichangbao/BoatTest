local LanguageConfig = require(script.Parent:WaitForChild("LanguageConfig"))

local NpcConfig ={
    NPC1 = {
        DialogText = LanguageConfig:Get(10024),
        Buttons = {
            Confirm = {
                Callback = "SetSpawnLocation"
            },
        }
    },
    NPC2 = {
        DialogText = LanguageConfig:Get(10024),
        Buttons = {
            Confirm = {
                Callback = "SetSpawnLocation"
            }
        }
    }
}

return NpcConfig