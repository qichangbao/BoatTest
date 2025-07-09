--[[
    数据重试工具模块
    提供通用的数据获取重试机制，用于处理网络请求失败、数据为空等异常情况
    作者: Roblox开发团队
    创建时间: 2024
]]

local DataRetryUtil = {}

-- 默认配置
local DEFAULT_CONFIG = {
    maxRetries = 5,          -- 最大重试次数
    retryDelay = 2,          -- 重试间隔（秒）
    timeout = 30,            -- 超时时间（秒）
    validateData = true,     -- 是否验证数据
    logErrors = true,        -- 是否记录错误日志
    logSuccess = true        -- 是否记录成功日志
}

--[[  
    通用数据获取重试方法
    @param serviceCall: function - 服务调用函数，返回Promise
    @param config: table - 配置参数
        - maxRetries: number - 最大重试次数（默认5）
        - retryDelay: number - 重试间隔秒数（默认2）
        - timeout: number - 超时时间秒数（默认30）
        - validateData: boolean - 是否验证数据（默认true）
        - dataValidator: function - 自定义数据验证函数
        - onSuccess: function - 成功回调
        - onFailure: function - 失败回调
        - logErrors: boolean - 是否记录错误（默认true）
        - logSuccess: boolean - 是否记录成功（默认true）
        - operationName: string - 操作名称，用于日志
    @return Promise
]]
function DataRetryUtil.RetryDataFetch(serviceCall, config)
    config = config or {}
    
    -- 合并默认配置
    local finalConfig = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        finalConfig[key] = config[key] ~= nil and config[key] or value
    end
    for key, value in pairs(config) do
        if DEFAULT_CONFIG[key] == nil then
            finalConfig[key] = value
        end
    end
    
    local retryCount = 0
    local startTime = tick()
    local operationName = finalConfig.operationName or "数据获取"
    
    -- 默认数据验证函数
    local function defaultValidator(data)
        return data ~= nil and (type(data) == "table" or type(data) == "string" or type(data) == "number")
    end
    
    local dataValidator = finalConfig.dataValidator or defaultValidator
    
    local function attemptFetch()
        -- 检查超时
        if tick() - startTime > finalConfig.timeout then
            local errorMsg = operationName .. "超时，停止重试"
            if finalConfig.logErrors then
                warn(errorMsg)
            end
            if finalConfig.onFailure then
                finalConfig.onFailure(errorMsg)
            end
            return
        end
        
        retryCount = retryCount + 1
        
        return serviceCall():andThen(function(data)
            -- 数据验证
            if finalConfig.validateData and not dataValidator(data) then
                local errorMsg = operationName .. "数据验证失败，重试次数: " .. retryCount .. "/" .. finalConfig.maxRetries
                if finalConfig.logErrors then
                    warn(errorMsg)
                end
                
                if retryCount < finalConfig.maxRetries then
                    task.wait(finalConfig.retryDelay)
                    return attemptFetch()
                else
                    local finalErrorMsg = operationName .. "最终失败 - 数据验证不通过"
                    if finalConfig.logErrors then
                        warn(finalErrorMsg)
                    end
                    if finalConfig.onFailure then
                        finalConfig.onFailure(finalErrorMsg)
                    end
                end
            else
                -- 成功
                if finalConfig.logSuccess then
                    print(operationName .. "成功，重试次数: " .. (retryCount - 1))
                end
                if finalConfig.onSuccess then
                    finalConfig.onSuccess(data)
                end
                return data
            end
        end):catch(function(err)
            local errorMsg = operationName .. "失败，重试次数: " .. retryCount .. "/" .. finalConfig.maxRetries .. "，错误: " .. tostring(err)
            if finalConfig.logErrors then
                warn(errorMsg)
            end
            
            if retryCount < finalConfig.maxRetries then
                task.wait(finalConfig.retryDelay)
                return attemptFetch()
            else
                local finalErrorMsg = operationName .. "最终失败"
                if finalConfig.logErrors then
                    warn(finalErrorMsg)
                end
                if finalConfig.onFailure then
                    finalConfig.onFailure(finalErrorMsg)
                end
            end
        end)
    end
    
    return attemptFetch()
