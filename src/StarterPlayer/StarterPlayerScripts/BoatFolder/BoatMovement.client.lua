local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)

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
    
    local BoatMovementService = Knit.GetService('BoatMovementService')
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
    
    local BoatMovementService = Knit.GetService('BoatMovementService')
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

Knit:OnStart():andThen(function()
    local BoatMovementService = Knit.GetService('BoatMovementService')
    BoatMovementService.isOnBoat:Connect(function(isOnBoat)
        _activeKeys = {}
        _moveDirection = Vector3.new()
        _moveAngular = Vector3.new()
        if isOnBoat then
            -- 设置摄像头朝向玩家面向的方向
            local camera = game.Workspace.CurrentCamera
            local player = Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
                local humanoidRootPart = player.Character.HumanoidRootPart
                -- 获取玩家当前朝向
                local lookDirection = humanoidRootPart.CFrame.LookVector
                -- 设置摄像头位置在玩家后方稍高的位置
                local cameraOffset = Vector3.new(0, 5, 10) -- 后方10单位，上方5单位
                local cameraPosition = humanoidRootPart.Position - lookDirection * cameraOffset.Z + Vector3.new(0, cameraOffset.Y, 0)
                -- 设置摄像头朝向玩家前方
                local targetPosition = humanoidRootPart.Position + lookDirection * 20
                camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
                camera.CameraType = Enum.CameraType.Custom
            end
        else
            -- 恢复默认摄像头
            local camera = game.Workspace.CurrentCamera
            camera.CameraType = Enum.CameraType.Custom
            if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild('Humanoid') then
                camera.CameraSubject = Players.LocalPlayer.Character.Humanoid
            end
        end
        print('玩家是否在船上：', isOnBoat)
    end)
end):catch(warn)