local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))

-- 等待Knit启动
Knit.OnStart():andThen(function()
    local BuffService = Knit.GetService("BuffService")
    local PlayerAttributeService = Knit.GetService("PlayerAttributeService")
    
    -- 聊天命令处理
    local function onPlayerChatted(player, message)
        -- 只有管理员可以使用BUFF命令
        if not PlayerAttributeService:IsAdmin(player) then
            return
        end
        
        local args = string.split(message, " ")
        local command = args[1]:lower()
        -- /addbuff qichangbao speed_boost 60
        if command == "/addbuff" then
            -- 用法: /addbuff [玩家名] [BUFF ID] [持续时间(可选)]
            if #args >= 4 then
                local targetPlayerName = args[2]
                local buffId = args[3]
                local duration = tonumber(args[4])
                
                local targetPlayer = Players:FindFirstChild(targetPlayerName)
                if targetPlayer then
                    local success = BuffService:AddBuff(targetPlayer, buffId, duration)
                    if success then
                        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                            Text = "已为玩家 " .. targetPlayer.Name .. " 添加BUFF: " .. buffId,
                            Color = Color3.fromRGB(0, 255, 0)
                        })
                    else
                        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                            Text = "添加BUFF失败！请检查BUFF ID和类型",
                            Color = Color3.fromRGB(255, 0, 0)
                        })
                    end
                else
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = "未找到玩家: " .. targetPlayerName,
                        Color = Color3.fromRGB(255, 0, 0)
                    })
                end
            else
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = "用法: /addbuff [玩家名] [BUFF ID] [持续时间(可选)]",
                    Color = Color3.fromRGB(255, 255, 0)
                })
            end
            
        elseif command == "/removebuff" then
            -- 用法: /removebuff [玩家名] [BUFF ID]
            if #args >= 3 then
                local targetPlayerName = args[2]
                local buffId = args[3]
                
                local targetPlayer = Players:FindFirstChild(targetPlayerName)
                if targetPlayer then
                    local success = BuffService:RemoveBuff(targetPlayer, buffId)
                    if success then
                        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                            Text = "已为玩家 " .. targetPlayer.Name .. " 移除BUFF: " .. buffId,
                            Color = Color3.fromRGB(0, 255, 0)
                        })
                    else
                        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                            Text = "移除BUFF失败！该玩家没有此BUFF",
                            Color = Color3.fromRGB(255, 0, 0)
                        })
                    end
                else
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = "未找到玩家: " .. targetPlayerName,
                        Color = Color3.fromRGB(255, 0, 0)
                    })
                end
            else
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = "用法: /removebuff [玩家名] [BUFF类型] [BUFF ID]",
                    Color = Color3.fromRGB(255, 255, 0)
                })
            end
            
        elseif command == "/clearbuffs" then
            -- 用法: /clearbuffs [玩家名]
            if #args >= 2 then
                local targetPlayerName = args[2]
                local targetPlayer = Players:FindFirstChild(targetPlayerName)
                if targetPlayer then
                    BuffService:ClearAllBuffs(targetPlayer)
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = "已清除玩家 " .. targetPlayer.Name .. " 的所有BUFF",
                        Color = Color3.fromRGB(0, 255, 0)
                    })
                else
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = "未找到玩家: " .. targetPlayerName,
                        Color = Color3.fromRGB(255, 0, 0)
                    })
                end
            else
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = "用法: /clearbuffs [玩家名]",
                    Color = Color3.fromRGB(255, 255, 0)
                })
            end
            
        elseif command == "/listbuffs" then
            -- 用法: /listbuffs [玩家名]
            if #args >= 2 then
                local targetPlayerName = args[2]
                local targetPlayer = Players:FindFirstChild(targetPlayerName)
                if targetPlayer then
                    local buffs = BuffService:GetPlayerBuffs(targetPlayer)
                    local buffCount = 0
                    local buffText = "玩家 " .. targetPlayer.Name .. " 的BUFF列表:\n"
                    
                    for buffType, buffList in pairs(buffs) do
                        for buffId, buffData in pairs(buffList) do
                            buffCount = buffCount + 1
                            buffText = buffText .. string.format("- %s (%s): %.1fs\n", 
                                buffData.config.displayName or buffId, 
                                buffType, 
                                buffData.remainingTime
                            )
                        end
                    end
                    
                    if buffCount == 0 then
                        buffText = buffText .. "无活跃BUFF"
                    end
                    
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = buffText,
                        Color = Color3.fromRGB(0, 255, 255)
                    })
                else
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                        Text = "未找到玩家: " .. targetPlayerName,
                        Color = Color3.fromRGB(255, 0, 0)
                    })
                end
            else
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = "用法: /listbuffs [玩家名]",
                    Color = Color3.fromRGB(255, 255, 0)
                })
            end
            
        elseif command == "/buffhelp" then
            local helpText = [[BUFF系统命令帮助:
/addbuff [玩家名] [类型] [ID] [时间] - 添加BUFF
/removebuff [玩家名] [类型] [ID] - 移除BUFF
/clearbuffs [玩家名] - 清除所有BUFF
/listbuffs [玩家名] - 查看BUFF列表

BUFF类型: speed, health, damage

常用BUFF ID:
速度: speed_boost_small, speed_boost_medium, speed_boost_large, speed_slow
生命: health_boost_small, health_boost_medium, health_boost_large
伤害: damage_boost_small, damage_boost_medium, damage_boost_large]]
            
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = helpText,
                Color = Color3.fromRGB(255, 255, 255)
            })
        end
    end
    
    -- 为所有玩家连接聊天事件
    local function playerAdded(player)
        player.Chatted:Connect(function(message)
            onPlayerChatted(player, message)
        end)
    end
    
    -- 为已存在的玩家连接事件
    for _, player in Players:GetPlayers() do
        playerAdded(player)
    end
    
    -- 为新加入的玩家连接事件
    Players.PlayerAdded:Connect(playerAdded)
    
    print("BUFF测试命令系统已启动！管理员可使用 /buffhelp 查看帮助")
end)