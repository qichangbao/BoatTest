print('LandService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local LandService = Knit.CreateService {
    Name = "LandService",
    Client = {
    }
}

-- 客户端调用，占领岛屿
function LandService.Client:Occupy(player, landName)
    Knit.GetService("SystemService"):UpdateIsLandOwner(player, landName)
    self:IntoIsLand(player, landName)
    return 10038
end

-- 客户端调用，付费登岛
function LandService.Client:Pay(player, landName)
    local landData = Interface.FindIsLand(landName)
    if not landData then
        return 10042, landName
    end

    local gold = tonumber(player:GetAttribute("Gold"))
    local Price = tonumber(Interface.FindIsLand(landName).Price)
    if gold < Price then
        return 10044
    end

    player:SetAttribute("Gold", gold - Price)
    self:IntoIsLand(player, landName)
    Knit.GetService("SystemService"):AddGoldFromIsLandPay(landName, Price)

    return 10041, tostring(landData.Price)
end

-- 客户端调用，登岛
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