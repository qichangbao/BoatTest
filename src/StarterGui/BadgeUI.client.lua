--[[
模块名称：徽章界面系统
功能：管理玩家徽章UI的显示与交互，包括徽章展示和完成状态
作者：Trea AI
版本：1.0.0
最后修改：2024-12-19
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BadgeConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("BadgeConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local ClientData = require(game:GetService('StarterPlayer'):WaitForChild('StarterPlayerScripts'):WaitForChild('ClientData'))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
local UIConfig = require(script.Parent:WaitForChild('UIConfig'))

local _screenGui = Instance.new("ScreenGui")
_screenGui.Name = "BadgeUI_GUI"
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateBigFrame(_screenGui, LanguageConfig.Get(10118))

-- 徽章详情显示区域
local _detailFrame = Instance.new("Frame")
_detailFrame.Name = "BadgeDetailFrame"
_detailFrame.Size = UDim2.new(1, -20, 0, 80)  -- 从120减小到80
_detailFrame.Position = UDim2.new(0, 10, 0, 10)
_detailFrame.BackgroundColor3 = Color3.fromRGB(35, 39, 56)
_detailFrame.BackgroundTransparency = 0.1
_detailFrame.BorderSizePixel = 0
_detailFrame.Parent = _frame
UIConfig.CreateCorner(_detailFrame, UDim.new(0, 8))

-- 详情区域边框
local _detailStroke = Instance.new("UIStroke")
_detailStroke.Color = Color3.fromRGB(86, 92, 120)
_detailStroke.Thickness = 1
_detailStroke.Parent = _detailFrame

-- 详情区域图标
local _detailIcon = Instance.new("ImageLabel")
_detailIcon.Name = "DetailIcon"
_detailIcon.Size = UDim2.new(0, 60, 0, 60)  -- 从80x80减小到60x60
_detailIcon.Position = UDim2.new(0, 15, 0.5, -30)  -- 调整位置适应新尺寸
_detailIcon.BackgroundColor3 = Color3.fromRGB(59, 63, 83)
_detailIcon.BackgroundTransparency = 1
_detailIcon.BorderSizePixel = 0
_detailIcon.ScaleType = Enum.ScaleType.Fit
_detailIcon.Image = "rbxassetid://0"
_detailIcon.Parent = _detailFrame
UIConfig.CreateCorner(_detailIcon, UDim.new(0, 8))

-- 详情区域名称
local _detailName = Instance.new("TextLabel")
_detailName.Name = "DetailName"
_detailName.Text = LanguageConfig.Get(10122)
_detailName.Size = UDim2.new(1, -100, 0, 25)  -- 调整尺寸适应更小的详情区域
_detailName.Position = UDim2.new(0, 85, 0, 10)  -- 调整位置
_detailName.TextColor3 = Color3.fromRGB(255, 255, 255)
_detailName.Font = UIConfig.Font
_detailName.TextScaled = true
_detailName.TextXAlignment = Enum.TextXAlignment.Left
_detailName.BackgroundTransparency = 1
_detailName.TextTruncate = Enum.TextTruncate.AtEnd
_detailName.Parent = _detailFrame

-- 详情区域描述
local _detailDesc = Instance.new("TextLabel")
_detailDesc.Name = "DetailDesc"
_detailDesc.Text = LanguageConfig.Get(10119)
_detailDesc.Size = UDim2.new(1, -100, 0, 35)  -- 调整尺寸
_detailDesc.Position = UDim2.new(0, 85, 0, 35)  -- 调整位置
_detailDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
_detailDesc.Font = UIConfig.Font
_detailDesc.TextScaled = true
_detailDesc.TextXAlignment = Enum.TextXAlignment.Left
_detailDesc.TextYAlignment = Enum.TextYAlignment.Top
_detailDesc.BackgroundTransparency = 1
_detailDesc.TextWrapped = true
_detailDesc.Parent = _detailFrame

-- 详情区域状态标签
local _detailStatus = Instance.new("TextLabel")
_detailStatus.Name = "DetailStatus"
_detailStatus.Text = ""
_detailStatus.Size = UDim2.new(0, 80, 0, 20)  -- 调整尺寸
_detailStatus.Position = UDim2.new(1, -90, 0, 10)  -- 调整位置
_detailStatus.TextColor3 = Color3.fromRGB(46, 204, 113)
_detailStatus.Font = UIConfig.Font
_detailStatus.TextScaled = true
_detailStatus.TextXAlignment = Enum.TextXAlignment.Center
_detailStatus.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
_detailStatus.BackgroundTransparency = 0.8
_detailStatus.BorderSizePixel = 0
_detailStatus.Visible = false
_detailStatus.Parent = _detailFrame
UIConfig.CreateCorner(_detailStatus, UDim.new(0, 4))

-- 徽章滚动区域
local _scrollFrame = Instance.new("ScrollingFrame")
_scrollFrame.Size = UDim2.new(1, -20, 1, -110)  -- 从-150调整到-110，增加徽章区域高度
_scrollFrame.Position = UDim2.new(0, 10, 0, 100)  -- 从140调整到100，向上移动
_scrollFrame.BackgroundTransparency = 1
_scrollFrame.ScrollBarThickness = 8
_scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
_scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
_scrollFrame.Parent = _frame

-- 添加内边距容器
local _paddingFrame = Instance.new("UIPadding")
_paddingFrame.PaddingLeft = UDim.new(0, 5)
_paddingFrame.PaddingRight = UDim.new(0, 5)
_paddingFrame.PaddingTop = UDim.new(0, 5)
_paddingFrame.PaddingBottom = UDim.new(0, 5)
_paddingFrame.Parent = _scrollFrame

-- 网格布局
local _gridLayout = Instance.new("UIGridLayout")
_gridLayout.CellSize = UDim2.new(0.15, 0, 0.5, 0)  -- 按比例设置，每行6个徽章，正方形
_gridLayout.CellPadding = UDim2.new(0.02, 0, 0.1, 0)  -- 按比例设置间距
_gridLayout.FillDirectionMaxCells = 6  -- 每行6个徽章
_gridLayout.StartCorner = Enum.StartCorner.TopLeft
_gridLayout.FillDirection = Enum.FillDirection.Horizontal
_gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
_gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
_gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
_gridLayout.Parent = _scrollFrame

-- 监听网格布局变化，自动调整滚动框大小
_gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local contentSize = _gridLayout.AbsoluteContentSize
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + _gridLayout.CellPadding.Y.Scale * _scrollFrame.AbsoluteSize.Y + 20)
end)

-- 创建徽章模板
local _badgeTemplate = Instance.new("ImageButton")
_badgeTemplate.Name = "BadgeTemplate"
_badgeTemplate.Size = UDim2.new(0.15, 0, 0.5, 0)  -- 按比例设置徽章大小
_badgeTemplate.BackgroundTransparency = 1  -- 完全透明，不显示底板
_badgeTemplate.BorderSizePixel = 0
_badgeTemplate.Visible = false

-- 徽章图标（圆形）
local _iconImage = Instance.new("ImageLabel")
_iconImage.Name = "IconImage"
_iconImage.Image = "rbxassetid://0" -- 默认空图片
_iconImage.Size = UDim2.new(1, 0, 1, 0)  -- 填满整个按钮
_iconImage.Position = UDim2.new(0, 0, 0, 0)
_iconImage.BackgroundTransparency = 1
_iconImage.ScaleType = Enum.ScaleType.Fit
_iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)  -- 默认白色
_iconImage.Parent = _badgeTemplate
-- 创建圆形遮罩
local _iconCorner = Instance.new("UICorner")
_iconCorner.CornerRadius = UDim.new(0.5, 0)  -- 50%圆角，形成圆形
_iconCorner.Parent = _iconImage

