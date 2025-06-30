-- 航行距离排行榜客户端界面
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

-- 当前显示的排行榜类型
local currentLeaderboardType = 'totalDis'

-- 创建主界面
local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'RandUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = playerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateBigFrame(_screenGui, LanguageConfig.Get(10084))

-- 标签页按钮容器
local tabContainer = Instance.new('Frame')
tabContainer.Name = 'TabContainer'
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.Position = UDim2.new(0, 10, 0, 10)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = _frame

-- 总距离标签页
local totalTab = Instance.new('TextButton')
totalTab.Name = 'TotalTab'
totalTab.Size = UDim2.new(0.33, -5, 1, 0)
totalTab.Position = UDim2.new(0, 0, 0, 0)
totalTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
totalTab.BorderSizePixel = 0
totalTab.Text = LanguageConfig.Get(10085)
totalTab.TextColor3 = Color3.fromRGB(255, 255, 255)
totalTab.TextScaled = true
totalTab.Font = UIConfig.Font
totalTab.Parent = tabContainer

local totalTabCorner = Instance.new('UICorner')
totalTabCorner.CornerRadius = UDim.new(0, 6)
totalTabCorner.Parent = totalTab

-- 单次最大距离标签页
local maxTab = Instance.new('TextButton')
maxTab.Name = 'MaxTab'
maxTab.Size = UDim2.new(0.33, -5, 1, 0)
maxTab.Position = UDim2.new(0.33, 5, 0, 0)
maxTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
maxTab.BorderSizePixel = 0
maxTab.Text = LanguageConfig.Get(10086)
maxTab.TextColor3 = Color3.fromRGB(255, 255, 255)
maxTab.TextScaled = true
maxTab.Font = UIConfig.Font
maxTab.Parent = tabContainer

local maxTabCorner = Instance.new('UICorner')
maxTabCorner.CornerRadius = UDim.new(0, 6)
maxTabCorner.Parent = maxTab

-- 航行天数标签页
local daysTab = Instance.new('TextButton')
daysTab.Name = 'DaysTab'
daysTab.Size = UDim2.new(0.33, -5, 1, 0)
daysTab.Position = UDim2.new(0.66, 10, 0, 0)
daysTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
daysTab.BorderSizePixel = 0
daysTab.Text = LanguageConfig.Get(10087)
daysTab.TextColor3 = Color3.fromRGB(255, 255, 255)
daysTab.TextScaled = true
daysTab.Font = UIConfig.Font
daysTab.Parent = tabContainer

local daysTabCorner = Instance.new('UICorner')
daysTabCorner.CornerRadius = UDim.new(0, 6)
daysTabCorner.Parent = daysTab

-- 排行榜内容容器
local contentFrame = Instance.new('ScrollingFrame')
contentFrame.Name = 'ContentFrame'
contentFrame.Size = UDim2.new(1, -20, 1, -130)
contentFrame.Position = UDim2.new(0, 10, 0, 60)
contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 8
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
contentFrame.Parent = _frame

local contentCorner = Instance.new('UICorner')
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

-- 列表布局
local listLayout = Instance.new('UIListLayout')
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = contentFrame

-- 个人数据显示
local personalFrame = Instance.new('Frame')
personalFrame.Name = 'PersonalFrame'
personalFrame.Size = UDim2.new(1, -20, 0, 50)
personalFrame.Position = UDim2.new(0, 10, 1, -60)
personalFrame.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
personalFrame.BorderSizePixel = 0
personalFrame.Parent = _frame

local personalCorner = Instance.new('UICorner')
personalCorner.CornerRadius = UDim.new(0, 8)
personalCorner.Parent = personalFrame

local personalLabel = Instance.new('TextLabel')
personalLabel.Name = 'PersonalLabel'
personalLabel.Size = UDim2.new(1, -10, 1, 0)
personalLabel.Position = UDim2.new(0, 5, 0, 0)
personalLabel.BackgroundTransparency = 1
personalLabel.Text = ''
personalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
personalLabel.TextScaled = true
personalLabel.Font = UIConfig.Font
personalLabel.Parent = personalFrame

