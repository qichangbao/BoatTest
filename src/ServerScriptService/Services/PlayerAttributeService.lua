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
        ChangeGold = Knit.CreateSignal(),
    },
})

-- 客户端登陆时调用，获取是否管理员
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

-- 客户端登陆时调用，获取玩家金币
function PlayerAttributeService.Client:GetGold(player)
    return player:GetAttribute("Gold")
end

-- 客户端调用，设置出生点
function PlayerAttributeService.Client:SetSpawnLocation(player, areaName)
    local spawnLocation = workspace:WaitForChild(areaName):WaitForChild("SpawnLocation")
    player.RespawnLocation = spawnLocation
    local DBService = Knit.GetService('DBService')
    DBService:Set(player.UserId, "SpawnLocation", areaName)
end

function PlayerAttributeService:KnitInit()
    print('PlayerAttributeService initialized')

    local function playerAdded(player)
        print("PlayerAdded    ", player.Name)
        player.CharacterAdded:Connect(function(character)
            if not player.RespawnLocation then
                task.wait(1.5)
            end
            Interface.InitPlayerPos(player)
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

        local DBService = Knit.GetService('DBService')
        DBService:PlayerAdded(player)
        -- 初始化重生点
        local areaName = DBService:Get(player.UserId, "SpawnLocation")
        local area = workspace:FindFirstChild(areaName) or workspace:FindFirstChild("Land")
        local spawnLocation = area:WaitForChild("SpawnLocation")
        player.RespawnLocation = spawnLocation

        local gold = DBService:Get(player.UserId, "Gold")
        player:SetAttribute("Gold", gold)
        self.Client.ChangeGold:Fire(player, math.max(gold, 0))
    
        player:GetAttributeChangedSignal('Gold'):Connect(function()
            self:ChangeGold(player, player:GetAttribute('Gold'))
        end)
    
        local playerInventory = DBService:Get(player.UserId, "PlayerInventory") or {}
        Knit.GetService('InventoryService'):InitPlayerInventory(player, playerInventory)
    end

    local function playerRemoving(player)
		print("playerRemoving    ", player.Name)
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
    print('PlayerAttributeService started')
end

return PlayerAttributeService