end

--[[
    安全数值更新方法
    @param targetTable: table - 目标表
    @param sourceData: table - 源数据
    @param fieldMappings: table - 字段映射 {targetField = sourceField}
    @param logErrors: boolean - 是否记录错误（默认true）
]]
function DataRetryUtil.SafeUpdateNumbers(targetTable, sourceData, fieldMappings, logErrors)
    if not targetTable or type(targetTable) ~= "table" then
        warn("目标表无效")
        return
    end
    
    if not sourceData or type(sourceData) ~= "table" then
        if logErrors ~= false then
            warn("源数据无效或格式错误")
        end
        return
    end
    
    logErrors = logErrors ~= false -- 默认为true
    
    for targetField, sourceField in pairs(fieldMappings) do
        local value = sourceData[sourceField]
        if value ~= nil then
            local numValue = tonumber(value)
            if numValue then
                targetTable[targetField] = numValue
            else
                if logErrors then
                    warn("字段 " .. sourceField .. " 不是有效数字: " .. tostring(value))
                end
            end
        end
    end
end

--[[
    安全表合并方法
    @param targetTable: table - 目标表
    @param sourceTable: table - 源表
    @param allowOverwrite: boolean - 是否允许覆盖已存在的字段（默认true）
    @param validator: function - 值验证函数（可选）
]]
function DataRetryUtil.SafeMergeTables(targetTable, sourceTable, allowOverwrite, validator)
    if not targetTable or type(targetTable) ~= "table" then
        warn("目标表无效")
        return
    end
    
    if not sourceTable or type(sourceTable) ~= "table" then
        warn("源表无效")
        return
    end
    
    allowOverwrite = allowOverwrite ~= false -- 默认为true
    
    for key, value in pairs(sourceTable) do
        local shouldSet = allowOverwrite or targetTable[key] == nil
        
        if shouldSet then
            if validator then
                if validator(key, value) then
                    targetTable[key] = value
                end
            else
                targetTable[key] = value
            end
        end
    end
end

--[[
    创建带重试的Promise包装器
    @param promiseFunc: function - 返回Promise的函数
    @param retryConfig: table - 重试配置
    @return function - 包装后的函数
]]
function DataRetryUtil.CreateRetryWrapper(promiseFunc, retryConfig)
    return function(...)
        local args = {...}
        return DataRetryUtil.RetryDataFetch(function()
            return promiseFunc(table.unpack(args))
        end, retryConfig)
    end
end

--[[
    批量数据获取方法
    @param fetchTasks: table - 获取任务列表 {{serviceCall, config, name}}
    @param concurrent: boolean - 是否并发执行（默认false）
    @return Promise
]]
function DataRetryUtil.BatchFetch(fetchTasks, concurrent)
    if not fetchTasks or type(fetchTasks) ~= "table" or #fetchTasks == 0 then
        warn("批量获取任务列表无效")
        return
    end
    
    concurrent = concurrent or false
    local results = {}
    
    if concurrent then
        -- 并发执行
        local promises = {}
        for i, task in ipairs(fetchTasks) do
            local promise = DataRetryUtil.RetryDataFetch(task.serviceCall, task.config)
            table.insert(promises, promise)
        end
        
        -- 等待所有Promise完成（这里需要Promise.all的实现）
        -- 由于Roblox的Promise库可能不同，这里提供基础框架
        return promises
    else
        -- 顺序执行
        local function executeNext(index)
            if index > #fetchTasks then
                return results
            end
            
            local task = fetchTasks[index]
            return DataRetryUtil.RetryDataFetch(task.serviceCall, task.config):andThen(function(data)
                results[task.name or index] = data
                return executeNext(index + 1)
            end)
        end
        
        return executeNext(1)
    end
end

return DataRetryUtil