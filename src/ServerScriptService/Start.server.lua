local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")
local GameConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("GameConfig"))

math.randomseed(os.time())

-- 初始化Knit框架
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
Knit.AddServices(game.ServerScriptService.Services)
Knit.Start():andThen(function()
end):catch(warn)

-- 时间系统配置
local _gameTime = 12 -- 游戏时间（小时，0-24）
local _lastUpdateTime = tick() -- 上次更新的真实时间

-- 时间系统更新函数
-- @param deltaTime number 距离上次更新的真实时间间隔（秒）
local function updateGameTime(deltaTime)
    -- 计算游戏时间增量（小时）
    local gameTimeIncrement = (deltaTime * GameConfig.Real_To_Game_Second) / 3600
    
    -- 更新游戏时间
    _gameTime = _gameTime + gameTimeIncrement
    
    -- 确保时间在0-24小时范围内循环
    if _gameTime >= 24 then
        _gameTime = _gameTime - 24
    elseif _gameTime < 0 then
        _gameTime = _gameTime + 24
    end
    
    -- 更新Lighting的ClockTime
    Lighting.ClockTime = _gameTime
end

-- 连接到Heartbeat事件进行实时更新
game:GetService("RunService").Heartbeat:Connect(function(dt)
    local currentTime = tick()
    local deltaTime = currentTime - _lastUpdateTime
    
    -- 更新游戏时间
    updateGameTime(deltaTime)
    
    -- 记录当前时间用于下次计算
    _lastUpdateTime = currentTime
end)

local TriggerManager = require(ServerScriptService:WaitForChild("TriggerFolder"):WaitForChild("TriggerManager"))
TriggerManager.new()

PhysicsService:RegisterCollisionGroup('BoatCollisionGroup')
PhysicsService:RegisterCollisionGroup('BoatStabilizerCollisionGroup')
PhysicsService:RegisterCollisionGroup('PlayerCollisionGroup')
PhysicsService:RegisterCollisionGroup('MonsterCollisionGroup')
PhysicsService:RegisterCollisionGroup('LandCollisionGroup')
-- 设置碰撞关系
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'PlayerCollisionGroup', false)
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'MonsterCollisionGroup', false)
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'LandCollisionGroup', false)
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'BoatStabilizerCollisionGroup', false)
-- 在装配船只时初始化碰撞组
local function setupBoatCollisionGroup(boatModel)
    -- 给所有部件设置碰撞组
    for _, part in ipairs(boatModel:GetDescendants()) do
        if part:IsA('BasePart') then
            part.CollisionGroup = 'BoatCollisionGroup'
        end
    end
end
setupBoatCollisionGroup(ServerStorage:WaitForChild("船"))

print("服务器ID：", game.JobId)
print("服务器ID：", game.GameId)
print("服务器ID：", game.PlaceId)
print("服务器名称：", game.Name)