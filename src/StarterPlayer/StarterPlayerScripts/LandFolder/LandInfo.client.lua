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

local RADIUS = 40
local _isTriggered = {}
local _allLand = {} -- 所有岛屿
for i, data in ipairs(IslandConfig.IsLand) do
    _allLand[data.Name] = data
end

local function CheckPos()
    local boat = Interface.GetBoatByPlayerUserId(Players.LocalPlayer.UserId)
    if not boat then
        _isTriggered = {}
        return
    end
    
    local boatPosition = boat:GetPivot().Position
    -- 初始化陆地数据
    for _, landData in pairs(_allLand) do
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

-- 创建岛屿的部件，信息板，倒计时
local function CreateIslandPart(landName, lifetime)
    local land = workspace:WaitForChild(landName)
    if not land then
        return
    end

    local landPos = land:GetPivot().Position
    
    -- 通知BoatAttributeUI更新指南针显示数据
    local wharfPos = land:FindFirstChild("WharfPos")
    if wharfPos then
        local compassPosition = Vector3.new(
            landPos.X + wharfPos.Value.X,
            wharfPos.Value.Y,
            landPos.Z + wharfPos.Value.Z
        )
        Knit.GetController("UIController").UpdateCompassIsland:Fire(landName, compassPosition)
    end

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
    
    -- 创建岛屿信息显示板，包含倒计时功能
    -- 创建BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 300, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 30, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = land
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
    nameLabel.Text = LanguageConfig.Get(10082)
    nameLabel.Font = Enum.Font.SourceSansBold
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
    countdownLabel.Font = Enum.Font.SourceSansBold
    countdownLabel.TextSize = 20
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextStrokeTransparency = 0.5
    countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    countdownLabel.Parent = frame
    
    billboard.Parent = land
    
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

    local data = {
        Name = land.Name,
        Position = landPos,
        WharfInOffsetPos = land:FindFirstChild("WharfPos").Value,
        WharfOutOffsetPos = land:FindFirstChild("WharfPos").Value,
    }
    _allLand[land.Name] = data
end

-- 移除岛屿函数
-- @param islandName: 岛屿名称
local function RemoveIsland(islandName)
    _allLand[islandName] = nil
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

    Knit.GetService("LandService").CreateIsland:Connect(function(landName, id, lifetime)
        CreateIslandPart(landName, id, lifetime)
    end)

    Knit.GetService("LandService").RemoveIsland:Connect(function(landName)
        RemoveIsland(landName)
    end)

    game:GetService('RunService').RenderStepped:Connect(CheckPos)
end):catch(warn)