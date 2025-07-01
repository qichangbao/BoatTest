-- 航行距离排行榜客户端界面
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

-- 当前显示的排行榜类型
local currentLeaderboardType = 'totalDis'

-- 创建主界面
local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'RankUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = playerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateBigFrame(_screenGui, LanguageConfig.Get(10084))

-- 标签页按钮容器
local _tabContainer = Instance.new('Frame')
_tabContainer.Name = 'TabContainer'
_tabContainer.Size = UDim2.new(1, -20, 0, 40)
_tabContainer.Position = UDim2.new(0, 10, 0, 10)
_tabContainer.BackgroundTransparency = 1
_tabContainer.Parent = _frame

-- 总距离标签页
local _totalDisTab = Instance.new('TextButton')
_totalDisTab.Name = 'TotalDisTab'
_totalDisTab.Size = UDim2.new(0.23, 0, 1, 0)
_totalDisTab.Position = UDim2.new(0, 0, 0, 0)
_totalDisTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
_totalDisTab.BorderSizePixel = 0
_totalDisTab.Text = LanguageConfig.Get(10085)
_totalDisTab.TextColor3 = Color3.fromRGB(255, 255, 255)
_totalDisTab.TextScaled = true
_totalDisTab.Font = UIConfig.Font
_totalDisTab.Parent = _tabContainer

local _totalDisTabCorner = Instance.new('UICorner')
_totalDisTabCorner.CornerRadius = UDim.new(0, 6)
_totalDisTabCorner.Parent = _totalDisTab

-- 单次最大距离标签页
local _maxDisTab = Instance.new('TextButton')
_maxDisTab.Name = 'MaxDisTab'
_maxDisTab.Size = UDim2.new(0.23, 0, 1, 0)
_maxDisTab.Position = UDim2.new(0.25, 5, 0, 0)
_maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
_maxDisTab.BorderSizePixel = 0
_maxDisTab.Text = LanguageConfig.Get(10086)
_maxDisTab.TextColor3 = Color3.fromRGB(255, 255, 255)
_maxDisTab.TextScaled = true
_maxDisTab.Font = UIConfig.Font
_maxDisTab.Parent = _tabContainer

local _maxDisTabCorner = Instance.new('UICorner')
_maxDisTabCorner.CornerRadius = UDim.new(0, 6)
_maxDisTabCorner.Parent = _maxDisTab

-- 总航行时间标签页
local _totalTimeTab = Instance.new('TextButton')
_totalTimeTab.Name = 'TotalTimeTab'
_totalTimeTab.Size = UDim2.new(0.23, 0, 1, 0)
_totalTimeTab.Position = UDim2.new(0.5, 10, 0, 0)
_totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
_totalTimeTab.BorderSizePixel = 0
_totalTimeTab.Text = LanguageConfig.Get(10090)
_totalTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
_totalTimeTab.TextScaled = true
_totalTimeTab.Font = UIConfig.Font
_totalTimeTab.Parent = _tabContainer

local _totalTimeTabTabCorner = Instance.new('UICorner')
_totalTimeTabTabCorner.CornerRadius = UDim.new(0, 6)
_totalTimeTabTabCorner.Parent = _totalTimeTab

-- 最大航行时间标签页
local _maxTimeTab = Instance.new('TextButton')
_maxTimeTab.Name = 'MaxTimeTab'
_maxTimeTab.Size = UDim2.new(0.23, 0, 1, 0)
_maxTimeTab.Position = UDim2.new(0.75, 10, 0, 0)
_maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
_maxTimeTab.BorderSizePixel = 0
_maxTimeTab.Text = LanguageConfig.Get(10087)
_maxTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
_maxTimeTab.TextScaled = true
_maxTimeTab.Font = UIConfig.Font
_maxTimeTab.Parent = _tabContainer

