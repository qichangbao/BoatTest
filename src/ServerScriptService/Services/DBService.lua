local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProfileService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ProfileService"):WaitForChild("ProfileService"))
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local DataStoreService = game:GetService("DataStoreService")
local SystemStore = DataStoreService:GetDataStore("SystemStore")

local _dataTemplate = {
	Gold = 50,	-- 金币
	PlayerInventory = {},	-- 背包
	SpawnLocation = "奥林匹斯",	-- 出生地
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerProfile",
	_dataTemplate
)

local DBService = Knit.CreateService({
    Name = 'DBService',
	Profiles = {},
    Client = {
    },
})

function DBService.Client:AdminRequest(player, action, userId, ...)
	local PlayerAttributeService = Knit.GetService("PlayerAttributeService")
    if PlayerAttributeService:IsAdmin(player) then
        return self.Server:ProcessAdminRequest(player, action, userId, ...)
    end

	return "不是管理员，无法执行该操作"
end

function DBService:GetPlayerSystemData(userId)
	local successful, data = pcall(function()
		return SystemStore:GetAsync("PlayerSystem_".. userId)
	end)
	if not successful then
		warn('无法连接数据库: SystemStore')
		return nil
	end

	return data
end

-- 客户端调用，获取玩家登陆时保存在数据库的数据，尽量只用于管理员在客户端操作数据库时调用
function DBService.Client:GetPlayerSystemData(player, targetUserId)
	if not targetUserId or type(targetUserId) ~= "number" then
		print("无效的用户ID")
		return nil
	end

	return self.Server:GetPlayerSystemData(targetUserId)
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
		for i, v in pairs(_dataTemplate) do
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

function DBService:SetPayInfos(userId, payInfos)
	task.spawn(function()
		local profileKey = "PayInfos_"..userId
		pcall(function()
			return SystemStore:SetAsync(profileKey, payInfos)
		end)
	end)
end

function DBService:UpdatePayInfos(userId, callback)
	task.spawn(function()
		local profileKey = "PayInfos_"..userId
		SystemStore:UpdateAsync(profileKey, function(oldData)
			return callback(oldData or {})
		end)
	end)
end

function DBService:PlayerAdded(player)
	local userId = player.UserId
	if self.Profiles[userId] then
		return
	end

	task.spawn(function()
		local loginData = {}
		loginData.Login = true
		loginData.LoginTime = os.time()
		loginData.JobId = game.JobId
		loginData.GameId = game.GameId
		pcall(function()
			return SystemStore:SetAsync("PlayerSystem_"..userId, loginData)
		end)
	end)

	local profileKey = "Player_"..userId
	local profile = ProfileStore:LoadProfileAsync(profileKey)
	if profile then
		profile:AddUserId(userId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			self.Profiles[userId] = nil

			player:Kick()
		end)

		if not player:IsDescendantOf(Players) then
			profile:Release()
		else
			self.Profiles[userId] = profile
		end
	else
		player:Kick()
	end
	
	self:GiveStats(player)
end

function DBService:PlayerRemoving(player)
	local userId = player.UserId
	local profileKey = "PlayerSystem_"..userId
	task.spawn(function()
		SystemStore:UpdateAsync(profileKey, function(oldData)
			oldData.Login = false
			return oldData
		end)
	end)

	if self.Profiles[userId] then
		self.Profiles[userId]:Release()
	end
end

function DBService:InitDataFromUserId(userId)
	if self.Profiles[userId] then
		return 1
	end

	local profileKey = "Player_"..userId
	local profile = ProfileStore:LoadProfileAsync(profileKey)
	if profile then
		profile:AddUserId(userId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			self.Profiles[userId] = nil
		end)

		self.Profiles[userId] = profile
	end
	return 0
end

function DBService:GetProfile(userId)
	return self.Profiles[userId]
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
			print("设置玩家金币", value)
			player:SetAttribute("Gold", value or 0)
		else
			self:Set(userId, key, value)
		end
	elseif key == "PlayerInventory" then
		Knit.GetService("InventoryService"):GetInventoryFromDBService(userId, value)
	end
	-- 初始化用户数据，确保用户数据存在，并且可以设置value
	self:InitDataFromUserId(userId)
	if key ~= "Gold" then
		return self:Set(userId, key, value)
	end
	return true
end

function DBService:Get(userId, key)
	local profile = self:GetProfile(userId)
	if not profile then
		return
	end

	return profile.Data[key]
end

function DBService:Set(userId, key, value)
	local profile = self:GetProfile(userId)
	if not profile then
		return false
	end

	profile.Data[key] = value
	profile:Save()
	print("数据已保存  ", userId, key, value)

	if key == "Gold" then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			player:FindFirstChild("leaderstats"):FindFirstChild("Gold").Value = value
		end
	end

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
end

function DBService:KnitStart()
end

return DBService