print("客户端初始化中...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFolder = ReplicatedStorage:WaitForChild("ConfigFolder")

-- 加载地形配置模块
local GameConfig = require(ConfigFolder:WaitForChild("GameConfig"))

-- 初始化地形系统
local TerrainFolder = script.Parent:WaitForChild("TerrainFolder")
if not TerrainFolder then
    error("地形生成器文件夹不存在！")
end
local TerrainManager = require(TerrainFolder:WaitForChild("TerrainManager", 5)).new(GameConfig)
TerrainManager:Init()

print("客户端初始化完成")