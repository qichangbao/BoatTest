local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')
local UserInputService = game:GetService('UserInputService')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local ClientData = require(StarterPlayer:WaitForChild('StarterPlayerScripts'):WaitForChild("ClientData"))

local _moveDirection = Vector3.new()
local _moveAngular = Vector3.new()
local _activeKeys = {}

-- 触摸控制相关变量
local _touchStartPosition = nil
local _isTouching = false
local _joystickDeadzone = 0.1  -- 摇杆死区
local _joystickMaxDistance = 100  -- 摇杆最大距离

local function CanInput()
    local boat = game.Workspace:FindFirstChild('PlayerBoat_'..Players.LocalPlayer.UserId)
    if not boat then
        return false
    end
    local driverSeat = boat:FindFirstChild('VehicleSeat')
    if not driverSeat or not driverSeat.Occupant then
        return false
    end
    return true
end

-- 计算虚拟摇杆输入的函数
-- @param startPos Vector2 触摸开始位置
-- @param currentPos Vector2 当前触摸位置
-- @return Vector2 标准化的摇杆输入值 (-1到1)
local function calculateJoystickInput(startPos, currentPos)
    local delta = currentPos - startPos
    local distance = delta.Magnitude
    
    -- 如果距离小于死区，返回零向量
    if distance < _joystickDeadzone then
        return Vector2.new(0, 0)
    end
    
    -- 限制最大距离
    if distance > _joystickMaxDistance then
        delta = delta.Unit * _joystickMaxDistance
        distance = _joystickMaxDistance
    end
    
    -- 标准化到-1到1的范围
    local normalizedInput = delta / _joystickMaxDistance
    return normalizedInput
end

-- 更新船只移动的函数（摇杆控制专用）
-- @param joystickInput Vector2 摇杆输入值
-- 摇杆控制兼容两种模式：移动模式和旋转模式
local function updateBoatMovement(joystickInput)
    local BoatMovementService = Knit.GetService('BoatMovementService')
    
    -- 增加摇杆敏感度，让较小的移动就能达到最大效果
    local sensitivity = 2.5  -- 敏感度倍数，可以调整
    local amplifiedInput = Vector2.new(
        math.clamp(joystickInput.X * sensitivity, -1, 1),
        math.clamp(joystickInput.Y * sensitivity, -1, 1)
    )
    
    -- 计算输入的主要方向
    local absX = math.abs(amplifiedInput.X)
    local absY = math.abs(amplifiedInput.Y)
    
    -- 智能模式切换：根据输入的主要方向决定控制方式
      if absY > absX * 1.5 then
          -- 主要是前后移动：纯移动模式（类似W/S键）
          _moveDirection = Vector3.new(0, 0, amplifiedInput.Y)
          _moveAngular = Vector3.new(0, 0, 0)
      elseif absX > absY * 1.5 then
          -- 主要是左右移动：纯旋转模式（类似A/D键）
          _moveDirection = Vector3.new(0, 0, 0)
          _moveAngular = Vector3.new(0, -amplifiedInput.X, 0)
      else
          -- 复合操作：同时移动和旋转
          _moveDirection = Vector3.new(0, 0, amplifiedInput.Y)
          _moveAngular = Vector3.new(0, -amplifiedInput.X, 0)
      end
    
    -- 添加调试信息
    print(string.format("客户端移动 - 原始输入: %s, 放大输入: %s, 移动方向: %s, 旋转: %s", 
        tostring(joystickInput), tostring(amplifiedInput), tostring(_moveDirection), tostring(_moveAngular)))
    
    BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
end

-- 触摸控制事件监听（始终启用）
-- 检查是否为移动设备（保留注释但移除条件判断）
if true then  -- 改为始终启用触摸控制
    -- 监听触摸开始事件
    UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
        if not CanInput() then return end
        --if gameProcessed then return end
        
        -- 记录触摸开始位置
        _touchStartPosition = touch.Position
        _isTouching = true
        
        print("触摸开始:", touch.Position)
    end)
    
    -- 监听触摸移动事件
    UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
        if not CanInput() then return end
        --if gameProcessed then return end
        if not _isTouching or not _touchStartPosition then return end
        
        -- 计算摇杆输入
        local joystickInput = calculateJoystickInput(_touchStartPosition, touch.Position)
        
        -- 更新船只移动
        updateBoatMovement(joystickInput)
        
        print("触摸移动:", touch.Position, "摇杆输入:", joystickInput)
    end)
    
    -- 监听触摸结束事件
    UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
        if not CanInput() then return end
       -- if gameProcessed then return end
        
        -- 重置触摸状态
        _touchStartPosition = nil
        _isTouching = false
        
        -- 停止船只移动
        _moveDirection = Vector3.new(0, 0, 0)
        _moveAngular = Vector3.new(0, 0, 0)
        
        local BoatMovementService = Knit.GetService('BoatMovementService')
        BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
        
        print("触摸结束:", touch.Position)
    end)
end

-- 键盘控制事件监听（始终启用，兼容触摸设备）
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
            _moveAngular = Vector3.new(0, 1, 0)  -- 修正：使用Y轴旋转
            BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
        elseif input.KeyCode == Enum.KeyCode.D then
            if _activeKeys.D then return end
            _activeKeys.D = true
            _moveAngular = Vector3.new(0, -1, 0)  -- 修正：使用Y轴旋转
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
            _moveAngular = Vector3.new(0, 0, 0)  -- 停止旋转
            BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
        elseif input.KeyCode == Enum.KeyCode.D then
            _activeKeys.D = false
            _moveAngular = Vector3.new(0, 0, 0)  -- 停止旋转
            BoatMovementService:UpdateMovement(_moveDirection, _moveAngular)
        end
    end)

Knit:OnStart():andThen(function()
    local BoatMovementService = Knit.GetService('BoatMovementService')
    BoatMovementService.isOnBoat:Connect(function(isOnBoat)
        ClientData.IsOnBoat = isOnBoat
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