-- 完成标记（仅已完成徽章显示）
local _completedMark = Instance.new("ImageLabel")
_completedMark.Name = "CompletedMark"
_completedMark.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"  -- 可以替换为勾选图标
_completedMark.Size = UDim2.new(0.3, 0, 0.3, 0)  -- 相对大小
_completedMark.Position = UDim2.new(0.7, 0, 0, 0)  -- 右上角
_completedMark.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
_completedMark.BackgroundTransparency = 0.2
_completedMark.BorderSizePixel = 0
_completedMark.Visible = false
_completedMark.Parent = _badgeTemplate
-- 完成标记圆形
local _markCorner = Instance.new("UICorner")
_markCorner.CornerRadius = UDim.new(0.5, 0)
_markCorner.Parent = _completedMark

-- 选择框（表示当前选中的徽章）
local _selectionFrame = Instance.new("Frame")
_selectionFrame.Name = "SelectionFrame"
_selectionFrame.Size = UDim2.new(1, 6, 1, 6)
_selectionFrame.Position = UDim2.new(0, -3, 0, -3)
_selectionFrame.BackgroundTransparency = 1
_selectionFrame.BorderSizePixel = 0
_selectionFrame.Visible = false
_selectionFrame.Parent = _badgeTemplate

-- 选择框边框
local _selectionStroke = Instance.new("UIStroke")
_selectionStroke.Color = Color3.fromRGB(255, 215, 0) -- 金色边框
_selectionStroke.Thickness = 2  -- 更细的选择边框
_selectionStroke.Parent = _selectionFrame
UIConfig.CreateCorner(_selectionFrame, UDim.new(0, 10))  -- 更小的圆角

