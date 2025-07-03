-- 充值购买配置表
-- 专门用于船只购买功能

local PurchaseConfig = {}

-- 商品类型枚举
PurchaseConfig.ProductType = {
    BOAT = "船只"
}

-- Roblox开发者产品ID映射表（需要在Roblox开发者控制台中创建）
-- 注意：以下是示例ID，您需要在Roblox开发者控制台中创建真实的开发者产品并替换这些ID
-- 创建步骤：
-- 1. 访问 https://create.roblox.com/dashboard/creations
-- 2. 选择您的游戏 -> 货币化 -> 开发者产品
-- 3. 创建新的开发者产品，设置名称、描述和价格
-- 4. 复制产品ID并替换下面的示例ID
PurchaseConfig.DeveloperProductIds = {
    ["speed_boat"] = 0, -- 请替换为真实的开发者产品ID
    ["luxury_yacht"] = 0, -- 请替换为真实的开发者产品ID
    ["battle_cruiser"] = 0, -- 请替换为真实的开发者产品ID
    ["diamond_cruiser"] = 0, -- 请替换为真实的开发者产品ID
}

-- 船只商品配置表
PurchaseConfig.Products = {
    ["speed_boat"] = {
        id = "speed_boat",
        name = "极速快艇",
        description = "轻巧快速的小型船只，适合探索和快速移动",
        price = 299, -- Robux价格
        productType = PurchaseConfig.ProductType.BOAT,
        boatModel = "极速快艇",
        stats = {
            speed = 25,
            health = 100,
            capacity = 2
        },
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        sortOrder = 1
    },
    
    ["luxury_yacht"] = {
        id = "luxury_yacht",
        name = "豪华游艇",
        description = "奢华舒适的大型游艇，拥有宽敞的空间和优雅的外观",
        price = 599,
        productType = PurchaseConfig.ProductType.BOAT,
        boatModel = "豪华游艇",
        stats = {
            speed = 15,
            health = 300,
            capacity = 8
        },
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        sortOrder = 2
    },
    
    ["battle_cruiser"] = {
        id = "battle_cruiser",
        name = "战斗巡洋舰",
        description = "强大的军用舰艇，装备精良，适合战斗和防御",
        price = 999,
        productType = PurchaseConfig.ProductType.BOAT,
        boatModel = "战斗巡洋舰",
        stats = {
            speed = 20,
            health = 500,
            capacity = 6,
            weapons = {"大炮", "鱼雷"}
        },
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        sortOrder = 3
    },
    
    ["diamond_cruiser"] = {
        id = "diamond_cruiser",
        name = "钻石巡洋舰",
        description = "华丽的钻石巡洋舰，速度与美观并存",
        price = 1499,
        productType = PurchaseConfig.ProductType.BOAT,
        boatModel = "钻石巡洋舰",
        stats = {
            speed = 30,
            health = 400,
            capacity = 4,
            special = "钻石装饰"
        },
        icon = "rbxasset://textures/ui/GuiImagePlaceholder.png",
        sortOrder = 4
    }
}

-- 根据类型获取商品列表
-- @param productType string 商品类型
-- @return table 商品列表
function PurchaseConfig:GetProductsByType(productType)
    local products = {}
    
    for _, product in pairs(self.Products) do
        if product.productType == productType then
            table.insert(products, product)
        end
    end
    
    -- 按排序顺序排序
    table.sort(products, function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    
    return products
end

-- 获取所有船只商品（按排序顺序）
-- @return table 排序后的船只列表
function PurchaseConfig:GetAllProducts()
    local products = {}
    
    for _, product in pairs(self.Products) do
        table.insert(products, product)
    end
    
    -- 按排序顺序排序
    table.sort(products, function(a, b)
        return a.sortOrder < b.sortOrder
    end)
    
    return products
end

-- 根据ID获取船只商品
-- @param productId string 商品ID
-- @return table|nil 商品配置
function PurchaseConfig:GetProduct(productId)
    return self.Products[productId]
end

-- 获取开发者产品ID
-- @param productId string 商品ID
-- @return number|nil 开发者产品ID
function PurchaseConfig:GetDeveloperProductId(productId)
    return self.DeveloperProductIds[productId]
end

return PurchaseConfig