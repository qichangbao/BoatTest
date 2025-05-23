local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local GameConfig = require(ConfigFolder:WaitForChild('GameConfig'))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface'))
local Players = game:GetService('Players')

local RADIUS = 20
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

game:GetService('RunService').RenderStepped:Connect(CheckPos)