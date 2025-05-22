print("ServerScriptService start.lua loaded")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")

math.randomseed(os.time())

-- 初始化Knit框架
local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"):WaitForChild("Knit"))
Knit.AddServices(game.ServerScriptService.Services)
Knit.Start():andThen(function()
    print("Knit Server Started")
end):catch(warn)

local TriggerManager = require(ServerScriptService:WaitForChild("TriggerFolder"):WaitForChild("TriggerManager"))
TriggerManager.new()

PhysicsService:RegisterCollisionGroup('BoatCollisionGroup')
PhysicsService:RegisterCollisionGroup('WaveCollisionGroup')
PhysicsService:RegisterCollisionGroup('BoatStabilizerCollisionGroup')
PhysicsService:RegisterCollisionGroup('PlayerCollisionGroup')
PhysicsService:RegisterCollisionGroup('MonsterCollisionGroup')
PhysicsService:RegisterCollisionGroup('LandCollisionGroup')
-- 设置碰撞关系
PhysicsService:CollisionGroupSetCollidable('BoatCollisionGroup', 'WaveCollisionGroup', false)
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'PlayerCollisionGroup', false)
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'MonsterCollisionGroup', false)
PhysicsService:CollisionGroupSetCollidable('BoatStabilizerCollisionGroup', 'LandCollisionGroup', false)
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

print("服务器脚本初始化完成")