local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))

-- 初始化金币更新远程事件
local GOLD_UPDATE_RE_NAME = 'GoldUpdateEvent'
local goldEvent = ReplicatedStorage:FindFirstChild(GOLD_UPDATE_RE_NAME) or Instance.new('RemoteEvent')
goldEvent.Name = GOLD_UPDATE_RE_NAME
goldEvent.Parent = ReplicatedStorage

Players.PlayerAdded:Connect(function(player)
    local function setupCharacter(character)
        character:SetAttribute("Gold", 100)
        goldEvent:FireClient(player, 100)
    end

    -- 初始化已存在的角色
    if player.Character then
        setupCharacter(player.Character)
    else
        player.CharacterAdded:Connect(setupCharacter)
    end

    -- 初始化重生点
    player.RespawnLocation = Workspace.LandSpawnLocation
end)