local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local NPCConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("NpcConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

local _NpcUI = Instance.new('ScreenGui')
_NpcUI.Name = 'NpcDialogUI_Gui'
_NpcUI.Enabled = false
_NpcUI.Parent = PlayerGui

local _Frame = Instance.new('Frame')
_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
_Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_Frame.Size = UDim2.new(0, 300, 0, 200)
_Frame.Parent = _NpcUI

local _CloseButton = Instance.new('TextButton')
_CloseButton.Text = 'X'
_CloseButton.Size = UDim2.new(0, 30, 0, 30)
_CloseButton.Position = UDim2.new(1, -15, 0, -15)
_CloseButton.Parent = _Frame
local _ConfirmButton = Instance.new('TextButton')
_ConfirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
_ConfirmButton.Size = UDim2.new(0.2, 0, 0.2, 0)
_ConfirmButton.Position = UDim2.new(0.3, 0, 0.9, 0)
_ConfirmButton.TextSize = 18
_ConfirmButton.Parent = _Frame
local _CancelButton = Instance.new('TextButton')
_CancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
_CancelButton.Size = UDim2.new(0.2, 0, 0.2, 0)
_CancelButton.Position = UDim2.new(0.7, 0, 0.9, 0)
_CancelButton.TextSize = 18
_CancelButton.Parent = _Frame

local _TextLabel = Instance.new('TextLabel')
_TextLabel.AnchorPoint = Vector2.new(0, 0)
_TextLabel.Position = UDim2.new(0, 20, 0, 10)  -- 左缩进20像素
_TextLabel.Size = UDim2.new(0.8, 0, 0.7, 0)     -- 右侧留30像素边距
_TextLabel.TextSize = 18
_TextLabel.TextXAlignment = Enum.TextXAlignment.Left
_TextLabel.TextYAlignment = Enum.TextYAlignment.Top
_TextLabel.TextTruncate = Enum.TextTruncate.None
_TextLabel.TextWrapped = true
_TextLabel.Parent = _Frame
local _connection
local function CloseUI()
    _NpcUI.Enabled = false
    -- 关闭时同步停止距离检测
    if _connection then
        _connection:Disconnect()
    end
end
_CloseButton.MouseButton1Click:Connect(function()
    CloseUI()
end)

-- 等待所有模型加载完成
local ContentProvider = game:GetService("ContentProvider")
while ContentProvider.RequestQueueSize > 0 do
    task.wait(1)
end

for _, land in pairs(workspace:GetChildren()) do
    if land:IsA("BasePart") and land.Name:match("Land") then
        for _, npc in pairs(land:GetChildren()) do
            if npc:IsA("Model") and npc.Name:match("NPC") then
                local config = NPCConfig[npc.Name]
                -- 先创建ProximityPrompt实例
                local HumanoidRootPart = npc:WaitForChild('HumanoidRootPart')
                local prompt = HumanoidRootPart:FindFirstChild("ProximityPrompt")
                if not prompt then
                    prompt = Instance.new('ProximityPrompt')
                    prompt.Name = 'ProximityPrompt'
                    prompt.HoldDuration = 0
                    prompt.ActionText = '对话'
                    prompt.ObjectText = npc.Name
                    prompt.MaxActivationDistance = 20
                    prompt.ClickablePrompt = true
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = HumanoidRootPart
                end

                -- 修改后的ProximityPrompt监听
                prompt.Triggered:Connect(function(player)
                    if player == Players.LocalPlayer then
                        _NpcUI.Enabled = true
                        if config.Buttons.Confirm and config.Buttons.Confirm.Text then
                            _ConfirmButton.Text = config.Buttons.Confirm.Text
                        else
                            _ConfirmButton.Text = LanguageConfig:Get(10002)
                        end
                        if config.Buttons.Cancel and config.Buttons.Cancel.Text then
                            _CancelButton.Text = config.Buttons.Cancel.Text
                        else
                            _CancelButton.Text = LanguageConfig:Get(10003)
                        end
                        _TextLabel.Text = config.DialogText
                        
                        _ConfirmButton.MouseButton1Click:Connect(function()
                            if config.Buttons.Confirm and config.Buttons.Confirm.Callback then
                                if config.Buttons.Confirm.Callback == 'SetSpawnLocation' then
                                    Knit.GetService("PlayerAttributeService"):SetSpawnLocation(land.Name)
                                end
                            end
                            CloseUI()
                        end)
                        _CancelButton.MouseButton1Click:Connect(function()
                            if config.Buttons.Cancel and config.Buttons.Cancel.Callback then
                            end
                            CloseUI()
                        end)
                        
                        -- 启动距离检测循环
                        _connection = game:GetService('RunService').Heartbeat:Connect(function()
                            local playerPos = player.Character and player.Character:FindFirstChild('HumanoidRootPart').Position
                            local npcPos = HumanoidRootPart.Position
                            
                            if playerPos and npcPos then
                                local distance = (playerPos - npcPos).Magnitude
                                if distance > prompt.MaxActivationDistance then
                                    CloseUI()
                                end
                            else
                                CloseUI()
                            end
                        end)
                    end
                end)
            end
        end
    end
end