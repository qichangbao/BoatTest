local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local GameConfig = require(ConfigFolder:WaitForChild('GameConfig'))
local IslandConfig = require(ConfigFolder:WaitForChild('IslandConfig'))
local LanguageConfig = require(ConfigFolder:WaitForChild('LanguageConfig'))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface'))
local Players = game:GetService('Players')
local ClientData = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("ClientData"))
local IsLandPart = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("IsLandPart")

local _isTriggeredPlayerToBoat = false
local _isTriggeredBoatToLand = true
local _allLand = {} -- 所有岛屿

local function CheckPosFromBoatToLand(boat)
    local boatPosition = boat:GetPivot().Position
    -- 初始化陆地数据
    for _, landData in ipairs(_allLand) do
        local land = workspace:FindFirstChild(landData.Name)
        if not land then
            continue
        end
        local floor = land:FindFirstChild("Floor")
        if not floor then
            continue
        end
        local wharfMinPos = Vector3.new(
            floor.Position.X - floor.Size.X / 2 - GameConfig.LandWharfDis,
            0,
            floor.Position.Z - floor.Size.Z / 2 - GameConfig.LandWharfDis)
        local wharfMaxPos = Vector3.new(
            floor.Position.X + floor.Size.X / 2 + GameConfig.LandWharfDis,
            0,
            floor.Position.Z + floor.Size.Z / 2 + GameConfig.LandWharfDis)
        local isInWharf = false
        if boatPosition.X >= wharfMinPos.X and boatPosition.X <= wharfMaxPos.X and boatPosition.Z >= wharfMinPos.Z and boatPosition.Z <= wharfMaxPos.Z then
            isInWharf = true
        end

        if isInWharf then
            if _isTriggeredBoatToLand then
                break
            end
            Knit.GetController("UIController").ShowWharfUI:Fire(landData.Name)
            _isTriggeredBoatToLand = true
            break
        else
            if _isTriggeredBoatToLand then
                Knit.GetController("UIController").HideWharfUI:Fire()
            end
            _isTriggeredBoatToLand = false
        end
    end
end

local function CheckPosFromPlayerToBoat(boat)
    if _isTriggeredPlayerToBoat then
        return
    end
    if not Players.LocalPlayer.Character then
        _isTriggeredPlayerToBoat = false
        return
    end
    local boatPosition = boat:GetPivot().Position
    local playerPosition = Players.LocalPlayer.Character:GetPivot().Position
    local dis = (Vector3.new(boatPosition.X - playerPosition.X, 0, boatPosition.Z - playerPosition.Z)).Magnitude
    if dis <= GameConfig.PlayerToBoatDis then
        _isTriggeredPlayerToBoat = true
        Knit.GetController("UIController").ShowMessageBox:Fire({Content = LanguageConfig.Get(10083), OnConfirm = function()
            Knit.GetService("LandService"):PlayerToBoat(Players.LocalPlayer)
        end})
    else
        _isTriggeredPlayerToBoat = false
    end
end

local function CheckPos()
    if not Players.LocalPlayer.Character then
        return
    end
    local humanoid = Players.LocalPlayer.Character:FindFirstChild('Humanoid')
    if not humanoid then
        return
    end
    -- 特殊处理，玩家点了启航按钮，正在组装船，不触发检测，当玩家sit后触发检测
    if ClientData.IsBoatAssembling then
        if not humanoid.Sit then
            return
        end
        ClientData.IsBoatAssembling = false
    end
    local boat = Interface.GetBoatByPlayerUserId(Players.LocalPlayer.UserId)
    if boat then
        if humanoid.Sit then
            _isTriggeredPlayerToBoat = false
            CheckPosFromBoatToLand(boat)
        else
            _isTriggeredBoatToLand = true
            CheckPosFromPlayerToBoat(boat)
        end
    end
end

local function CreateIsLandOwnerModel(landName, playerName)
    local data = ClientData.IsLandOwners[landName]
    if not data then
        return
    end

    local landData = IslandConfig.FindIsLand(landName)
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

