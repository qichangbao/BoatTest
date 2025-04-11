print('BoatMovement.lua loaded')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BoatMovementService = Knit.GetService('BoatMovementService')

local moveDirection = Vector3.new()
local moveAngular = Vector3.new()
local activeKeys = {}

local function CanInput()
    local boat = game.Workspace:FindFirstChild('PlayerBoat_'..Players.LocalPlayer.UserId)
    if not boat then
        return false
    end
    local driverSeat = boat:FindFirstChild('DriverSeat')
    if not driverSeat or not driverSeat.Occupant then
        return false
    end
    return true
end

-- 跟踪持续按键状态
UserInputService.InputBegan:Connect(function(input)
    if not CanInput() then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        if activeKeys.W then return end
        activeKeys.W = true
        moveDirection = Vector3.new(0, 0, -1)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    elseif input.KeyCode == Enum.KeyCode.S then
        if activeKeys.S then return end
        activeKeys.S = true
        moveDirection = Vector3.new(0, 0, 1)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    elseif input.KeyCode == Enum.KeyCode.A then
        if activeKeys.A then return end
        activeKeys.A = true
        moveAngular = Vector3.new(0, 0, 1)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    elseif input.KeyCode == Enum.KeyCode.D then
        if activeKeys.D then return end
        activeKeys.D = true
        moveAngular = Vector3.new(0, 0, -1)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not CanInput() then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        activeKeys.W = false
        moveDirection = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    elseif input.KeyCode == Enum.KeyCode.S then
        activeKeys.S = false
        moveDirection = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    elseif input.KeyCode == Enum.KeyCode.A then
        activeKeys.A = false
        moveAngular = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    elseif input.KeyCode == Enum.KeyCode.D then
        activeKeys.D = false
        moveAngular = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(moveDirection, moveAngular)
    end
end)

BoatMovementService.isOnBoat:Connect(function(isOnBoat)
    activeKeys = {}
    moveDirection = Vector3.new()
    moveAngular = Vector3.new()
    print('玩家是否在船上：', isOnBoat)
end)