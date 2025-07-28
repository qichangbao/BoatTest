local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild('GameConfig'))
local IslandConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("IslandConfig"))

local Interface = {}

-- 初始化玩家位置
function Interface.InitPlayerPos(player)
    local curAreaTemplate = player:GetAttribute("CurAreaTemplate")
    local area = nil
    if curAreaTemplate then
        area = workspace:FindFirstChild(curAreaTemplate)
    end

    local spawnLocation = nil
    if area then
        spawnLocation = area:WaitForChild("SpawnLocation")
    end

    if not spawnLocation then
        spawnLocation = player.RespawnLocation
    end

    if spawnLocation and player.Character then
        local humanoid = player.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Sit = false
        end
        player.Character:PivotTo(spawnLocation.CFrame + Vector3.new(math.random(5, 10), 6, math.random(5, 10)))
        return spawnLocation.Parent.Name
    end
    return nil
end

-- 初始化船的位置
-- 初始化船只在水中的位置，让船头朝向海的方向
function Interface.InitBoatWaterPos(player, boat, revivePos)
    local x = 0
    local z = 0
    -- 使用适当的水面高度，而不是0
    local waterLevel = 2 -- 根据oldCFrame的Y坐标设置合适的水面高度
    if revivePos then   -- 如果是原地复活
        x = revivePos.X
        z = revivePos.Z
    else
        local curAreaTemplate = player:GetAttribute("CurAreaTemplate")
        local area = nil
        if curAreaTemplate then
            area = workspace:FindFirstChild(curAreaTemplate)
        end

        local spawnLocation = nil
        if area then
            spawnLocation = area:WaitForChild("SpawnLocation")
        end

        if not spawnLocation then
            spawnLocation = player.RespawnLocation
        end
        player:SetAttribute("CurAreaTemplate", nil)
        if spawnLocation and player.Character then
            local land = spawnLocation.Parent
            local floor = land:FindFirstChild("Floor")
            if not floor then
                return
            end
            local minPosX = floor.Position.X - floor.Size.X / 2
            local maxPosX = floor.Position.X + floor.Size.X / 2
            local minPosZ = floor.Position.Z - floor.Size.Z / 2
            local maxPosZ = floor.Position.Z + floor.Size.Z / 2
            local randomPosX = math.random(-10, 10)
            local randomPosZ = math.random(-10, 10)
            if randomPosX < 0 then
                x = minPosX + randomPosX - GameConfig.LandWharfDis
            else
                x = maxPosX + randomPosX + GameConfig.LandWharfDis
            end
            if randomPosZ < 0 then
                z = minPosZ + randomPosZ - GameConfig.LandWharfDis
            else
                z = maxPosZ + randomPosZ + GameConfig.LandWharfDis
            end
        end
    end

    boat:PivotTo(CFrame.new(Vector3.new(x, waterLevel, z)))

    task.wait(0.1)
    -- 玩家登船
    Interface.PlayerToBoat(player, boat)
end

-- 玩家登船
function Interface.PlayerToBoat(player, boat)
    if not player or not player.Character or not boat then
        return
    end

    -- 玩家入座
    local driverSeat = boat:FindFirstChild('VehicleSeat')
    if driverSeat then
        player.Character:PivotTo(driverSeat.CFrame)
    end
end

-- 通过玩家ID获取船
function Interface.GetBoatByPlayerUserId(userId)
    return workspace:FindFirstChild('PlayerBoat_' .. userId)
end

-- 判断是否在陆地上
function Interface.IsInLand(boat)
    local landConfig = IslandConfig.IsLand
    local pos = boat.PrimaryPart.Position
    for _, landData in ipairs(landConfig) do
        local land = workspace:WaitForChild(landData.Name):WaitForChild("Floor")
        local min = land.Position - land.Size / 2
        local max = land.Position + land.Size / 2
        if pos.X >= min.X and pos.X <= max.X and pos.Z >= min.Z and pos.Z <= max.Z then
            return true
        end
    end

    return false
end

function Interface.CreateIsLandOwnerModel(userId)
    local success, model = pcall(function()
        if userId <= 0 then
            return Players:CreateHumanoidModelFromUserId(7689724124)
        end
        return Players:CreateHumanoidModelFromUserId(userId)
    end)
    
    if success then
        return model
    else
        warn('无法创建玩家模型: ' .. tostring(model))
        return nil
    end
