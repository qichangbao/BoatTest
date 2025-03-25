local MaterialConfig = require(script.Parent.Parent:WaitForChild("ConfigFolder"):WaitForChild("MaterialConfig"))
--[[
船舶管理系统
版本 1.0.0
功能：
- 管理船舶材料配置
- 计算船舶健康值
- 控制部件解锁逻辑
]]
local ShipManager = {}
ShipManager.__index = ShipManager

--[[
构造函数
@return table 新的船舶管理器实例
]]
function ShipManager.new()
    local self = setmetatable({}, ShipManager)
    self.shipData = {
        materials = {},
        totalHealth = 100,
        unlockedParts = 1
    }
    return self
end

--[[
添加船舶材料
@param materialTier number 材料等级（1-3）
触发：
- 更新材料列表
- 重新计算总健康值
- 解锁新部件（每3个材料解锁1个）
]]
function ShipManager:AddMaterial(materialTier)
    table.insert(self.shipData.materials, materialTier)
    
    -- 计算新属性
    local newHealth = 0
    -- 遍历所有材料累加健康值
for _,tier in pairs(self.shipData.materials) do
        newHealth = newHealth + MaterialConfig.GetTierData(tier).health
    end
    
    -- 取历史最高健康值（防止维修降低耐久）
self.shipData.totalHealth = math.max(newHealth, self.shipData.totalHealth)
    -- 解锁新部件逻辑（每3个材料解锁1个，最多4个部件）
self.shipData.unlockedParts = math.min(#self.shipData.materials + 1, 4)
end

--[[
判断是否可以建造新部件
@return boolean 当前材料是否满足解锁条件
解锁规则：
- 每解锁1个部件需要3个材料
- 基础解锁部件数为1
]]
function ShipManager:CanBuildPart()
    return #self.shipData.materials >= (self.shipData.unlockedParts * 3)
end

return ShipManager