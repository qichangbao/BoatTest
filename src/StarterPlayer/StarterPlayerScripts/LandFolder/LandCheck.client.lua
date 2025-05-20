local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")
local GameConfig = require(ConfigFolder:WaitForChild('GameConfig'))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild('Interface'))
local Players = game:GetService('Players')

local RADIUS = 20
local _isTriggered = {}

local function CheckPos()
    local boat = Interface.GetBoatByPlayerUserId(Players.LocalPlayer.UserId)
    if not boat or not boat.PrimaryPart then
        _isTriggered = {}
        return
    end
    
    local boatCFrame = boat.PrimaryPart.CFrame or CFrame.new()
    -- 初始化陆地数据
    for _, landData in ipairs(GameConfig.TerrainType.IsLand) do
        local wharfPos = Vector3.new(
            landData.Position.X + landData.WharfOffsetPos.X,
            0,
            landData.Position.Z + landData.WharfOffsetPos.Z)
        local offset = Vector3.new(wharfPos.X - boatCFrame.Position.X, 0, wharfPos.Z - boatCFrame.Position.Z)
        local distance = offset.Magnitude
        if distance <= RADIUS then
            if _isTriggered[landData.Name] == true then
                break
            end
            Knit.GetController("UIController").ShowWharfUI:Fire(landData.Name)
            _isTriggered[landData.Name] = true
            break
        else
            _isTriggered[landData.Name] = nil
        end
    end
end

game:GetService('RunService').RenderStepped:Connect(CheckPos)