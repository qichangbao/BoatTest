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
    if not landData then
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

        model.Name = string.format(LanguageConfig.Get(10047), playerName)
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

local function CreateIslandBillboard()
    for _, v in ipairs(GameConfig.IsLand) do
        local isLand = workspace:WaitForChild(v.Name)
        if not isLand then
            continue
        end
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 100, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = isLand
        billboard.MaxDistance = 600
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = v.Name
        textLabel.Font = Enum.Font.Arimo
        textLabel.TextSize = 60
        textLabel.BackgroundTransparency = 1
        textLabel.Parent = billboard
        
        billboard.Parent = isLand
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

    task.spawn(CreateIslandBillboard)
    game:GetService('RunService').RenderStepped:Connect(CheckPos)
end):catch(warn)