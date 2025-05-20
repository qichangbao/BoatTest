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

-- 禁用背景点击
local _blocker = Instance.new("TextButton")
_blocker.Size = UDim2.new(1, 0, 1, 0)
_blocker.BackgroundTransparency = 1
_blocker.Text = ""
_blocker.Parent = _screenGui

-- 新增模态背景
local modalFrame = Instance.new("Frame")
modalFrame.Size = UDim2.new(1, 0, 1, 0)
modalFrame.BackgroundTransparency = 0.5
modalFrame.BackgroundColor3 = Color3.new(0, 0, 0)
modalFrame.Parent = _screenGui

local _frame = Instance.new('Frame')
_frame.Size = UDim2.new(0, 400, 0, 300)
_frame.Position = UDim2.new(0.5, 0, 0.5, 0)
_frame.AnchorPoint = Vector2.new(0.5, 0.5)
_frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
_frame.BackgroundTransparency = 0.1
_frame.Parent = _screenGui

-- 标题栏
local _titleBar = Instance.new('Frame')
_titleBar.Size = UDim2.new(1, 0, 0.1, 0)
_titleBar.Position = UDim2.new(0, 0, 0, 0)
_titleBar.BackgroundColor3 = Color3.fromRGB(103, 80, 164)
_titleBar.Parent = _frame

local _titleLabel = Instance.new('TextLabel')
_titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
_titleLabel.Position = UDim2.new(0.1, 0, 0, 0)
_titleLabel.Text = LanguageConfig:Get(10033)
_titleLabel.Font = UIConfig.Font
_titleLabel.TextSize = 20
_titleLabel.TextColor3 = Color3.new(1, 1, 1)
_titleLabel.BackgroundTransparency = 1
_titleLabel.Parent = _titleBar

-- 关闭按钮
local _closeButton = UIConfig.CreateCloseButton(function()
    _screenGui.Enabled = false
end)
_closeButton.Position = UDim2.new(1, -UIConfig.CloseButtonSize.X.Offset / 2 + 20, 0.5, 0)
_closeButton.Parent = _titleBar

local _scrollFrame = Instance.new('ScrollingFrame')
_scrollFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
_scrollFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.Parent = _frame

local _childFrame = Instance.new('Frame')
_childFrame.Size = UDim2.new(0, 60, 0, 40)
_childFrame.AnchorPoint = Vector2.new(0, 0.5)
_childFrame.BackgroundColor3 = Color3.fromRGB(33, 150, 243)  -- 蓝色
_childFrame.Visible = false
_childFrame.Parent = _screenGui

local _giftButton = Instance.new('TextButton')
_giftButton.Name = 'giftButton'
_giftButton.Size = UDim2.new(1, 0, 1, 0)
_giftButton.Text = LanguageConfig:Get(10027)
_giftButton.Font = UIConfig.Font
_giftButton.TextSize = 18
_giftButton.TextColor3 = Color3.new(1, 1, 1)
_giftButton.BackgroundTransparency = 0.5
_giftButton.Parent = _childFrame

_giftButton.MouseButton1Click:Connect(function()
    local userId = _childFrame:GetAttribute("PlayerId")
    Knit.GetController('UIController').ShowGiftUI:Fire(userId)
    _scrollFrame.ScrollingEnabled = false
end)

-- 玩家条目模板
local _playerTemplate = Instance.new('TextButton')
_playerTemplate.Size = UDim2.new(0.9, 0, 0, 40)
_playerTemplate.Text = "PlayerName (ID:123)"
_playerTemplate.Font = UIConfig.Font
_playerTemplate.TextSize = 18
_playerTemplate.TextColor3 = Color3.new(1, 1, 1)
_playerTemplate.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
_playerTemplate.Visible = false

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
        yPos += 35
    end
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