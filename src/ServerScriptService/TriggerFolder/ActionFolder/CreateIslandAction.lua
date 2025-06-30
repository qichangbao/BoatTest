local ReplicatedStorage = game.ReplicatedStorage
local ServerStorage = game.ServerStorage
local ActionBase = require(script.Parent:WaitForChild("ActionBase"))
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local Interface = require(ReplicatedStorage:WaitForChild("ToolFolder"):WaitForChild("Interface"))
local IslandConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("IslandConfig"))

local CreateIslandAction = {}
setmetatable(CreateIslandAction, ActionBase)
CreateIslandAction.__index = CreateIslandAction

function CreateIslandAction.new(config, condition)
    local self = setmetatable(ActionBase.new(config, condition), CreateIslandAction)
    self.destroyToResetCondition = config.DestroyToResetCondition or false
    self.ResetConditionDelayTime = config.ResetConditionDelayTime or {0, 0}
    return self
end

function CreateIslandAction:Execute(data)
    ActionBase.Execute(self)

    print("执行CreateIslandAction")

    -- 确定宝箱生成位置
    local position = self.position
    if self.config.UsePlayerPosition and self.config.PositionOffset and data and data.Player and data.Player.Character then
        local player = data.Player
        local frame = player.Character:GetPivot()
        position = frame.Position
        local baseOffset = frame.LookVector * self.config.PositionOffset -- 船头前方偏移
        
        -- 添加小范围随机偏移 (-5到5米的随机范围)
        local randomX = math.random(-200, 200)
        local randomZ = math.random(-200, 200)
        local randomOffset = Vector3.new(randomX, 0, randomZ)
        
        self.position = Vector3.new(position.X + baseOffset.X + randomOffset.X, randomOffset.Y, position.Z + baseOffset.Z + randomOffset.Z)
    end
    
    local islandData = IslandConfig.GetRandomIsland()
    local island = Knit.GetService("LandService"):CreateIsland(islandData.ModelName, self.position, self.config.Lifetime)
    if island then
        if self.config.Lifetime > 0 then
            task.delay(self.config.Lifetime, function()
                Knit.GetService("LandService"):RemoveIsland(island.Name)
            end)
        end
    end
end

-- 检测指定位置范围内是否有岛屿
-- @param position Vector3 检测位置
-- @param radius number 检测半径
-- @return boolean 是否有岛屿
function CreateIslandAction:CheckIslandInRange(position, radius)
    -- 遍历workspace中的所有岛屿模型
    local allLand = Knit.GetService("LandService"):GetAllLand()
    for landName, _ in pairs(allLand) do
        local land = workspace:FindFirstChild(landName)
        if land then
            local islandPosition = land:GetPivot().Position
            local distance = (position - islandPosition).Magnitude
            
            -- 如果距离小于指定半径，则认为范围内有岛屿
            if distance < radius then
                print(string.format("发现附近岛屿: %s, 距离: %.2f米", landName, distance))
                return true
            end
        end
    end
    
    return false
end

return CreateIslandAction