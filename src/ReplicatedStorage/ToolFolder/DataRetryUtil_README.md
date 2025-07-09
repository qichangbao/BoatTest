# DataRetryUtil - 通用数据重试工具

这是一个专为Roblox游戏开发设计的通用数据获取重试工具，基于Knit框架和Promise模式，提供了稳定可靠的数据获取解决方案。

## 主要功能

### 1. RetryDataFetch - 通用数据获取重试
自动重试失败的数据获取操作，支持自定义重试次数、延迟和数据验证。

```lua
local DataRetryUtil = require(ReplicatedStorage.ToolFolder.DataRetryUtil)

-- 基本用法
DataRetryUtil.RetryDataFetch(
    function()
        return Knit.GetService('PlayerService'):GetPlayerData()
    end,
    {
        maxRetries = 3,
        retryDelay = 1,
        operationName = "玩家数据获取",
        onSuccess = function(data)
            print("数据获取成功:", data)
        end,
        onFailure = function(errorMsg)
            warn("数据获取失败:", errorMsg)
        end
    }
)

-- 高级用法 - 带数据验证和超时
DataRetryUtil.RetryDataFetch(
    function()
        return Knit.GetService('InventoryService'):GetInventory()
    end,
    {
        maxRetries = 5,
        retryDelay = 2,
        timeout = 30,
        operationName = "背包数据获取",
        dataValidator = function(data)
            return data and type(data) == "table" and #data > 0
        end,
        onSuccess = function(data)
            -- 处理验证通过的数据
            ClientData.Inventory = data
        end,
        onFailure = function(errorMsg)
            -- 使用默认值
            ClientData.Inventory = {}
        end
    }
)
```

### 2. SafeUpdateNumbers - 安全数值更新
安全地将数据表中的数值字段更新到目标表中，自动处理类型转换和默认值。

```lua
-- 定义字段映射
local fieldMappings = {
    gold = "gold",
    level = "level",
    experience = "experience"
}

-- 安全更新数值
DataRetryUtil.SafeUpdateNumbers(targetTable, sourceData, fieldMappings)
```

### 3. SafeMergeTables - 安全表合并
安全地合并两个表，避免覆盖重要数据。

```lua
local mergedData = DataRetryUtil.SafeMergeTables(existingData, newData, {
    overwriteArrays = false,
    preserveExisting = true
})
```

### 4. CreateRetryWrapper - 创建重试包装器
为现有的Promise返回函数创建带重试功能的包装器。

```lua
local retryWrapper = DataRetryUtil.CreateRetryWrapper(
    function() return someService:GetData() end,
    { maxRetries = 3, retryDelay = 1 }
)

retryWrapper():andThen(function(data)
    print("数据获取成功:", data)
end):catch(function(err)
    warn("最终失败:", err)
end)
```

### 5. BatchFetch - 批量数据获取
同时获取多个数据源，支持部分失败容错。

```lua
local fetchTasks = {
    playerData = function() return Knit.GetService('PlayerService'):GetData() end,
    inventory = function() return Knit.GetService('InventoryService'):GetInventory() end,
    settings = function() return Knit.GetService('SettingsService'):GetSettings() end
}

DataRetryUtil.BatchFetch(fetchTasks, {
    allowPartialFailure = true,
    timeout = 15
}):andThen(function(results)
    -- results.playerData, results.inventory, results.settings
    print("批量获取完成:", results)
end)
```

## 配置选项说明

### RetryDataFetch 配置
- `maxRetries`: 最大重试次数（默认3次）
- `retryDelay`: 重试间隔秒数（默认1秒）
- `timeout`: 总超时时间（可选）
- `operationName`: 操作名称，用于日志记录
- `dataValidator`: 数据验证函数，返回true表示数据有效
- `onSuccess`: 成功回调函数
- `onFailure`: 失败回调函数

### SafeMergeTables 配置
- `overwriteArrays`: 是否覆盖数组（默认false）
- `preserveExisting`: 是否保留现有值（默认true）

### BatchFetch 配置
- `allowPartialFailure`: 是否允许部分失败（默认false）
- `timeout`: 批量操作超时时间（默认10秒）

## 最佳实践

### 1. 错误处理策略
```lua
-- 推荐：提供默认值和错误处理
DataRetryUtil.RetryDataFetch(
    fetchFunction,
    {
        onSuccess = function(data)
            -- 处理成功数据
        end,
        onFailure = function(errorMsg)
            -- 使用默认值，确保游戏继续运行
            useDefaultValues()
        end
    }
)
```

### 2. 数据验证
```lua
-- 推荐：添加数据验证确保数据完整性
dataValidator = function(data)
    return data and 
           type(data) == "table" and 
           data.requiredField ~= nil and
           #data > 0
end
```

### 3. 合理的重试配置
```lua
-- 重要数据：更多重试次数和更长延迟
maxRetries = 5,
retryDelay = 2,

-- 非关键数据：较少重试次数
maxRetries = 2,
retryDelay = 1,
```

### 4. 超时设置
```lua
-- 为长时间操作设置合理的超时
timeout = 30, -- 30秒超时
```

## 使用场景

1. **玩家登录数据获取** - 确保玩家数据正确加载
2. **背包/物品数据同步** - 处理网络不稳定导致的数据丢失
3. **排行榜数据更新** - 重试失败的排行榜请求
4. **游戏状态同步** - 确保客户端状态与服务器一致
5. **配置数据加载** - 重试配置文件加载失败

## 注意事项

1. **避免无限重试** - 始终设置合理的最大重试次数
2. **合理的延迟设置** - 避免过于频繁的重试请求
3. **提供默认值** - 确保即使数据获取失败，游戏也能正常运行
4. **日志记录** - 使用operationName参数便于调试
5. **数据验证** - 验证获取的数据格式和完整性

## 与现有代码集成

这个工具设计为与现有的Knit框架代码无缝集成，可以逐步替换现有的数据获取逻辑，提高代码的稳定性和可维护性。

参考 `ClientDataImproved.lua` 文件查看完整的使用示例。