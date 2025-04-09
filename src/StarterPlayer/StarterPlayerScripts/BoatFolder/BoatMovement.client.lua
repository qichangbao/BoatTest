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
        if activeKeys.W then return end
        activeKeys.W = true
        BoatMovementService:UpdateVelocity(Vector3.new(1, 0, 0))
    elseif input.KeyCode == Enum.KeyCode.S then
        if activeKeys.S then return end
        activeKeys.S = true
        BoatMovementService:UpdateVelocity(Vector3.new(-1, 0, 0))
    elseif input.KeyCode == Enum.KeyCode.A then
        if activeKeys.A then return end
        activeKeys.A = true
        BoatMovementService:UpdateAngular(Vector3.new(0, 0, 1))
    elseif input.KeyCode == Enum.KeyCode.D then
        if activeKeys.D then return end
        activeKeys.D = true
        BoatMovementService:UpdateAngular(Vector3.new(0, 0, -1))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not enabled then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        activeKeys.W = false
        BoatMovementService:UpdateVelocity()
    elseif input.KeyCode == Enum.KeyCode.S then
        activeKeys.S = false
        BoatMovementService:UpdateVelocity()
    elseif input.KeyCode == Enum.KeyCode.A then
        activeKeys.A = false
        BoatMovementService:UpdateAngular()
    elseif input.KeyCode == Enum.KeyCode.D then
        activeKeys.D = false
        BoatMovementService:UpdateAngular()
    end
end)

-- -- 持续更新移动向量
-- game:GetService('RunService').Heartbeat:Connect(function()
--     if not enabled then return end
--     local combinedDirection = Vector3.new()
    
--     if activeKeys.W then
--         combinedDirection += Vector3.new(0, 0, 1)
--     end
--     if activeKeys.S then
--         combinedDirection += Vector3.new(0, 0, -1)
--     end
--     if activeKeys.A then
--         combinedDirection += Vector3.new(0, 0, 1)
--     end
--     if activeKeys.D then
--         combinedDirection += Vector3.new(0, 0, -1)
--     end

--     if combinedDirection == Vector3.new() then
--         return
--     end
    
--     BoatMovementService:UpdateMovement(combinedDirection)
-- end)

BoatMovementService.isOnBoat:Connect(function(isOnBoat)
    enabled = isOnBoat
end)