local _maxTimeTabTabCorner = Instance.new('UICorner')
_maxTimeTabTabCorner.CornerRadius = UDim.new(0, 6)
_maxTimeTabTabCorner.Parent = _maxTimeTab

-- 排行榜内容容器
local _contentFrame = Instance.new('ScrollingFrame')
_contentFrame.Name = 'ContentFrame'
_contentFrame.Size = UDim2.new(1, -20, 1, -125)
_contentFrame.Position = UDim2.new(0, 10, 0, 60)
_contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
_contentFrame.BorderSizePixel = 0
_contentFrame.ScrollBarThickness = 8
_contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
_contentFrame.Parent = _frame

local _contentCorner = Instance.new('UICorner')
_contentCorner.CornerRadius = UDim.new(0, 8)
_contentCorner.Parent = _contentFrame

-- 列表布局
local _listLayout = Instance.new('UIListLayout')
_listLayout.SortOrder = Enum.SortOrder.LayoutOrder
_listLayout.Padding = UDim.new(0, 5)
_listLayout.Parent = _contentFrame

-- 个人数据显示
local _personalFrame = Instance.new('Frame')
_personalFrame.Name = 'PersonalFrame'
_personalFrame.Size = UDim2.new(1, -20, 0, 60)
_personalFrame.Position = UDim2.new(0, 10, 1, -60)
_personalFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
_personalFrame.BorderSizePixel = 0
_personalFrame.Parent = _frame

local _personalCorner = Instance.new('UICorner')
_personalCorner.CornerRadius = UDim.new(0, 8)
_personalCorner.Parent = _personalFrame

-- 创建个人信息标签容器的水平布局
local _personalLayout = Instance.new('UIListLayout')
_personalLayout.FillDirection = Enum.FillDirection.Horizontal
_personalLayout.SortOrder = Enum.SortOrder.LayoutOrder
_personalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
_personalLayout.Padding = UDim.new(0, 10)
_personalLayout.Parent = _personalFrame

-- 个人排名标题（左侧）
local _personalTitle = Instance.new('TextLabel')
_personalTitle.Name = 'PersonalTitle'
_personalTitle.Size = UDim2.new(0, 160, 1, 0)
_personalTitle.BackgroundTransparency = 1
_personalTitle.Text = LanguageConfig.Get(10089)
_personalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
_personalTitle.TextScaled = true
_personalTitle.Font = UIConfig.Font
_personalTitle.TextXAlignment = Enum.TextXAlignment.Left
_personalTitle.LayoutOrder = 1
_personalTitle.Parent = _personalFrame

-- 排名数据容器（右侧）
local _dataContainer = Instance.new('Frame')
_dataContainer.Name = 'DataContainer'
_dataContainer.Size = UDim2.new(1, -170, 1, 0)
_dataContainer.BackgroundTransparency = 1
_dataContainer.LayoutOrder = 2
_dataContainer.Parent = _personalFrame

-- 数据容器的垂直布局
local _dataLayout = Instance.new('UIListLayout')
_dataLayout.FillDirection = Enum.FillDirection.Vertical
_dataLayout.SortOrder = Enum.SortOrder.LayoutOrder
_dataLayout.VerticalAlignment = Enum.VerticalAlignment.Center
_dataLayout.Padding = UDim.new(0, 3)
_dataLayout.Parent = _dataContainer

-- 第一行：距离信息容器
local _distanceRow = Instance.new('Frame')
_distanceRow.Name = 'DistanceRow'
_distanceRow.Size = UDim2.new(1, 0, 0, 20)
_distanceRow.BackgroundTransparency = 1
_distanceRow.LayoutOrder = 1
_distanceRow.Parent = _dataContainer

local _distanceRowLayout = Instance.new('UIListLayout')
_distanceRowLayout.FillDirection = Enum.FillDirection.Horizontal
_distanceRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
_distanceRowLayout.Padding = UDim.new(0, 10)
_distanceRowLayout.Parent = _distanceRow