-- 创建岛屿信息板，倒计时
local function CreateBillBoard(land, name, lifetime)
    -- 创建岛屿信息显示板，包含倒计时功能
    -- 创建BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 300, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 30, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = land
    billboard.MaxDistance = 600
    billboard.Name = "IslandBillboard"
    billboard.Parent = land
    
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
    nameLabel.Text = name
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 24
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = frame
    
    if lifetime > 0 then
        -- 倒计时标签
        local countdownLabel = Instance.new("TextLabel")
        countdownLabel.Size = UDim2.new(1, 0, 0.5, 0)
        countdownLabel.Position = UDim2.new(0, 0, 0.5, 0)
        countdownLabel.Font = Enum.Font.SourceSansBold
        countdownLabel.TextSize = 20
        countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        countdownLabel.BackgroundTransparency = 1
        countdownLabel.TextStrokeTransparency = 0.5
        countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        countdownLabel.Parent = frame
        
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
            if not land or not land.Parent then
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
end

-- 创建岛屿的部件，信息板，倒计时
local function CreateIslandPart(landName, lifetime)
    local land = workspace:WaitForChild(landName)
    if not land then
        return
    end

    local landPos = land:GetPivot().Position
    
    -- 通知BoatAttributeUI更新指南针显示数据
    Knit.GetController("UIController").UpdateCompassIsland:Fire(landName, landPos)

    local partPosTable = {}
    for i, v in pairs(land:GetChildren()) do
        if string.match(v.Name, "PartPos") then
            table.insert(partPosTable, v.Value)
        end
    end
    if #partPosTable > 1 then
        local min = math.floor(#partPosTable * 0.3)
        local max = math.floor(#partPosTable * 0.6)
        if min > 0 and max > 0 and max > min then
            local num = math.random(min, max)
            local parts = IslandConfig.GetIslandPart(num)
            -- 打乱partPosTable数组
            for i = #partPosTable, 2, -1 do
                local j = math.random(1, i)
                partPosTable[i], partPosTable[j] = partPosTable[j], partPosTable[i]
            end
            for i = 1, num do
                local partData = parts[i]
                local pos = partPosTable[i]
                local PartTypeFolder = IsLandPart:FindFirstChild(partData.partType)
                if not PartTypeFolder then
                    continue
                end
                local partTemplate = PartTypeFolder:FindFirstChild(partData.partName)
                if not partTemplate then
                    continue
                end
                local part = partTemplate:Clone()
                pos = Interface.GetPartBottomPos(part, pos)
                pos += Vector3.new(math.random(-10, 10), 0, math.random(10, 10))
                part:PivotTo(CFrame.new(landPos + pos))
                part.Parent = land
            end
        end
    end
    
    CreateBillBoard(land, LanguageConfig.Get(10082), lifetime)

    local data = {
        Name = land.Name,
        Position = landPos,
    }

    table.insert(_allLand, data)
end

-- 移除岛屿函数
-- @param islandName: 岛屿名称
local function RemoveIsland(islandName)
    for i, v in ipairs(_allLand) do
        if v.Name == islandName then
            table.remove(_allLand, i)
            break
        end
    end

    local land = workspace:FindFirstChild(islandName)
    if not land then
        return
    end
    for _, child in ipairs(land:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Anchored = false
        end
    end
    local billboard = land:FindFirstChild("IslandBillboard")
    if billboard then
        billboard:Destroy()
    end
    
    -- 通知BoatAttributeUI移除指南针中的岛屿数据
    Knit.GetController("UIController").RemoveCompassIsland:Fire(islandName)
end

-- 初始化固定岛屿
for _, data in ipairs(IslandConfig.IsLand) do
    table.insert(_allLand, data)

    local land = workspace:WaitForChild(data.Name)
    CreateBillBoard(land, data.Name, -1)
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
        CreateIslandPart(landName, lifetime)
    end)

    Knit.GetService("LandService").RemoveIsland:Connect(function(landName)
        RemoveIsland(landName)
    end)

    game:GetService('RunService').RenderStepped:Connect(CheckPos)
end):catch(warn)