-- 创建排行榜条目
local function createLeaderboardEntry(rank, playerName, value, isPersonal)
    local entry = Instance.new('Frame')
    entry.Size = UDim2.new(1, -10, 0, 40)
    entry.BackgroundColor3 = isPersonal and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(50, 50, 60)
    entry.BorderSizePixel = 0
    entry.Parent = contentFrame
    
    local entryCorner = Instance.new('UICorner')
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entry
    
    -- 排名
    local rankLabel = Instance.new('TextLabel')
    rankLabel.Size = UDim2.new(0, 50, 1, 0)
    rankLabel.Position = UDim2.new(0, 0, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = tostring(rank)
    rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rankLabel.TextScaled = true
    rankLabel.Font = UIConfig.Font
    rankLabel.Parent = entry
    
    -- 玩家名
    local nameLabel = Instance.new('TextLabel')
    nameLabel.Size = UDim2.new(0.5, -25, 1, 0)
    nameLabel.Position = UDim2.new(0, 50, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = UIConfig.Font
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- 距离/天数
    local valueLabel = Instance.new('TextLabel')
    valueLabel.Size = UDim2.new(0.5, -25, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 25, 0, 0)
    valueLabel.BackgroundTransparency = 1
    -- 根据当前排行榜类型格式化显示文本
    if currentLeaderboardType == 'maxTime' then
        valueLabel.Text = string.format('%.2f 天', value / (24 * 3600))
    else
        valueLabel.Text = string.format('%.2f 米', value)
    end
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextScaled = true
    valueLabel.Font = UIConfig.Font
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = entry
    
    return entry
end

-- 更新排行榜显示
local function updateLeaderboard(leaderboardData)
    -- 清除现有条目
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA('Frame') then
            child:Destroy()
        end
    end
    
    if not leaderboardData then
        -- 获取排行榜数据
        Knit.GetService('RankService'):GetLeaderboard(currentLeaderboardType):andThen(function(leaderboardData)
            if leaderboardData and leaderboardData.leaderboard then
                for rank, entry in ipairs(leaderboardData.leaderboard) do
                    local isPersonal = entry.playerName == player.Name
                    createLeaderboardEntry(rank, entry.playerName, entry.value, isPersonal)
                end
                
                -- 更新Canvas大小
                contentFrame.CanvasSize = UDim2.new(0, 0, 0, #leaderboardData.leaderboard * 45)
            else
                warn('获取排行榜数据失败:', leaderboardData)
            end
        end)
    else
        if leaderboardData.leaderboard then
            for rank, entry in pairs(leaderboardData.leaderboard) do
                local isPersonal = entry.playerName == player.Name
                createLeaderboardEntry(rank, entry.playerName, entry.value, isPersonal)
            end
            
            -- 更新Canvas大小
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, #leaderboardData.leaderboard * 45)
        end
    end
    
    -- 获取个人数据
    Knit.GetService('RankService'):GetPersonalData():andThen(function(personalData)
        if personalData then
            local totalDisRank = personalData.totalDisRank
            if not totalDisRank or totalDisRank == GameConfig.TotalDistanceRank then
                totalDisRank = LanguageConfig.Get(10088)
            end
            local maxDisRank = personalData.maxDisRank
            if not maxDisRank or maxDisRank == GameConfig.MaxDistanceRank then
                maxDisRank = LanguageConfig.Get(10088)
            end
            local maxTimeRank = personalData.maxTimeRank
            if not maxTimeRank or maxTimeRank == GameConfig.MaxDaysRank then
                maxTimeRank = LanguageConfig.Get(10088)
            end
            local maxTime = string.format("%.2f", personalData.maxSailingTime / (24 * 3600))
            personalLabel.Text = string.format(LanguageConfig.Get(10089),
                personalData.totalDistance or 0,
                personalData.maxSingleDistance or 0,
                maxTime,
                totalDisRank,
                maxDisRank,
                maxTimeRank)
        else
            warn('获取个人数据失败:', personalData)
        end
    end)
end

-- 标签页切换
totalTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'totalDis'
    totalTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    maxTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    daysTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    updateLeaderboard()
end)

maxTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'maxDis'
    totalTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    maxTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    daysTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    updateLeaderboard()
end)

daysTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'maxTime'
    totalTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    maxTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    daysTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    updateLeaderboard()
end)

-- 打开/关闭快捷键 (L键)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.L then
        _screenGui.Enabled = not _screenGui.Enabled
        if _screenGui.Enabled then
            updateLeaderboard()
        end
    end
end)

-- 等待Knit启动
Knit.OnStart():andThen(function()
    -- 定期更新排行榜
    task.spawn(function()
        while true do
            if _screenGui.Enabled then
                updateLeaderboard()
            end
            task.wait(30) -- 每30秒更新一次
        end
    end)
    
    -- 监听排行榜更新信号
    Knit.GetService('RankService').UpdateLeaderboard:Connect(function(leaderboardData)
        if _screenGui.Enabled then
            if currentLeaderboardType == 'totalDis' then
                updateLeaderboard(leaderboardData.totalDis)
            elseif currentLeaderboardType == 'maxDis' then
                updateLeaderboard(leaderboardData.maxDis)
            elseif currentLeaderboardType == 'maxTime' then
                updateLeaderboard(leaderboardData.maxTime)
            end
        end
    end)
    
    print('航行距离排行榜界面已加载，按L键打开/关闭')
end)