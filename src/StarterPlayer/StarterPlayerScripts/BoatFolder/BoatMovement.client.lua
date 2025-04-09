print('BoatMovement.lua loaded')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BoatMovementService = Knit.GetService('BoatMovementService')

local enabled = false

local moveDirection = Vector3.new()
local activeKeys = {}

-- 跟踪持续按键状态
UserInputService.InputBegan:Connect(function(input)
    if not enabled then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        activeKeys.W = true
    elseif input.KeyCode == Enum.KeyCode.S then
        activeKeys.S = true
    elseif input.KeyCode == Enum.KeyCode.A then
        activeKeys.A = true
    elseif input.KeyCode == Enum.KeyCode.D then
        activeKeys.D = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not enabled then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        activeKeys.W = false
    elseif input.KeyCode == Enum.KeyCode.S then
        activeKeys.S = false
    elseif input.KeyCode == Enum.KeyCode.A then
        activeKeys.A = false
    elseif input.KeyCode == Enum.KeyCode.D then
        activeKeys.D = false
    end
end)

-- 持续更新移动向量
game:GetService('RunService').Heartbeat:Connect(function()
    if not enabled then return end
    local combinedDirection = Vector3.new()
    
    if activeKeys.W then
        combinedDirection += Vector3.new(1, 0, 0)
    end
    if activeKeys.S then
        combinedDirection += Vector3.new(-1, 0, 0)
    end
    if activeKeys.A then
        combinedDirection += Vector3.new(0, 0, 1)
    end
    if activeKeys.D then
        combinedDirection += Vector3.new(0, 0, -1)
    end
    
    BoatMovementService:UpdateMovement(combinedDirection)
end)

BoatMovementService.isOnBoat:Connect(function(isOnBoat)
    enabled = isOnBoat
end)