end

-- 获取模型底部位置
function Interface.GetPartBottomPos(model, targetPosition)
    -- 获取模型的包围盒
    local cf, size
    if model:IsA("Model") then
        cf, size = model:GetBoundingBox()
    elseif model:IsA("BasePart") then
        size = model.Size
    end
    
    if not size then
        return
    end
    -- 计算模型底部到中心的距离
    local bottomOffset = size.Y / 2
    
    -- 设置模型位置，Y坐标为地面高度加上底部偏移
    local groundY = targetPosition.Y -- 岛屿地面的Y坐标
    local newPosition = Vector3.new(
        targetPosition.X,
        groundY + bottomOffset,
        targetPosition.Z
    )
    
    return newPosition
end

-- 检测指定位置和大小范围内是否有物体
-- @param pos Vector3 检测区域的中心位置
-- @param size Vector3 检测区域的大小
-- @return boolean 如果范围内有物体返回true，否则返回false
-- @return table 范围内找到的所有Part列表
function Interface.CheckPosHasPart(pos, size)
    -- 计算检测区域的边界
    local halfSize = size / 2
    local minPoint = pos - halfSize
    local maxPoint = pos + halfSize
    
    -- 创建Region3用于检测
    local region = Region3.new(minPoint, maxPoint)
    
    -- 扩展region以确保边界正确
    region = region:ExpandToGrid(4)
    
    -- 存储找到的Part
    local foundParts = {}
    
    -- 遍历workspace中的所有Part
    local function checkDescendants(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Folder") then
                -- 递归检查子对象
                checkDescendants(child)
            else
                local partPos
                local partSize
                if child.Name == "Terrain" then
                    continue
                end
                
                if child:IsA("BasePart") then
                    -- 检查Part是否在指定区域内
                    partPos = child.Position
                    partSize = child.Size
                    
                    -- 计算Part的边界
                    local partMin = partPos - partSize / 2
                    local partMax = partPos + partSize / 2
                    
                    -- 检查是否有重叠
                    local hasOverlap = (
                        partMax.X > minPoint.X and partMin.X < maxPoint.X and
                        partMax.Y > minPoint.Y and partMin.Y < maxPoint.Y and
                        partMax.Z > minPoint.Z and partMin.Z < maxPoint.Z
                    )
                    
                    if hasOverlap then
                        table.insert(foundParts, child)
                    end
                elseif child:IsA("Model")then
                    partPos = child:GetPivot().Position
                    partSize = child:GetExtentsSize()
                    
                    -- 计算Part的边界
                    local partMin = partPos - partSize / 2
                    local partMax = partPos + partSize / 2
                    
                    -- 检查是否有重叠
                    local hasOverlap = (
                        partMax.X > minPoint.X and partMin.X < maxPoint.X and
                        partMax.Y > minPoint.Y and partMin.Y < maxPoint.Y and
                        partMax.Z > minPoint.Z and partMin.Z < maxPoint.Z
                    )
                    
                    if hasOverlap then
                        table.insert(foundParts, child)
                    end
                end
            end
        end
    end
    
    -- 开始检测workspace
    checkDescendants(workspace)
    
    -- 返回是否找到物体和找到的Part列表
    return #foundParts > 0, foundParts
end

function Interface.AwardBadge(userId, badgeId)
    -- 检查玩家是否拥有徽章
	local success, hasBadge = pcall(function()
		return game:GetService("BadgeService"):UserHasBadgeAsync(userId, badgeId)
	end)
    if success and not hasBadge then
        -- 首先检查徽章是否启用
        local badgeInfoSuccess, badgeInfo = pcall(function()
            return game:GetService("BadgeService"):GetBadgeInfoAsync(badgeId)
        end)
        
        if badgeInfoSuccess and badgeInfo.IsEnabled then
            -- 奖励徽章
            pcall(function()
                return game:GetService("BadgeService"):AwardBadge(userId, badgeId)
            end)
        else
            warn("BoatAssemblingService: 徽章未启用或获取徽章信息失败")
        end
    end
end

return Interface