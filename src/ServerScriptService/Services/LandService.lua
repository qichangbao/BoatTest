local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local IslandConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("IslandConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
local Players = game.Players

local LandService = Knit.CreateService {
    Name = "LandService",
    Client = {
        OccupyStart = Knit.CreateSignal(),
        OccupyFinish = Knit.CreateSignal(),
        OccupyFail = Knit.CreateSignal(),
        CreateIsland = Knit.CreateSignal(),
        RemoveIsland = Knit.CreateSignal(),
    }
}

local _allLand = {} -- 所有岛屿
local _occupingIslandsHandle = {}

-- 初始化固定岛屿
for _, data in ipairs(IslandConfig.IsLand) do
    _allLand[data.Name] = true
end

function LandService:GetAllLand()
    return _allLand
end

-- 客户端调用，玩家开始占领岛屿
function LandService.Client:StartOccupy(player, landName)
    local land = IslandConfig.FindIsLand(landName)
    if not land then
        return
    end

    self.OccupyStart:FireAll(player.Name, landName)
    Knit.GetService("TowerService"):SetIslandActive(landName, true, player.UserId)
    if _occupingIslandsHandle[landName] then
        pcall(task.cancel, _occupingIslandsHandle[landName])
        _occupingIslandsHandle[landName] = nil
    end
    _occupingIslandsHandle[landName] = task.delay(GameConfig.OccupyTime, function()
        self.Server:Occupy(player, landName)
    end)
end

-- 占领岛屿
function LandService:Occupy(player, landName)
    Knit.GetService("SystemService"):UpdateIsLandOwner(player, landName)
    self.Client:IntoIsLand(player, landName)
    self.Client.OccupyFinish:FireAll(player.UserId, player.Name, landName)
end

-- 占领失败
function LandService:OccupyFail(userId, landName)
    if _occupingIslandsHandle[landName] then
        pcall(task.cancel, _occupingIslandsHandle[landName])
        _occupingIslandsHandle[landName] = nil
    end

    local player = Players:GetPlayerByUserId(userId)
    if player then
        self.Client.OccupyFail:FireAll(userId, player.Name, landName)
    end
end

-- 客户端调用，付费登岛
function LandService.Client:Pay(player, landName)
    local land = IslandConfig.FindIsLand(landName)
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
    
    if not player.Character then
        return
    end
    local humanoid = player.Character:FindFirstChild('Humanoid')
    if humanoid then
        humanoid.Sit = false
    end
    local start = landName:find("_")
    if start then
        landName = landName:sub(1, start - 1)
    end
    Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 'info', 10049, landName)
    Interface.InitPlayerPos(player)
end

-- 客户端调用，玩家登船
function LandService.Client:PlayerToBoat(player)
    local boat = Interface.GetBoatByPlayerUserId(player.UserId)
    if not boat then
        return
    end

    Interface.PlayerToBoat(player, boat)
end

-- 创建岛屿
function LandService:CreateIsland(modelName, position, lifetime)
    local islandTemplate = ServerStorage:FindFirstChild(modelName)
    if not islandTemplate then
        return
    end
    local island = islandTemplate:Clone()
    if not Interface.CheckPosHasPart(position, island:GetExtentsSize()) then
        print("位置有物体，取消创建")
        island:Destroy()
        return
    end

    island.Name = string.format("%s_%s", LanguageConfig.Get(10082), tick())
    local pos = Interface.GetPartBottomPos(island, position)
    island:PivotTo(CFrame.new(pos))
    island.Parent = workspace
    _allLand[island.Name] = true

    self.Client.CreateIsland:FireAll(island.Name, lifetime)
    return island
end

function LandService:RemoveIsland(landName)
    local island = workspace:FindFirstChild(landName)
    if not island then
        return
    end

    _allLand[island.Name] = nil

    for _, child in ipairs(island:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Anchored = false
        end
    end

    task.delay(3, function()
        island:Destroy()
    end)

    self.Client.RemoveIsland:FireAll(landName)
end

function LandService:KnitInit()
end

function LandService:KnitStart()
end

return LandService