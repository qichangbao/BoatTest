-- local ReplicatedStorage = game:GetService('ReplicatedStorage')
-- local UserInputService = game:GetService('UserInputService')
-- local Workspace = game:GetService('Workspace')
-- local LocalPlayer = game:GetService('Players').LocalPlayer

-- local BOAT_CONTROL_RE_NAME = 'BoatControlEvent'
-- local controlEvent = ReplicatedStorage:WaitForChild(BOAT_CONTROL_RE_NAME)

-- local STOP_BOAT_BE_NAME = 'StopBoatEventBE'
-- local stopEventBE = ReplicatedStorage:FindFirstChild(STOP_BOAT_BE_NAME) or Instance.new('BindableEvent')
-- stopEventBE.Name = STOP_BOAT_BE_NAME
-- stopEventBE.Parent = ReplicatedStorage

-- local driverSeat = nil

-- controlEvent.OnClientEvent:Connect(function(action)
--     if action == 'SetDriverSeat' then
--         local boat = Workspace:WaitForChild('PlayerBoat_'..LocalPlayer.UserId)
--         if boat then
--             driverSeat = boat:WaitForChild('DriverSeat')
--         end
--     elseif action == 'ClearDriverSeat' then
--         driverSeat = nil
--     end
-- end)

-- local function handleInput(input, state)
--     local directionMap = {
--         [Enum.KeyCode.W] = 'Forward',
--         [Enum.KeyCode.S] = 'Backward',
--         [Enum.KeyCode.A] = 'Left',
--         [Enum.KeyCode.D] = 'Right'
--     }
    
--     if directionMap[input.KeyCode] then
--         controlEvent:FireServer(directionMap[input.KeyCode], state)
--     end
-- end

-- UserInputService.InputBegan:Connect(function(input)
--     if not driverSeat then return end

--     if input.UserInputType == Enum.UserInputType.Keyboard then
--         handleInput(input, true)
--     end
-- end)

-- UserInputService.InputEnded:Connect(function(input)
--     if not driverSeat then return end

--     if input.UserInputType == Enum.UserInputType.Keyboard then
--         handleInput(input, false)
--     end
-- end)

-- stopEventBE.Event:Connect(function()
--     driverSeat = nil
-- end)