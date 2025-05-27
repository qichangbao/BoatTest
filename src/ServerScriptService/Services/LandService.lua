print('LandService.lua loaded')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

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
    local land = GameConfig.FindIsLand(landName)
    if not land then
        return 10042, landName
    end

    local gold = tonumber(player:GetAttribute("Gold"))
    local price = tonumber(land.Price or 0)
    if gold < price then
        return 10044
    end

    player:SetAttribute("Gold", gold - price)
    self:IntoIsLand(player, landName)
    Knit.GetService("SystemService"):AddGoldFromIsLandPay(player.Name, landName, price)

    return 10041, tostring(price)
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