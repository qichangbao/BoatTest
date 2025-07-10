--[[
模块名称：排行榜信息显示
功能：在RankPart上显示排行榜信息，使用SurfaceGui
作者：Trea AI
版本：1.0.0
最后修改：2024-12-19
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(game:GetService("StarterGui"):WaitForChild('UIConfig'))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

-- 当前显示的排行榜类型
local currentLeaderboardType = 'totalDis'

-- 界面相关变量
local surfaceGui
local mainFrame
local titleLabel
local tabContainer
local totalDisTab
local maxDisTab
local totalTimeTab
local maxTimeTab
local contentFrame
local listLayout
local personalFrame
local totalDistanceLabel
local maxDistanceLabel
local totalTimeLabel
local maxTimeLabel

-- 创建排行榜条目
-- @param rank 排名
-- @param playerName 玩家名称
-- @param value 数值
-- @param isPersonal 是否为个人数据
local function createLeaderboardEntry(rank, playerName, value, isPersonal)
    local entry = Instance.new('Frame')
    entry.Size = UDim2.new(1, -10, 0, 50)
    entry.BackgroundColor3 = isPersonal and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(50, 50, 60)
    entry.BorderSizePixel = 0
    entry.Parent = contentFrame
    
    local entryCorner = Instance.new('UICorner')
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entry
    
    -- 排名
    local rankLabel = Instance.new('TextLabel')
    rankLabel.Size = UDim2.new(0, 60, 1, 0)
    rankLabel.Position = UDim2.new(0, 0, 0, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = tostring(rank)
    rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rankLabel.TextScaled = true
    rankLabel.Font = UIConfig.Font
    rankLabel.Parent = entry
    
    -- 玩家名
    local nameLabel = Instance.new('TextLabel')
    nameLabel.Size = UDim2.new(0.5, -30, 1, 0)
    nameLabel.Position = UDim2.new(0, 60, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = UIConfig.Font
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entry
    
    -- 距离/天数
    local valueLabel = Instance.new('TextLabel')
    valueLabel.Size = UDim2.new(0.5, -30, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 30, 0, 0)
    valueLabel.BackgroundTransparency = 1
    -- 根据当前排行榜类型格式化显示文本
    if currentLeaderboardType == 'totalTime' or currentLeaderboardType == 'maxTime' then
        valueLabel.Text = string.format('%.2f', value / (24 * 3600))
    else
        valueLabel.Text = tostring(value)
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
    for _, child in pairs(contentFrame:GetChildren()) do
        if child:IsA('Frame') then
            child:Destroy()
        end
    end
    
    -- 获取排行榜数据
    local leaderboardData = nil
    if currentLeaderboardType == "totalDis" then
        leaderboardData = ClientData.RankData.totalDis
        totalDisTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    elseif currentLeaderboardType == "maxDis" then
        leaderboardData = ClientData.RankData.maxDis
        totalDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        maxDisTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    elseif currentLeaderboardType == "totalTime" then
        leaderboardData = ClientData.RankData.totalTime
        totalDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        totalTimeTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    elseif currentLeaderboardType == "maxTime" then
        leaderboardData = ClientData.RankData.maxTime
        totalDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
        maxTimeTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    end

    if leaderboardData and leaderboardData.leaderboard then
        for rank, entry in ipairs(leaderboardData.leaderboard) do
            local isPersonal = entry.playerName == Players.LocalPlayer.Name
            createLeaderboardEntry(rank, entry.playerName, entry.value, isPersonal)
        end
        
        -- 更新Canvas大小
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, #leaderboardData.leaderboard * 55)
    else
        warn('获取排行榜数据失败:', leaderboardData)
    end
    
    -- 获取个人数据
    local totalDisRank = ClientData.PersonRankData.totalDisRank
    if not totalDisRank or totalDisRank == GameConfig.TotalDistanceRank then
        totalDisRank = LanguageConfig.Get(10088)
    end
    local maxDisRank = ClientData.PersonRankData.maxDisRank
    if not maxDisRank or maxDisRank == GameConfig.MaxDistanceRank then
        maxDisRank = LanguageConfig.Get(10088)
    end
    local totalTimeRank = ClientData.PersonRankData.totalTimeRank
    if not totalTimeRank or totalTimeRank == GameConfig.TotalTimeRank then
        totalTimeRank = LanguageConfig.Get(10088)
    end
    local maxTimeRank = ClientData.PersonRankData.maxTimeRank
    if not maxTimeRank or maxTimeRank == GameConfig.MaxTimeRank then
        maxTimeRank = LanguageConfig.Get(10088)
    end

    local totalDis = ClientData.PersonRankData.totalDistance or 0
    local maxDis = ClientData.PersonRankData.maxSailingDistance or 0
    local totalTime = string.format("%.2f", ClientData.PersonRankData.totalSailingTime / (24 * 3600))
    local maxTime = string.format("%.2f", ClientData.PersonRankData.maxSailingTime / (24 * 3600))
    
    -- 更新各个标签的文本
    totalDistanceLabel.Text = LanguageConfig.Get(10085) .. ": " .. math.floor(totalDis) .. "    " .. LanguageConfig.Get(10091) .. ": " .. totalDisRank
    maxDistanceLabel.Text = LanguageConfig.Get(10086) .. ": " .. math.floor(maxDis) .. "    " .. LanguageConfig.Get(10091) .. ": " .. maxDisRank
    totalTimeLabel.Text = LanguageConfig.Get(10090) .. ": " .. totalTime .. "    " .. LanguageConfig.Get(10091) .. ": " .. totalTimeRank
    maxTimeLabel.Text = LanguageConfig.Get(10087) .. ": " .. maxTime .. "    " .. LanguageConfig.Get(10091) .. ": " .. maxTimeRank
end

-- 创建排行榜界面的函数
local function createRankInterface()
    -- 等待RankPart存在
    local rankPart = workspace:WaitForChild("奥林匹斯", 30):WaitForChild("RankPart")
    
    -- 创建SurfaceGui
    surfaceGui = Instance.new('SurfaceGui')
    surfaceGui.Name = 'RankInfoSurfaceGui'
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    surfaceGui.Parent = rankPart

    -- 主框架
    mainFrame = Instance.new('Frame')
    mainFrame.Name = 'MainFrame'
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = surfaceGui
    
    local mainCorner = Instance.new('UICorner')
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame
    
    -- 标题
    titleLabel = Instance.new('TextLabel')
    titleLabel.Name = 'TitleLabel'
    titleLabel.Size = UDim2.new(1, -20, 0, 60)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = LanguageConfig.Get(10084)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = UIConfig.Font
    titleLabel.Parent = mainFrame
    
    -- 标签页按钮容器
    tabContainer = Instance.new('Frame')
    tabContainer.Name = 'TabContainer'
    tabContainer.Size = UDim2.new(1, -20, 0, 50)
    tabContainer.Position = UDim2.new(0, 10, 0, 80)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    -- 总距离标签页
    totalDisTab = Instance.new('TextButton')
    totalDisTab.Name = 'TotalDisTab'
    totalDisTab.Size = UDim2.new(0.23, 0, 1, 0)
    totalDisTab.Position = UDim2.new(0, 0, 0, 0)
    totalDisTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    totalDisTab.BorderSizePixel = 0
    totalDisTab.Text = LanguageConfig.Get(10085)
    totalDisTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    totalDisTab.TextScaled = true
    totalDisTab.Font = UIConfig.Font
    totalDisTab.Parent = tabContainer
    totalDisTab.MouseButton1Click:Connect(function()
        currentLeaderboardType = "totalDis"
        updateLeaderboard()
    end)
    
    local totalDisTabCorner = Instance.new('UICorner')
    totalDisTabCorner.CornerRadius = UDim.new(0, 6)
    totalDisTabCorner.Parent = totalDisTab
    
    -- 单次最大距离标签页
    maxDisTab = Instance.new('TextButton')
    maxDisTab.Name = 'MaxDisTab'
    maxDisTab.Size = UDim2.new(0.23, 0, 1, 0)
    maxDisTab.Position = UDim2.new(0.25, 5, 0, 0)
    maxDisTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    maxDisTab.BorderSizePixel = 0
    maxDisTab.Text = LanguageConfig.Get(10086)
    maxDisTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    maxDisTab.TextScaled = true
    maxDisTab.Font = UIConfig.Font
    maxDisTab.Parent = tabContainer
    maxDisTab.MouseButton1Click:Connect(function()
        currentLeaderboardType = "maxDis"
        updateLeaderboard()
    end)
    
    local maxDisTabCorner = Instance.new('UICorner')
    maxDisTabCorner.CornerRadius = UDim.new(0, 6)
    maxDisTabCorner.Parent = maxDisTab
    
    -- 总航行时间标签页
    totalTimeTab = Instance.new('TextButton')
    totalTimeTab.Name = 'TotalTimeTab'
    totalTimeTab.Size = UDim2.new(0.23, 0, 1, 0)
    totalTimeTab.Position = UDim2.new(0.5, 10, 0, 0)
    totalTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    totalTimeTab.BorderSizePixel = 0
    totalTimeTab.Text = LanguageConfig.Get(10090)
    totalTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    totalTimeTab.TextScaled = true
    totalTimeTab.Font = UIConfig.Font
    totalTimeTab.Parent = tabContainer
    totalTimeTab.MouseButton1Click:Connect(function()
        currentLeaderboardType = "totalTime"
        updateLeaderboard()
    end)
    
    local totalTimeTabCorner = Instance.new('UICorner')
    totalTimeTabCorner.CornerRadius = UDim.new(0, 6)
    totalTimeTabCorner.Parent = totalTimeTab
    
    -- 最大航行时间标签页
    maxTimeTab = Instance.new('TextButton')
    maxTimeTab.Name = 'MaxTimeTab'
    maxTimeTab.Size = UDim2.new(0.23, 0, 1, 0)
    maxTimeTab.Position = UDim2.new(0.75, 10, 0, 0)
    maxTimeTab.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
    maxTimeTab.BorderSizePixel = 0
    maxTimeTab.Text = LanguageConfig.Get(10087)
    maxTimeTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    maxTimeTab.TextScaled = true
    maxTimeTab.Font = UIConfig.Font
    maxTimeTab.Parent = tabContainer
    maxTimeTab.MouseButton1Click:Connect(function()
        currentLeaderboardType = "maxTime"
        updateLeaderboard()
    end)
    
    local maxTimeTabCorner = Instance.new('UICorner')
    maxTimeTabCorner.CornerRadius = UDim.new(0, 6)
    maxTimeTabCorner.Parent = maxTimeTab

    -- 排行榜内容容器
    contentFrame = Instance.new('ScrollingFrame')
    contentFrame.Name = 'ContentFrame'
    contentFrame.Size = UDim2.new(1, -20, 1, -220)
    contentFrame.Position = UDim2.new(0, 10, 0, 140)
    contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new('UICorner')
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame
    
    -- 列表布局
    listLayout = Instance.new('UIListLayout')
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = contentFrame
    
    -- 个人数据显示
    personalFrame = Instance.new('Frame')
    personalFrame.Name = 'PersonalFrame'
    personalFrame.Size = UDim2.new(1, -20, 0, 80)
    personalFrame.Position = UDim2.new(0, 10, 1, -90)
    personalFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    personalFrame.BorderSizePixel = 0
    personalFrame.Parent = mainFrame
    
    local personalCorner = Instance.new('UICorner')
    personalCorner.CornerRadius = UDim.new(0, 8)
    personalCorner.Parent = personalFrame

    -- 创建个人信息标签容器的水平布局
    local personalLayout = Instance.new('UIListLayout')
    personalLayout.FillDirection = Enum.FillDirection.Horizontal
    personalLayout.SortOrder = Enum.SortOrder.LayoutOrder
    personalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    personalLayout.Padding = UDim.new(0, 10)
    personalLayout.Parent = personalFrame
    
    -- 个人排名标题（左侧）
    local personalTitle = Instance.new('TextLabel')
    personalTitle.Name = 'PersonalTitle'
    personalTitle.Size = UDim2.new(0, 160, 1, 0)
    personalTitle.BackgroundTransparency = 1
    personalTitle.Text = LanguageConfig.Get(10089)
    personalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    personalTitle.TextScaled = true
    personalTitle.Font = UIConfig.Font
    personalTitle.TextXAlignment = Enum.TextXAlignment.Left
    personalTitle.LayoutOrder = 1
    personalTitle.Parent = personalFrame
    
    -- 排名数据容器（右侧）
    local dataContainer = Instance.new('Frame')
    dataContainer.Name = 'DataContainer'
    dataContainer.Size = UDim2.new(1, -170, 1, 0)
    dataContainer.BackgroundTransparency = 1
    dataContainer.LayoutOrder = 2
    dataContainer.Parent = personalFrame
    
    -- 数据容器的垂直布局
    local dataLayout = Instance.new('UIListLayout')
    dataLayout.FillDirection = Enum.FillDirection.Vertical
    dataLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dataLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    dataLayout.Padding = UDim.new(0, 3)
    dataLayout.Parent = dataContainer
    
    -- 第一行：距离信息容器
    local distanceRow = Instance.new('Frame')
    distanceRow.Name = 'DistanceRow'
    distanceRow.Size = UDim2.new(1, 0, 0, 25)
    distanceRow.BackgroundTransparency = 1
    distanceRow.LayoutOrder = 1
    distanceRow.Parent = dataContainer
    
    local distanceRowLayout = Instance.new('UIListLayout')
    distanceRowLayout.FillDirection = Enum.FillDirection.Horizontal
    distanceRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    distanceRowLayout.Padding = UDim.new(0, 10)
    distanceRowLayout.Parent = distanceRow
    
    -- 总距离标签
    totalDistanceLabel = Instance.new('TextLabel')
    totalDistanceLabel.Name = 'TotalDistanceLabel'
    totalDistanceLabel.Size = UDim2.new(0.5, -5, 1, 0)
    totalDistanceLabel.BackgroundTransparency = 1
    totalDistanceLabel.Text = ''
    totalDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    totalDistanceLabel.TextScaled = true
    totalDistanceLabel.Font = UIConfig.Font
    totalDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalDistanceLabel.LayoutOrder = 1
    totalDistanceLabel.Parent = distanceRow
    
    -- 单次最大距离标签
    maxDistanceLabel = Instance.new('TextLabel')
    maxDistanceLabel.Name = 'MaxDistanceLabel'
    maxDistanceLabel.Size = UDim2.new(0.5, -5, 1, 0)
    maxDistanceLabel.BackgroundTransparency = 1
    maxDistanceLabel.Text = ''
    maxDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    maxDistanceLabel.TextScaled = true
    maxDistanceLabel.Font = UIConfig.Font
    maxDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    maxDistanceLabel.LayoutOrder = 2
    maxDistanceLabel.Parent = distanceRow
    
    -- 第二行：时间信息容器
    local timeRow = Instance.new('Frame')
    timeRow.Name = 'TimeRow'
    timeRow.Size = UDim2.new(1, 0, 0, 25)
    timeRow.BackgroundTransparency = 1
    timeRow.LayoutOrder = 2
    timeRow.Parent = dataContainer
    
    local timeRowLayout = Instance.new('UIListLayout')
    timeRowLayout.FillDirection = Enum.FillDirection.Horizontal
    timeRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    timeRowLayout.Padding = UDim.new(0, 10)
    timeRowLayout.Parent = timeRow
    
    -- 总航行天数标签
    totalTimeLabel = Instance.new('TextLabel')
    totalTimeLabel.Name = 'TotalDaysLabel'
    totalTimeLabel.Size = UDim2.new(0.5, -5, 1, 0)
    totalTimeLabel.BackgroundTransparency = 1
    totalTimeLabel.Text = ''
    totalTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    totalTimeLabel.TextScaled = true
    totalTimeLabel.Font = UIConfig.Font
    totalTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalTimeLabel.LayoutOrder = 1
    totalTimeLabel.Parent = timeRow
    
    -- 单次最长天数标签
    maxTimeLabel = Instance.new('TextLabel')
    maxTimeLabel.Name = 'MaxDaysLabel'
    maxTimeLabel.Size = UDim2.new(0.5, -5, 1, 0)
    maxTimeLabel.BackgroundTransparency = 1
    maxTimeLabel.Text = ''
    maxTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    maxTimeLabel.TextScaled = true
    maxTimeLabel.Font = UIConfig.Font
    maxTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    maxTimeLabel.LayoutOrder = 2
    maxTimeLabel.Parent = timeRow
end

-- 等待Knit启动
Knit.OnStart():andThen(function()
    createRankInterface()
    -- local player = game.Players.LocalPlayer
    -- -- 如果角色已经存在，直接创建界面
    -- if player.Character and player.Character:FindFirstChild("Humanoid") then
    --     createRankInterface()
    -- else
    --     -- 等待角色创建
    --     local function onCharacterAdded(character)
    --         -- 等待Humanoid加载完成
    --         local humanoid = character:WaitForChild("Humanoid", 10)
    --         if humanoid then
    --             createRankInterface()
    --         else
    --             warn("排行榜界面：等待Humanoid超时")
    --         end
    --     end
        
    --     -- 连接角色添加事件
    --     if player.Character then
    --         onCharacterAdded(player.Character)
    --     else
    --         player.CharacterAdded:Connect(onCharacterAdded)
    --     end
    -- end
    
    -- 定期更新排行榜
    task.spawn(function()
        while true do
            task.wait(3600) -- 每小时更新一次
            updateLeaderboard()
        end
    end)
    
    -- 连接更新排行榜信号
    Knit.GetController('UIController').UpdateRankUI:Connect(function()
        updateLeaderboard()
    end)
end)