-- 全局变量：当前选中的徽章
local _selectedBadge = nil
local _badgeList = {} -- 存储所有徽章的信息
local _badgeUICreated = false -- 标记徽章UI是否已创建

--[[
更新详情显示区域
@param badgeInfo: 徽章信息
@param hasBadge: 是否拥有徽章
]]
local function UpdateDetailDisplay(badgeInfo, hasBadge)
    -- 更新图标
    if badgeInfo.IconImageId and badgeInfo.IconImageId > 0 then
        _detailIcon.Image = "rbxassetid://" .. badgeInfo.IconImageId
    else
        _detailIcon.Image = "rbxassetid://0"
    end
    
    -- 更新名称和描述
    _detailName.Text = badgeInfo.Name or ""
    _detailDesc.Text = badgeInfo.Description or ""
    
    -- 更新状态标签
    if hasBadge then
        _detailStatus.Text = LanguageConfig.Get(10120)
        _detailStatus.TextColor3 = Color3.fromRGB(46, 204, 113)
        _detailStatus.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        _detailStatus.Visible = true
    else
        _detailStatus.Text = LanguageConfig.Get(10121)
        _detailStatus.TextColor3 = Color3.fromRGB(231, 76, 60)
        _detailStatus.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        _detailStatus.Visible = true
    end
end

--[[
选择徽章
@param badgeButton: 被选中的徽章按钮
@param badgeInfo: 徽章信息
@param hasBadge: 是否拥有徽章
@param badgeData: 徽章配置数据
]]
local function SelectBadge(badgeButton, badgeInfo, hasBadge)
    -- 取消之前选中的徽章
    if _selectedBadge then
        local prevSelection = _selectedBadge:FindFirstChild("SelectionFrame")
        if prevSelection then
            prevSelection.Visible = false
        end
    end
    
    -- 选中新徽章
    _selectedBadge = badgeButton
    local selectionFrame = badgeButton:FindFirstChild("SelectionFrame")
    if selectionFrame then
        selectionFrame.Visible = true
    end
    
    -- 更新详情显示
    UpdateDetailDisplay(badgeInfo, hasBadge)
end

