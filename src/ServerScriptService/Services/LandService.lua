print('LandService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local LandService = Knit.CreateService {
    Name = "LandService",
    Client = {
    }
}

function LandService.Client:Occupy(player, landName)
    Knit.GetService("SystemService"):UpdateIsLandOwner(player, landName)
    self:IntoIsLand(player, landName)
    return 10038
end

function LandService.Client:Pay(player, landName)
    local landData = GameConfig.TerrainType.IsLand[landName]
    if not landData then
        return 10042, landName
    end
    self:IntoIsLand(player, landName)

    return 10041, tostring(landData.Price)
end

function LandService.Client:IntoIsLand(player, landName)
    player:SetAttribute("CurAreaTemplate", landName)
    Knit.GetService("BoatAssemblingService"):StopBoat(player)
end

function LandService:KnitInit()
    print('LandService initialized')
end

function LandService:KnitStart()
    print('LandService started')
end

return LandService