-- 总距离标签
local _totalDistanceLabel = Instance.new('TextLabel')
_totalDistanceLabel.Name = 'TotalDistanceLabel'
_totalDistanceLabel.Size = UDim2.new(0.5, -5, 1, 0)
_totalDistanceLabel.BackgroundTransparency = 1
_totalDistanceLabel.Text = ''
_totalDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_totalDistanceLabel.TextScaled = true
_totalDistanceLabel.Font = UIConfig.Font
_totalDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
_totalDistanceLabel.LayoutOrder = 1
_totalDistanceLabel.Parent = _distanceRow

-- 单次最大距离标签
local _maxDistanceLabel = Instance.new('TextLabel')
_maxDistanceLabel.Name = 'MaxDistanceLabel'
_maxDistanceLabel.Size = UDim2.new(0.5, -5, 1, 0)
_maxDistanceLabel.BackgroundTransparency = 1
_maxDistanceLabel.Text = ''
_maxDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_maxDistanceLabel.TextScaled = true
_maxDistanceLabel.Font = UIConfig.Font
_maxDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
_maxDistanceLabel.LayoutOrder = 2
_maxDistanceLabel.Parent = _distanceRow

-- 第二行：时间信息容器
local _timeRow = Instance.new('Frame')
_timeRow.Name = 'TimeRow'
_timeRow.Size = UDim2.new(1, 0, 0, 20)
_timeRow.BackgroundTransparency = 1
_timeRow.LayoutOrder = 2
_timeRow.Parent = _dataContainer

local _timeRowLayout = Instance.new('UIListLayout')
_timeRowLayout.FillDirection = Enum.FillDirection.Horizontal
_timeRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
_timeRowLayout.Padding = UDim.new(0, 10)
_timeRowLayout.Parent = _timeRow

-- 总航行天数标签
local _totalTimeLabel = Instance.new('TextLabel')
_totalTimeLabel.Name = 'TotalDaysLabel'
_totalTimeLabel.Size = UDim2.new(0.5, -5, 1, 0)
_totalTimeLabel.BackgroundTransparency = 1
_totalTimeLabel.Text = ''
_totalTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_totalTimeLabel.TextScaled = true
_totalTimeLabel.Font = UIConfig.Font
_totalTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
_totalTimeLabel.LayoutOrder = 1
_totalTimeLabel.Parent = _timeRow

-- 单次最长天数标签
local _maxTimeLabel = Instance.new('TextLabel')
_maxTimeLabel.Name = 'MaxDaysLabel'
_maxTimeLabel.Size = UDim2.new(0.5, -5, 1, 0)
_maxTimeLabel.BackgroundTransparency = 1
_maxTimeLabel.Text = ''
_maxTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
_maxTimeLabel.TextScaled = true
_maxTimeLabel.Font = UIConfig.Font
_maxTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
_maxTimeLabel.LayoutOrder = 2
_maxTimeLabel.Parent = _timeRow

-- 创建排行榜条目
local function createLeaderboardEntry(rank, playerName, value, isPersonal)
    local entry = Instance.new('Frame')
    entry.Size = UDim2.new(1, -10, 0, 40)
    entry.BackgroundColor3 = isPersonal and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(50, 50, 60)
    entry.BorderSizePixel = 0
    entry.Parent = _contentFrame
    
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
    if currentLeaderboardType == 'totalTime' or currentLeaderboardType == 'maxTime' then
        valueLabel.Text = string.format('%.2f', value / (24 * 3600))
    else
        valueLabel.Text = string.format('%.2f', value)
    end
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextScaled = true
    valueLabel.Font = UIConfig.Font
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = entry
    
    return entry
end

