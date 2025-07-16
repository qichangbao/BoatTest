local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

-- 购买复活
function PlayerAttributeService:BuyRevive(player)
    Knit.GetService("PurchaseService"):BuyRevive(player)
end

function PlayerAttributeService:PurchaseRevive(player)
    local position = player.Character:GetPivot().Position
    player:SetAttribute("RevivePos", position)
    -- 重新加载角色（复活）
    player:LoadCharacter()
end

-- 拒绝复活（正常重生）
function PlayerAttributeService:DeclineRevive(player)
    -- 正常重生
    player:LoadCharacter()
end

-- 客户端接口：购买复活
function PlayerAttributeService.Client:BuyRevive(player)
    return self.Server:BuyRevive(player)
end

-- 客户端接口：拒绝复活
function PlayerAttributeService.Client:DeclineRevive(player)
    return self.Server:DeclineRevive(player)
end

-- 客户端调用，设置出生点
function PlayerAttributeService.Client:SetSpawnLocation(player, areaName)
    local spawnLocation = workspace:FindFirstChild(areaName):FindFirstChild("SpawnLocation")
    if spawnLocation then
        player.RespawnLocation = spawnLocation
    end
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
        Knit.GetService('DBService'):PlayerAdded(player)
        Knit.GetService("RankService"):InitPlayerSailingData(player)
        
        player.CharacterAdded:Connect(function(character)
            local boat = Interface.GetBoatByPlayerUserId(player.UserId)
            if boat then
                boat:Destroy()
            end
            character:SetAttribute("ModelType", "Player")
            
            -- 移除Roblox自带的ForceField保护光环效果
            local forceField = character:FindFirstChild("ForceField")
            if forceField then
                forceField:Destroy()
            end
            
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CollisionGroup = "PlayerCollisionGroup"
                end
            end

            local revivePos = player:GetAttribute("RevivePos")
            if revivePos then
                task.wait(0.1)
                local boatName = player:GetAttribute("BoatName")
                Knit.GetService("BoatAssemblingService"):AssembleBoat(player, boatName, revivePos)
            else
                Interface.InitPlayerPos(player)
            end
            player:SetAttribute("RevivePos", nil)
        end)

        -- 设置玩家的幸运值
        player:SetAttribute("Lucky", 0)

        -- 玩家登录时，查找是否有其他玩家支付的登岛费用，将其添加到玩家金币中
        local gold = Knit.GetService('DBService'):Get(player.UserId, "Gold")
        local curGold = gold
        -- DBService:UpdatePayInfos(player.UserId, function(payInfos)
        --     for _, data in ipairs(payInfos) do
        --         curGold += data.price
        --     end
        --     return {}
        -- end)
        player:SetAttribute("Gold", curGold)
        if gold ~= curGold then
            Knit.GetService('DBService'):Set(player.UserId, "Gold", curGold)
            Knit.GetService("SystemService"):SendSystemMessageToSinglePlayer(player, 10048, tostring(curGold - gold))
        end
    
        player:GetAttributeChangedSignal('Gold'):Connect(function()
            local playerGold = player:GetAttribute("Gold")
            Knit.GetService('DBService'):Set(player.UserId, "Gold", playerGold)
        end)
    
        local playerInventory = Knit.GetService('DBService'):Get(player.UserId, "PlayerInventory") or {}
        Knit.GetService('InventoryService'):InitPlayerInventory(player, playerInventory)
        -- 初始化重生点
        local areaName = Knit.GetService('DBService'):Get(player.UserId, "SpawnLocation")
        local area = workspace:FindFirstChild(areaName) or workspace:FindFirstChild("奥林匹斯")
        local spawnLocation = area:WaitForChild("SpawnLocation")
        player.RespawnLocation = spawnLocation
        
        player:LoadCharacter()
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

    -- 存储玩家上次受到水中伤害的时间
    local playerWaterDamageTime = {}
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        for _, player in Players:GetPlayers() do
            if not player.Character or not player.Character:FindFirstChild("Humanoid") then
                playerWaterDamageTime[player.UserId] = nil
                continue
            end
            
            local humanoid = player.Character.Humanoid
            local currentState = humanoid:GetState()
            
            -- 检测是否在游泳状态
            if currentState == Enum.HumanoidStateType.Swimming then
                local lastDamageTime = playerWaterDamageTime[player.UserId] or 0
                
                -- 每秒造成一次伤害
                if currentTime - lastDamageTime >= 1 then
                    humanoid:TakeDamage(10)
                    playerWaterDamageTime[player.UserId] = currentTime
                    print(player.Name .. " 在水中受到10点伤害")
                end
            else
                -- 玩家不在水中时，重置伤害计时
                playerWaterDamageTime[player.UserId] = nil
            end
        end
    end)
end

function PlayerAttributeService:KnitStart()
end

return PlayerAttributeService