--[[
创建所有徽章的UI元素（游戏开始时调用一次）
]]
local function CreateBadgeUI()
    -- 检查徽章数据是否已加载
    if not ClientData.BadgeData or next(ClientData.BadgeData) == nil then
        warn("徽章数据尚未加载完成，无法创建UI")
        return false
    end
    
    -- 如果已经创建过UI，直接返回
    if _badgeUICreated then
        return true
    end
    
    print("开始创建徽章UI元素...")
    
    -- 清空现有徽章槽（保留模板）
    for _, child in ipairs(_scrollFrame:GetChildren()) do
        if child:IsA('ImageButton') and child ~= _badgeTemplate then
            child:Destroy()
        end
    end
    
    -- 清空徽章列表
    _badgeList = {}
    
    -- 从ClientData获取徽章数据并创建UI
    for badgeId, badgeData in pairs(ClientData.BadgeData) do
        -- 克隆徽章模板并初始化
        local newBadge = _badgeTemplate:Clone()
        newBadge.Name = 'Badge_' .. badgeId
        newBadge.LayoutOrder = badgeData.layoutOrder
        
        -- 存储徽章信息到列表
        table.insert(_badgeList, {
            button = newBadge,
            info = badgeData.info,
            hasBadge = badgeData.hasBadge,
            badgeId = badgeId
        })
        
        -- 设置徽章UI元素引用
        local iconImage = newBadge:FindFirstChild('IconImage')
        
        -- 设置徽章图标
        if badgeData.info.IconImageId and badgeData.info.IconImageId > 0 then
            iconImage.Image = "rbxassetid://" .. badgeData.info.IconImageId
            iconImage.Visible = true
        else
            iconImage.Visible = false
        end
        
        -- 设置徽章状态显示
        if badgeData.hasBadge then
            -- 已获得徽章：高亮显示
            iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- 正常亮度
            iconImage.ImageTransparency = 0 -- 完全不透明
        else
            -- 未获得徽章：调暗显示
            iconImage.ImageColor3 = Color3.fromRGB(100, 100, 100) -- 暗灰色
            iconImage.ImageTransparency = 0.5 -- 半透明
        end
            
        -- 点击事件：选择徽章并显示详情
        newBadge.MouseButton1Click:Connect(function()
            SelectBadge(newBadge, badgeData.info, badgeData.hasBadge)
        end)
        
        newBadge.Visible = true
        newBadge.Parent = _scrollFrame
    end
    
    -- 按LayoutOrder排序徽章列表
    table.sort(_badgeList, function(a, b)
        return a.button.LayoutOrder < b.button.LayoutOrder
    end)
    
    _badgeUICreated = true
    print("徽章UI创建完成，共创建 " .. #_badgeList .. " 个徽章")
    return true
end

--[[
更新徽章状态显示（当徽章状态改变时调用）
]]
local function UpdateBadgeStatus()
    -- 更新每个徽章的状态
    for _, badgeItem in ipairs(_badgeList) do
        local badgeId = badgeItem.badgeId
        local badgeData = ClientData.BadgeData[badgeId]
        
        if badgeData then
            -- 更新拥有状态
            badgeItem.hasBadge = badgeData.hasBadge
            
            local iconImage = badgeItem.button:FindFirstChild('IconImage')
            if badgeData.hasBadge then
                -- 已获得徽章：高亮显示
                if iconImage then
                    iconImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                    iconImage.ImageTransparency = 0
                end
            else
                -- 未获得徽章：调暗显示
                if iconImage then
                    iconImage.ImageColor3 = Color3.fromRGB(100, 100, 100)
                    iconImage.ImageTransparency = 0.5
                end
            end
        end
    end
end

--[[
显示徽章UI（打开界面时调用）
]]
local function ShowBadgeUI()
    -- 如果UI尚未创建，先尝试创建
    if not _badgeUICreated then
        local success = CreateBadgeUI()
        if not success then
            warn("无法创建徽章UI，请稍后再试")
            return
        end
    end
    
    -- 更新徽章状态（可能有新获得的徽章）
    UpdateBadgeStatus()
    
    -- 重置选中状态
    _selectedBadge = nil
    
    -- 默认选中第一个徽章
    if #_badgeList > 0 then
        local firstBadge = _badgeList[1]
        SelectBadge(firstBadge.button, firstBadge.info, firstBadge.hasBadge)
    end
    
    -- 手动触发一次画布大小更新
    local contentSize = _gridLayout.AbsoluteContentSize
    _scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + _gridLayout.CellPadding.Y.Scale * _scrollFrame.AbsoluteSize.Y + 20)
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    
    -- 注册显示徽章UI事件
    Knit.GetController('UIController').ShowBadgeUI:Connect(function()
        _screenGui.Enabled = true
        ShowBadgeUI()
    end)

    -- 注册徽章完成更新事件
    Knit.GetController('UIController').BadgeComplete:Connect(function()
        CreateBadgeUI()
    end)
end):catch(warn)