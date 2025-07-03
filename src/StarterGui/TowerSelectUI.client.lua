local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local TowerConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("TowerConfig"))
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local _screenGui = Instance.new("ScreenGui")
_screenGui.Name = "TowerSelectUI_GUI"
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = playerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateSmallFrame(_screenGui, LanguageConfig.Get(10077))

-- 箭塔选择区域
local _selectionArea = Instance.new("Frame")
_selectionArea.Name = "SelectionArea"
_selectionArea.Size = UDim2.new(1, -20, 1, -20)
_selectionArea.Position = UDim2.new(0, 10, 0, 10)
_selectionArea.BackgroundTransparency = 1
_selectionArea.Parent = _frame

-- 创建箭塔选项
local function createSelectItem(selectedIsland, index, callFunc)
    _selectionArea:ClearAllChildren()

    local _yOffset = 0
    for towerType, towerData in pairs(TowerConfig) do
        -- 箭塔选项框架
        local towerOption = Instance.new("Frame")
        towerOption.Name = "TowerOption_" .. towerType
        towerOption.Size = UDim2.new(1, 0, 0, 80)
        towerOption.Position = UDim2.new(0, 0, 0, _yOffset)
        towerOption.BackgroundColor3 = Color3.fromRGB(73, 80, 87)
        towerOption.Parent = _selectionArea
        UIConfig.CreateCorner(towerOption, UDim.new(0, 8))
        
        -- 箭塔信息
        local towerInfo = Instance.new("TextLabel")
        towerInfo.Name = "TowerInfo"
        towerInfo.Size = UDim2.new(0.7, 0, 0, 30)
        towerInfo.Position = UDim2.new(0, 15, 0, 10)
        towerInfo.BackgroundTransparency = 1
        towerInfo.Text = towerData.ModelName
        towerInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
        towerInfo.TextScaled = true
        towerInfo.Font = UIConfig.Font
        towerInfo.TextXAlignment = Enum.TextXAlignment.Left
        towerInfo.Parent = towerOption
        
        -- 箭塔属性
        local towerStats = Instance.new("TextLabel")
        towerStats.Name = "TowerStats"
        towerStats.Size = UDim2.new(0.7, 0, 0, 25)
        towerStats.Position = UDim2.new(0, 15, 0, 50)
        towerStats.BackgroundTransparency = 1
        towerStats.Text = LanguageConfig.Get(10073) .. string.format(":%d", towerData.Damage)
        towerStats.TextColor3 = Color3.fromRGB(200, 200, 200)
        towerStats.TextScaled = true
        towerStats.Font = UIConfig.Font
        towerStats.TextXAlignment = Enum.TextXAlignment.Left
        towerStats.Parent = towerOption
        
        -- 购买按钮
        local buyButton = Instance.new("TextButton")
        buyButton.Name = "BuyButton"
        buyButton.Size = UDim2.new(0, 100, 0, 50)
        buyButton.Position = UDim2.new(1, -115, 0.5, 0)
        buyButton.AnchorPoint = Vector2.new(0, 0.5)
        buyButton.Text = string.format("%d金币\n购买", towerData.Price)
        buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyButton.TextScaled = true
        buyButton.Font = UIConfig.Font
        buyButton.Parent = towerOption
        UIConfig.CreateCorner(buyButton, UDim.new(0, 6))
        
        -- 检查金币是否足够
        if ClientData.Gold >= towerData.Price then
            buyButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
            buyButton.Active = true
            
            -- 购买点击事件
            buyButton.MouseButton1Click:Connect(function()
                Knit.GetService('IslandManageService'):BuyTower(selectedIsland, towerType, index):andThen(function(success, tipId)
                    Knit.GetController('UIController').ShowTip:Fire(tipId)
                    if success then
                        _screenGui.Enabled = false
                        if callFunc then
                            callFunc()
                        end
                    else
                    end
                end)
            end)
        else
            buyButton.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
            buyButton.Active = false
            -- 购买点击事件
            buyButton.MouseButton1Click:Connect(function()
                Knit.GetController('UIController').ShowTip:Fire(10056)
            end)
        end
        
        _yOffset = _yOffset + 90
    end

    -- 设置选择区域的内容大小
    _selectionArea.Size = UDim2.new(1, -20, 0, _yOffset)

    -- 如果内容超出对话框高度，调整对话框大小
    if _yOffset > 240 then
        _frame.Size = UDim2.new(0, 500, 0, math.min(_yOffset + 110, 500))
    end
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').ShowTowerSelectUI:Connect(function(selectedIsland, index, callFunc)
        _screenGui.Enabled = true
        createSelectItem(selectedIsland, index, callFunc)
    end)
end)