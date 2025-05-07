local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local AdminUserIds = {
	4803414780,
	7689724124,
}

local PlayerAttributeService = Knit.CreateService({
    Name = 'PlayerAttributeService',
    Client = {
        ChangeAttribute = Knit.CreateSignal(),
        ChangeGold = Knit.CreateSignal(),
    },
})

function PlayerAttributeService.Client:IsAdmin(player)
	for i, v in ipairs(AdminUserIds) do
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

function PlayerAttributeService:ChangeGold(player, gold)
    Knit.GetService('DBService'):Set(player.UserId, "Gold", math.max(gold, 0))
    self.Client.ChangeGold:Fire(player, math.max(gold, 0))
end

function PlayerAttributeService.Client:SetSpawnLocation(player, spawnLocation)
    local DBService = Knit.GetService('DBService')
    DBService:Set(player.UserId, "SpawnLocation", spawnLocation)
end

function PlayerAttributeService:KnitInit()
    print('PlayerAttributeService initialized')

    local function playerAdded(player)
        local DBService = Knit.GetService('DBService')
        DBService:PlayerAdded(player)
        -- 初始化重生点
        local areaName = DBService:Get(player.UserId, "SpawnLocation")
        local spawnLocation = workspace:WaitForChild(areaName):WaitForChild("SpawnLocation")
        player.RespawnLocation = spawnLocation

        player.CharacterAdded:Connect(function(character)
            local boat = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface")).GetBoatByPlayerUserId(player.UserId)
            if boat then
                boat:Destroy()
            end
            character:SetAttribute("ModelType", "Player")
        end)
    
        player:GetAttributeChangedSignal('Gold'):Connect(function()
            self:ChangeGold(player, player:GetAttribute('Gold'))
        end)

        local gold = DBService:Get(player.UserId, "Gold")
        player:SetAttribute("Gold", gold)
    
        local playerInventory = DBService:Get(player.UserId, "PlayerInventory") or {}
        Knit.GetService('InventoryService'):InitPlayerInventory(player, playerInventory)
    end

    local function playerRemoving(player)
		print("playerRemoving    ", player.Name)
        Knit.GetService('DBService'):PlayerRemoving(player)
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
    print('PlayerAttributeService started')
end

return PlayerAttributeService