local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local NPCConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("NpcConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

for _, land in pairs(workspace:GetChildren()) do
    if land:IsA("BasePart") and land.Name:match("Land") then
        for _, npc in pairs(land:GetChildren()) do
            if npc:IsA("Model") and npc.Name:match("NPC") then
                local config = NPCConfig[npc.Name]
                -- 先创建ProximityPrompt实例
                local HumanoidRootPart = npc:WaitForChild('HumanoidRootPart')
                local prompt = Instance.new('ProximityPrompt')
                prompt.HoldDuration = 0
                prompt.ActionText = '对话'
                prompt.ObjectText = npc.Name
                prompt.MaxActivationDistance = 20
                prompt.ClickablePrompt = true
                prompt.RequiresLineOfSight = false
                prompt.Parent = HumanoidRootPart
                
                -- 后绑定事件
                local NpcUI = Instance.new('ScreenGui')
                NpcUI.Name = 'NPC_Dialog_UI'
                NpcUI.ResetOnSpawn = false
                NpcUI.Enabled = false
                NpcUI.Parent = PlayerGui

                local Frame = Instance.new('Frame')
                Frame.AnchorPoint = Vector2.new(0.5, 0.5)
                Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
                Frame.Size = UDim2.new(0, 300, 0, 200)
                Frame.Parent = NpcUI

                local CloseButton = Instance.new('TextButton')
                CloseButton.Text = 'X'
                CloseButton.Size = UDim2.new(0, 30, 0, 30)
                CloseButton.Position = UDim2.new(1, -15, 0, -15)
                CloseButton.Parent = Frame
                local ConfirmButton = Instance.new('TextButton')
                ConfirmButton.AnchorPoint = Vector2.new(0.5, 0.5)
                ConfirmButton.Size = UDim2.new(0.2, 0, 0.2, 0)
                ConfirmButton.Position = UDim2.new(0.3, 0, 0.9, 0)
                ConfirmButton.TextSize = 18
                if config.Buttons.Confirm and config.Buttons.Confirm.Text then
                    ConfirmButton.Text = config.Buttons.Confirm.Text
                else
                    ConfirmButton.Text = LanguageConfig:Get(10002)
                end
                ConfirmButton.Parent = Frame
                local CancelButton = Instance.new('TextButton')
                CancelButton.AnchorPoint = Vector2.new(0.5, 0.5)
                CancelButton.Size = UDim2.new(0.2, 0, 0.2, 0)
                CancelButton.Position = UDim2.new(0.7, 0, 0.9, 0)
                CancelButton.TextSize = 18
                if config.Buttons.Cancel and config.Buttons.Cancel.Text then
                    CancelButton.Text = config.Buttons.Cancel.Text
                else
                    CancelButton.Text = LanguageConfig:Get(10003)
                end
                CancelButton.Parent = Frame
                
                local TextLabel = Instance.new('TextLabel')
                TextLabel.Text = config.DialogText
                TextLabel.AnchorPoint = Vector2.new(0, 0)
                TextLabel.Position = UDim2.new(0, 20, 0, 10)  -- 左缩进20像素
                TextLabel.Size = UDim2.new(0.8, 0, 0.7, 0)     -- 右侧留30像素边距
                TextLabel.TextSize = 18
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.TextYAlignment = Enum.TextYAlignment.Top
                TextLabel.TextTruncate = Enum.TextTruncate.None
                TextLabel.TextWrapped = true
                TextLabel.Parent = Frame
                local _connection
                local function CloseUI()
                    NpcUI.Enabled = false
                    -- 关闭时同步停止距离检测
                    if _connection then
                        _connection:Disconnect()
                    end
                end
                
                ConfirmButton.MouseButton1Click:Connect(function()
                    if config.Buttons.Confirm and config.Buttons.Confirm.Callback then
                        if config.Buttons.Confirm.Callback == 'SetSpawnLocation' then
                            Knit.GetService("PlayerAttributeService"):SetSpawnLocation(land.Name)
                        end
                    end
                    CloseUI()
                end)
                CancelButton.MouseButton1Click:Connect(function()
                    if config.Buttons.Cancel and config.Buttons.Cancel.Callback then
                    end
                    CloseUI()
                end)
                CloseButton.MouseButton1Click:Connect(function()
                    CloseUI()
                end)

                -- 修改后的ProximityPrompt监听
                prompt.Triggered:Connect(function(player)
                    if player == Players.LocalPlayer then
                        NpcUI.Enabled = true
                        
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