local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProfileService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ProfileService"):WaitForChild("ProfileService"))
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))

local dataTemplate = {
	Gold = 50,
	PlayerInventory = {},
	SpawnLocation = "Land",
}

local DBService = Knit.CreateService({
    Name = 'DBService',
    Client = {
    },
})

function DBService.Client:AdminRequest(player, action, userId, ...)
	local PlayerAttributeService = Knit.GetService("PlayerAttributeService")
    if PlayerAttributeService.Client:IsAdmin(player) then
        return self.Server:ProcessAdminRequest(player, action, userId, ...)
    end

	return "不是管理员，无法执行该操作"
end

function DBService:ProcessAdminRequest(player, action, userId, ...)
	if not userId or type(userId) ~= "number" then
		return "无效的用户ID"
	end

	if not action or type(action) ~= "string" then
		return "无效的操作"
	end
	
	if action == "GetData" then
		local data = {}
		local statu = 0
		for i, v in pairs(dataTemplate) do
			data[i], statu = self:GetToAllStore(userId, i)
		end
		return data, statu
	elseif action == "SetData" then
		if self:SetToAllStore(userId, ...) then
			return "数据更新成功"
		end
		return "找不到用户数据"
	end
end

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerProfile",
	dataTemplate
)

local Profiles = {}

function DBService:PlayerAdded(player)
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
	
	self:GiveStats(player)
end

function DBService:PlayerRemoving(player)
	if Profiles[player.UserId] then
		Profiles[player.UserId]:Release()
	end
end

function DBService:InitDataFromUserId(userId)
	if Profiles[userId] then
		return 1
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
	return 0
end

local function getProfile(userId)
	return Profiles[userId]
end

-- getter/setter methods
function DBService:GetToAllStore(userId, key)
	local statu = self:InitDataFromUserId(userId)
	return self:Get(userId, key), statu
end

function DBService:SetToAllStore(userId, key, value)
	if key == "Gold" then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			player:SetAttribute("Gold", value)
		end
	elseif key == "PlayerInventory" then
		Knit.GetService("InventoryService"):GetInventoryFromDBService(userId, value)
	end
	-- 初始化用户数据，确保用户数据存在，并且可以设置value
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