
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProfileService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ProfileService"):WaitForChild("ProfileService"))
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local dataTemplate = {
	Gold = 50,
	PlayerInventory = {},
}

local DBService = Knit.CreateService({
    Name = 'DBService',
    Client = {
        AdminRequest = Knit.CreateSignal()
    },
})

function DBService.Client:AdminRequest(player, action, ...)
    if RunService:IsStudio() then
        return self.Server:ProcessAdminRequest(player, action, ...)
    end

	return "非Studio环境，无法执行该操作"
end

function DBService:ProcessAdminRequest(player, action, userId, ...)
	if action == "GetData" then
		local data = {}
		for i, v in pairs(dataTemplate) do
			data[i] = self:GetToAllStore(userId, i)
		end
		return data
	elseif action == "SetData" then
		self:SetToAllStore(userId, ...)
		return "数据修改成功"
	end
end

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerProfile",
	dataTemplate
)

local Profiles = {}

function DBService:PlayerAdded(player)
	print("PlayerAdded")
	local userId = player.UserId
	if Profiles[userId] then
		return
	end

	local profileKey = "Player_"..userId
	local profile = ProfileStore:LoadProfileAsync(profileKey)
	if profile then
		profile:AddUserId(userId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[userId] = nil

			player:Kick()
		end)

		if not player:IsDescendantOf(Players) then
			profile:Release()
		else
			Profiles[userId] = profile
		end
	else
		player:Kick()
	end
	
	print(profile.Data)
	self:GiveStats(player)
end

function DBService:PlayerRemoving(player)
	if Profiles[player.UserId] then
		Profiles[player.UserId]:Release()
	end
end

function DBService:InitDataFromUserId(userId)
	if Profiles[userId] then
		return
	end

	local profileKey = "Player_"..userId
	local profile = ProfileStore:LoadProfileAsync(profileKey)
	if profile then
		profile:AddUserId(userId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[userId] = nil
		end)

		Profiles[userId] = profile
	end
end

local function getProfile(userId)
	return Profiles[userId]
end

-- getter/setter methods
function DBService:GetToAllStore(userId, key)
	self:InitDataFromUserId(userId)
	return self:Get(userId, key)
end

function DBService:SetToAllStore(userId, key, value)
	self:InitDataFromUserId(userId)
	return self:Set(userId, key, value)
end

function DBService:Get(userId, key)
	local profile = getProfile(userId)
	if not profile then
		return
	end

	return profile.Data[key]
end

function DBService:Set(userId, key, value)
	local profile = getProfile(userId)
	if not profile then
		return false
	end

	profile.Data[key] = value
	profile:Save()
	return true
end

function DBService:Update(userId, key, callback)
	local oldData = self:Get(userId, key)
	local newData = callback(oldData)

	self:Set(userId, key, newData)
end

function DBService:GiveStats(player)
	if not player or not player:IsA("Player") then
		warn("GiveStats function requires a valid player instance")
		return
	end

	local Leaderstats = Instance.new("Folder", player)
	Leaderstats.Name = "leaderstats"

	local gold = Instance.new("IntValue", Leaderstats)
	gold.Name = "Gold"
	gold.Value = self:Get(player.UserId, "Gold")
end

function DBService:KnitInit()
    print('DBService initialized')
end

function DBService:KnitStart()
    print('DBService started')
end

return DBService