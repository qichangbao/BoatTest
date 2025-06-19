local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local GameConfig = require(ConfigFolder:WaitForChild('GameConfig'))
local LanguageConfig = require(ConfigFolder:WaitForChild('LanguageConfig'))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface'))
local Players = game:GetService('Players')
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))

local RADIUS = 40
local _isTriggered = {}

local function CheckPos()
    local boat = Interface.GetBoatByPlayerUserId(Players.LocalPlayer.UserId)
    if not boat then
        _isTriggered = {}
        return
    end
    
    local boatPosition = boat:GetPivot().Position
    -- 初始化陆地数据
    for _, landData in ipairs(GameConfig.IsLand) do
        local wharfPos = Vector3.new(
            landData.Position.X + landData.WharfInOffsetPos.X,
            0,
            landData.Position.Z + landData.WharfInOffsetPos.Z)
        local offset = Vector3.new(wharfPos.X - boatPosition.X, 0, wharfPos.Z - boatPosition.Z)
        local distance = offset.Magnitude
        if distance <= RADIUS then
            if _isTriggered[landData.Name] == true then
                break
            end
            Knit.GetController("UIController").ShowWharfUI:Fire(landData.Name)
            _isTriggered[landData.Name] = true
            break
        else
            if _isTriggered[landData.Name] then
                Knit.GetController("UIController").HideWharfUI:Fire()
            end
            _isTriggered[landData.Name] = nil
        end
    end
end

local function CreateIsLandOwnerModel(landName, playerName)
    local data = ClientData.IsLandOwners[landName]
    if not data then
        return
    end

    local landData = GameConfig.FindIsLand(landName)
    if not landData or not landData.OwnerModelOffsetPos then
        return
    end
    local model = Interface.CreateIsLandOwnerModel(data.userId)
    if model then
        local land = workspace:WaitForChild(landName)
        if not land then
            model:Destroy()
            return
        end
        local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.Anchored = true
        end

        model.Name = LanguageConfig.Get(10047) .. string.format(":%s", playerName)
        model:ScaleTo(8)
        model.Parent = land
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA('BasePart') then
                child.CanCollide = true
                child.CanTouch = false

                child.Material = Enum.Material.Slate
                child.Color = Color3.fromRGB(150, 150, 150)
                child.Reflectance = 0.2
            end
        end
        
        -- 获取原始CFrame的旋转部分
        local rotation = landData.OwnerModelOffsetPos - landData.OwnerModelOffsetPos.Position
        local newCFrame = CFrame.new(
            landData.Position.X + landData.OwnerModelOffsetPos.Position.X,
            landData.OwnerModelOffsetPos.Position.Y,
            landData.Position.Z + landData.OwnerModelOffsetPos.Position.Z
        ) * rotation
        model:PivotTo(newCFrame)
    end
end

-- 创建岛屿信息显示板，包含倒计时功能
local function CreateIslandBillboard(landName, lifetime)
    local isLand = workspace:FindFirstChild(landName)
    if not isLand then
        return
    end
    
    -- 创建BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 300, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 100, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = isLand
    billboard.MaxDistance = 600
    billboard.Name = "IslandBillboard"
    
    -- 创建背景框架
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    
    -- 添加圆角
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- 岛屿名称标签
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Text = "无名岛"
    nameLabel.Font = Enum.Font.ArialBold
    nameLabel.TextSize = 24
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = frame
    
    -- 倒计时标签
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(1, 0, 0.5, 0)
    countdownLabel.Position = UDim2.new(0, 0, 0.5, 0)
    countdownLabel.Font = Enum.Font.Arial
    countdownLabel.TextSize = 20
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextStrokeTransparency = 0.5
    countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    countdownLabel.Parent = frame
    
    billboard.Parent = isLand
    
    -- 倒计时逻辑
    local startTime = tick()
    local connection
    
    -- 格式化时间显示（分:秒）
    local function formatTime(seconds)
        local minutes = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%02d:%02d", minutes, secs)
    end
    
    -- 更新倒计时显示
    local function updateCountdown()
        -- 检测岛屿是否被销毁
        if not isLand or not isLand.Parent then
            -- 岛屿已被销毁，清理连接并销毁billboard
            if connection then
                connection:Disconnect()
                connection = nil
            end
            return
        end
        
        local elapsed = tick() - startTime
        local remaining = math.max(0, lifetime - elapsed)
        
        if remaining > 0 then
            countdownLabel.Text = "岛屿沉没剩余时间: " .. formatTime(remaining)
            
            -- 根据剩余时间改变颜色
            if remaining <= 30 then
                countdownLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- 红色警告
            elseif remaining <= 60 then
                countdownLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- 橙色提醒
            else
                countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- 黄色正常
            end
        else
            countdownLabel.Text = "即将沉没"
            countdownLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
    
    -- 开始倒计时更新
    connection = game:GetService("RunService").Heartbeat:Connect(updateCountdown)
    
    -- 初始更新
    updateCountdown()
end

local function RemoveIsland(islandName)
    local island = workspace:FindFirstChild(islandName)
    if not island then
        return
    end
    local billboard = island:FindFirstChild("IslandBillboard")
    if billboard then
        billboard:Destroy()
    end
end

Knit:OnStart():andThen(function()
    local UIController = Knit.GetController('UIController')
    UIController.IsLandOwner:Connect(function()
        for landName, landData in pairs(ClientData.IsLandOwners) do
            task.spawn(CreateIsLandOwnerModel, landName, landData.playerName)
        end
    end)
    UIController.IsLandOwnerChanged:Connect(function(landName, playerName)
        task.spawn(CreateIsLandOwnerModel, landName, playerName)
    end)

    Knit.GetService("LandService").CreateIsland:Connect(function(landName, lifetime)
        task.spawn(CreateIslandBillboard, landName, lifetime)
    end)

    Knit.GetService("LandService").RemoveIsland:Connect(function(landName)
        task.spawn(RemoveIsland, landName)
    end)

    game:GetService('RunService').RenderStepped:Connect(CheckPos)
end):catch(warn)