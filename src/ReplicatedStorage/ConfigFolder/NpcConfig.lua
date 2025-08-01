local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

local NpcConfig ={
    ["Spawn"] = {
        [1] = {
            DialogText = LanguageConfig.Get(10024),
            Buttons = {
                Confirm = {
                    Visible = true,
                    Callback = "SetSpawnLocation"
                },
                Cancel = {
                    Visible = true,
                }
            },
        },
        [2] = {
            DialogText = LanguageConfig.Get(10043),
            Buttons = {
                Cancel = {
                    Visible = true,
                }
            },
        }
    },
}

return NpcConfig