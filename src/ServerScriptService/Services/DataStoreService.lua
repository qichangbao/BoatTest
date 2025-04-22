
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProfileService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ProfileService"):WaitForChild("ProfileService"))
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local DataStoreService = Knit.CreateService({
    Name = 'DataStoreService',
    Client = {
    },
})

local dataTemplate = {
	Gold = 50,
	PlayerInventory = {},
	-- 已移除废弃的PlayerAttribute字段
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerProfile",
	dataTemplate
)

local Profiles = {}

function DataStoreService:PlayerAdded(player)
	print("PlayerAdded")
	local profile = ProfileStore:LoadProfileAsync("Player_"..player.UserId)
	if profile then
		-- -- 迁移旧数据
		-- if profile.Data.PlayerAttribute then
		-- 	profile.Data.PlayerAttribute = nil
		-- 	profile:Save()
		-- end
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil

			player:Kick()
		end)

		if not player:IsDescendantOf(Players) then
			profile:Release()
		else
			Profiles[player] = profile
		end
	else
		player:Kick()
	end
	
	print(profile.Data)
	self:GiveStats(player)
end

function DataStoreService:PlayerRemoving(player)
	if Profiles[player] then
		Profiles[player]:Release()
	end
end

local function getProfile(player)
	assert(Profiles[player], string.format("Profile does not exist for %s", player.UserId))

	return Profiles[player]
end

-- getter/setter methods
function DataStoreService:Get(player, key)
	local profile = getProfile(player)
	assert(profile.Data[key], string.format("Profile does not exist for %s", key))

	return profile.Data[key]
end

function DataStoreService:Set(player, key, value)
	local profile =  getProfile(player)
	assert(profile.Data[key], string.format("Profile does not exist for %s", key))

	assert(type(profile.Data[key]) == type(value))

	profile.Data[key] = value
end

function DataStoreService:Update(player, key, callback)
	local oldData = self:Get(player, key)
	local newData = callback(oldData)

	self:Set(player, key, newData)
end

function DataStoreService:GiveStats(player)
	if not player or not player:IsA("Player") then
		warn("GiveStats function requires a valid player instance")
		return
	end

	local Leaderstats = Instance.new("Folder", player)
	Leaderstats.Name = "leaderstats"

	local gold = Instance.new("IntValue", Leaderstats)
	gold.Name = "Gold"
	gold.Value = self:Get(player, "Gold")
end

function DataStoreService:KnitInit()
    print('DataStoreService initialized')
end

function DataStoreService:KnitStart()
    print('DataStoreService started')
end

return DataStoreService