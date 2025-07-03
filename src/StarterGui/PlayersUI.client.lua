local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
local Players = game:GetService('Players')
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'PlayersUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateMiddleFrame(_screenGui, LanguageConfig.Get(10033))

local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Size = UDim2.new(1, -20, 1, -20)
_scrollFrame.Position = UDim2.new(0, 10, 0, 10)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.Parent = _frame

local _childFrame = Instance.new('Frame')
_childFrame.Size = UDim2.new(0, 60, 0, 40)
_childFrame.AnchorPoint = Vector2.new(0, 0.5)
_childFrame.BackgroundColor3 = Color3.fromRGB(33, 150, 243)  -- 蓝色
_childFrame.BackgroundTransparency = 1
_childFrame.Visible = false
_childFrame.Parent = _screenGui

local _giftButton = Instance.new('TextButton')
_giftButton.Name = '_giftButton'
_giftButton.Size = UDim2.new(1, 0, 1, 0)
_giftButton.BackgroundColor3 = Color3.fromRGB(33, 150, 243)  -- 蓝色
_giftButton.Text = LanguageConfig.Get(10027)
_giftButton.Font = UIConfig.Font
_giftButton.TextScaled = true
_giftButton.TextColor3 = Color3.new(1, 1, 1)
_giftButton.Parent = _childFrame
UIConfig.CreateCorner(_giftButton)

_giftButton.MouseButton1Click:Connect(function()
    local userId = _childFrame:GetAttribute("PlayerId")
    Knit.GetController('UIController').ShowGiftUI:Fire(userId)
    _scrollFrame.ScrollingEnabled = false
end)

-- 玩家条目模板
local _playerTemplate = Instance.new('TextButton')
_playerTemplate.Name = '_playerTemplate'
_playerTemplate.Size = UDim2.new(0.95, 0, 0, 40)
_playerTemplate.Text = "PlayerName (ID:123)"
_playerTemplate.Font = UIConfig.Font
_playerTemplate.TextScaled = true
_playerTemplate.TextColor3 = Color3.new(1, 1, 1)
_playerTemplate.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
_playerTemplate.Visible = false
UIConfig.CreateCorner(_playerTemplate, UDim.new(0, 8))

-- 动态生成玩家列表
local function UpdatePlayerList()
    _screenGui.Enabled = true
    _childFrame.Visible = false
    for _, child in ipairs(_scrollFrame:GetChildren()) do
        if child:IsA('TextButton') then child:Destroy() end
    end
    
    local yPos = 0
    for _, player in ipairs(Players:GetPlayers()) do
        local entry = _playerTemplate:Clone()
        entry.Text = `{player.Name} (ID:{player.UserId})`
        entry.Position = UDim2.new(0, 0, 0, yPos)
        entry.Visible = true
        entry.Parent = _scrollFrame
        entry.MouseButton1Click:Connect(function()
            -- 根据条目位置动态定位
            local entryPosition = entry.AbsolutePosition
            local entrySize = entry.AbsoluteSize
            
            _childFrame.Position = UDim2.new(
                0,
                entryPosition.X - _childFrame.AbsoluteSize.X - 30,
                0,
                entryPosition.Y + entrySize.Y/2
            )
            _childFrame.Visible = true
            _childFrame:SetAttribute("PlayerId", player.UserId)
        end)
        yPos += entry.Size.Y.Offset + 10
    end
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    Knit.GetController('UIController').ShowPlayersUI:Connect(function()
        UpdatePlayerList()
    end)
    Knit.GetController('UIController').GiftUIClose:Connect(function()
        _scrollFrame.ScrollingEnabled = true
    end)
end):catch(warn)