-- 更新排行榜显示
local function updateLeaderboard()
    -- 清除现有条目
    for _, child in pairs(_contentFrame:GetChildren()) do
        if child:IsA('Frame') then
            child:Destroy()
        end
    end
    
    -- 获取排行榜数据
    local leaderboardData = nil
    if currentLeaderboardType == "totalDis" then
        leaderboardData = ClientData.RankData.totalDis
    elseif currentLeaderboardType == "maxDis" then
        leaderboardData = ClientData.RankData.maxDis
    elseif currentLeaderboardType == "totalTime" then
        leaderboardData = ClientData.RankData.totalTime
    elseif currentLeaderboardType == "maxTime" then
        leaderboardData = ClientData.RankData.maxTime
    end

    if leaderboardData and leaderboardData.leaderboard then
        for rank, entry in ipairs(leaderboardData.leaderboard) do
            local isPersonal = entry.playerName == player.Name
            createLeaderboardEntry(rank, entry.playerName, entry.value, isPersonal)
        end
        
        -- 更新Canvas大小
        _contentFrame.CanvasSize = UDim2.new(0, 0, 0, #leaderboardData.leaderboard * 45)
    else
        warn('获取排行榜数据失败:', leaderboardData)
    end
    
    -- 获取个人数据
    local totalDisRank = ClientData.PersonRankData.serverData.totalDisRank
    if not totalDisRank or totalDisRank == GameConfig.TotalDistanceRank then
        totalDisRank = LanguageConfig.Get(10088)
    end
    local maxDisRank = ClientData.PersonRankData.serverData.maxDisRank
    if not maxDisRank or maxDisRank == GameConfig.MaxDistanceRank then
        maxDisRank = LanguageConfig.Get(10088)
    end
    local totalTimeRank = ClientData.PersonRankData.serverData.totalTimeRank
    if not totalTimeRank or totalTimeRank == GameConfig.TotalTimeRank then
        totalTimeRank = LanguageConfig.Get(10088)
    end
    local maxTimeRank = ClientData.PersonRankData.serverData.maxTimeRank
    if not maxTimeRank or maxTimeRank == GameConfig.MaxTimeRank then
        maxTimeRank = LanguageConfig.Get(10088)
    end

    local totalDis = ClientData.PersonRankData.serverData.totalDistance or 0
    local maxDis = ClientData.PersonRankData.serverData.maxSingleDistance or 0
    local totalTime = string.format("%.2f", ClientData.PersonRankData.serverData.totalSailingTime / (24 * 3600))
    local maxTime = string.format("%.2f", ClientData.PersonRankData.serverData.maxSailingTime / (24 * 3600))
    
    -- 更新各个标签的文本
    _totalDistanceLabel.Text = LanguageConfig.Get(10085) .. ": " .. math.floor(totalDis) .. "    " .. LanguageConfig.Get(10091) .. ": " .. totalDisRank
    _maxDistanceLabel.Text = LanguageConfig.Get(10086) .. ": " .. math.floor(maxDis) .. "    " .. LanguageConfig.Get(10091) .. ": " .. maxDisRank
    _totalTimeLabel.Text = LanguageConfig.Get(10090) .. ": " .. totalTime .. "    " .. LanguageConfig.Get(10091) .. ": " .. totalTimeRank
    _maxTimeLabel.Text = LanguageConfig.Get(10087) .. ": " .. maxTime .. "    " .. LanguageConfig.Get(10091) .. ": " .. maxTimeRank
end

-- 标签页切换
_totalDisTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'totalDis'
    _totalDisTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    _maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    updateLeaderboard()
end)

_maxDisTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'maxDis'
    _totalDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _maxDisTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    _totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    updateLeaderboard()
end)

_totalTimeTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'totalTime'
    _totalDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _totalTimeTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    _maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    updateLeaderboard()
end)

_maxTimeTab.MouseButton1Click:Connect(function()
    currentLeaderboardType = 'maxTime'
    _totalDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    _maxTimeTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    updateLeaderboard()
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

    Knit.GetController('UIController').ShowRankUI:Connect(function()
        _screenGui.Enabled = true
        updateLeaderboard()
    end)
end)