print('BoatMovement.lua loaded')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local BoatMovementService = Knit.GetService('BoatMovementService')

local _moveDirection = Vector3.new()
local _moveAngular = Vector3.new()
local _activeKeys = {}

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
        if _activeKeys.W then return end
        _activeKeys.W = true
        _moveDirection = Vector3.new(0, 0, -1)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    elseif input.KeyCode == Enum.KeyCode.S then
        if _activeKeys.S then return end
        _activeKeys.S = true
        _moveDirection = Vector3.new(0, 0, 1)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    elseif input.KeyCode == Enum.KeyCode.A then
        if _activeKeys.A then return end
        _activeKeys.A = true
        _moveAngular = Vector3.new(0, 0, 1)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    elseif input.KeyCode == Enum.KeyCode.D then
        if _activeKeys.D then return end
        _activeKeys.D = true
        _moveAngular = Vector3.new(0, 0, -1)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not CanInput() then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        _activeKeys.W = false
        _moveDirection = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    elseif input.KeyCode == Enum.KeyCode.S then
        _activeKeys.S = false
        _moveDirection = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    elseif input.KeyCode == Enum.KeyCode.A then
        _activeKeys.A = false
        _moveAngular = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    elseif input.KeyCode == Enum.KeyCode.D then
        _activeKeys.D = false
        _moveAngular = Vector3.new(0, 0, 0)
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
    end
end)

BoatMovementService.isOnBoat:Connect(function(isOnBoat)
    _activeKeys = {}
    _moveDirection = Vector3.new()
    _moveAngular = Vector3.new()
    print('玩家是否在船上：', isOnBoat)
end)