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

-- 添加持续位置检测
game:GetService('RunService').Heartbeat:Connect(function()
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name:sub(1,11) == "PlayerBoat_" and child.PrimaryPart then
            local currentCFrame = child:GetPivot()
            local currentPos = currentCFrame.Position
            local newPosition = Vector3.new(currentPos.X, 20, currentPos.Z)
            local newCFrame = CFrame.new(newPosition) * CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
            child:PivotTo(newCFrame)
        end
    end
end)

print("客户端初始化完成")
