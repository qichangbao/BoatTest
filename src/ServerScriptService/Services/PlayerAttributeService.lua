local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

local AdminUserIds = {
	4803414780,
	7689724124,
}

local PlayerAttributeService = Knit.CreateService({
    Name = 'PlayerAttributeService',
    Client = {
        ChangeAttribute = Knit.CreateSignal(),
    },
})

-- 获取是否管理员
function PlayerAttributeService:IsAdmin(player)
	for _, v in ipairs(AdminUserIds) do
		if v == player.UserId then
			return true
		end
	end
	return false
end

function PlayerAttributeService:GetPlayerHealth(player)
    if player.Humanoid then
        return player.Humanoid.Health
    end
    return 0
end

function PlayerAttributeService.Client:GetPlayerHealth(player)
    return self.Server:GetPlayerHealth(player)
end

function PlayerAttributeService:ChangePlayerHealth(player, hp, maxHp)
    self.Client.ChangeAttribute:Fire(player, 'Health', math.max(hp, 0), maxHp)
end

function PlayerAttributeService:GetPlayerSpeed(player)
    if player.Humanoid then
        return player.Humanoid.WalkSpeed
    end
    return 0
end

function PlayerAttributeService.Client:GetPlayerSpeed(player)
    return self.Server:GetPlayerSpeed(player)
end

function PlayerAttributeService:ChangePlayerSpeed(player, speed, maxSpeed)
    self.Client.ChangeAttribute:Fire(player, 'Speed', math.max(speed, 0), maxSpeed)
end

-- 客户端调用，设置出生点
function PlayerAttributeService.Client:SetSpawnLocation(player, areaName)
    local spawnLocation = workspace:WaitForChild(areaName):WaitForChild("SpawnLocation")
    player.RespawnLocation = spawnLocation
    local DBService = Knit.GetService('DBService')
    DBService:Set(player.UserId, "SpawnLocation", areaName)
end

-- 客户端登陆时调用，获取玩家数据
function PlayerAttributeService.Client:GetLoginData(player)
    local data = {}
    data.Gold = player:GetAttribute("Gold")
    data.PlayerInventory = Knit.GetService('InventoryService'):GetPlayerInventory(player)
    data.isAdmin = self.Server:IsAdmin(player)
    data.IsLandOwners = Knit.GetService('SystemService'):GetIsLandOwner(player)
    return data
end

function PlayerAttributeService:KnitInit()
    local function playerAdded(player)
        print("PlayerAdded    ", player.Name)
        player.CharacterAdded:Connect(function(character)
            local boat = Interface.GetBoatByPlayerUserId(player.UserId)
            if boat then
                boat:Destroy()
            end
            character:SetAttribute("ModelType", "Player")
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CollisionGroup = "PlayerCollisionGroup"
                end
            end
        end)
        -- 设置玩家的幸运值
        player:SetAttribute("Lucky", 0)

        local DBService = Knit.GetService('DBService')
        DBService:PlayerAdded(player)
        Knit.GetService("RankService"):InitPlayerSailingData(player)
        -- 初始化重生点
        local areaName = DBService:Get(player.UserId, "SpawnLocation")
        local area = workspace:FindFirstChild(areaName) or workspace:FindFirstChild("奥林匹斯")
        local spawnLocation = area:WaitForChild("SpawnLocation")
        player.RespawnLocation = spawnLocation
        Interface.InitPlayerPos(player)

        -- 玩家登录时，查找是否有其他玩家支付的登岛费用，将其添加到玩家金币中
        local gold = DBService:Get(player.UserId, "Gold")
        local curGold = gold
        -- DBService:UpdatePayInfos(player.UserId, function(payInfos)
        --     for _, data in ipairs(payInfos) do
        --         curGold += data.price
        --     end
        --     return {}
        -- end)
        player:SetAttribute("Gold", curGold)
        if gold ~= curGold then
            DBService:Set(player.UserId, "Gold", curGold)
            Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 10048, tostring(curGold - gold))
        end
    
        player:GetAttributeChangedSignal('Gold'):Connect(function()
            DBService:Set(player.UserId, "Gold", player:GetAttribute("Gold"))
        end)
    
        local playerInventory = DBService:Get(player.UserId, "PlayerInventory") or {}
        Knit.GetService('InventoryService'):InitPlayerInventory(player, playerInventory)
    end

    local function playerRemoving(player)
		print("playerRemoving    ", player.Name)
        Knit.GetService("RankService"):RemovePlayerSailingData(player)
        local DBService = Knit.GetService('DBService')
        DBService:PlayerRemoving(player)
    end

	for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end

    Players.PlayerAdded:Connect(function(player)
        playerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        playerRemoving(player)
    end)
end

function PlayerAttributeService:KnitStart()
end

return PlayerAttributeService