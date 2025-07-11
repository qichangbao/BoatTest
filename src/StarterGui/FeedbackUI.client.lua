--[[
模块功能：反馈界面 - 使用Roblox原生API
版本：2.0.0
作者：Trea
修改记录：
2024-12-19 更新为使用Roblox原生反馈API
--]]

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local AnalyticsService = game:GetService('AnalyticsService')
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Knit"))
local UIConfig = require(script.Parent:WaitForChild("UIConfig"))
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local _screenGui = Instance.new('ScreenGui')
_screenGui.Name = 'FeedbackUI_GUI'
_screenGui.IgnoreGuiInset = true
_screenGui.Enabled = false
_screenGui.Parent = PlayerGui

UIConfig.CreateBlock(_screenGui)

local _frame = UIConfig.CreateMiddleFrame(_screenGui, LanguageConfig.Get(10106))

-- 内容区域
local contentFrame = Instance.new('Frame')
contentFrame.Name = 'ContentFrame'
contentFrame.Size = UDim2.new(1, -40, 1, -20)
contentFrame.Position = UDim2.new(0, 20, 0, 10)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = _frame

-- 反馈输入框
local feedbackTextBox = Instance.new('TextBox')
feedbackTextBox.Name = 'FeedbackTextBox'
feedbackTextBox.Size = UDim2.new(1, 0, 0.7, 0)
feedbackTextBox.Position = UDim2.new(0, 0, 0, 0)
feedbackTextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
feedbackTextBox.BorderSizePixel = 1
feedbackTextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
feedbackTextBox.Text = ""
feedbackTextBox.PlaceholderText = LanguageConfig.Get(10107)
feedbackTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
feedbackTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
feedbackTextBox.TextSize = 36
feedbackTextBox.Font = UIConfig.Font
feedbackTextBox.TextWrapped = true
feedbackTextBox.TextXAlignment = Enum.TextXAlignment.Left
feedbackTextBox.TextYAlignment = Enum.TextYAlignment.Top
feedbackTextBox.MultiLine = true
feedbackTextBox.ClearTextOnFocus = false
feedbackTextBox.Parent = contentFrame

local textBoxCorner = Instance.new('UICorner')
textBoxCorner.CornerRadius = UDim.new(0, 6)
textBoxCorner.Parent = feedbackTextBox

local LogService = game:GetService('LogService')
-- 记录反馈提交事件
local function logFeedbackSubmission(content, success)
    if success then
        print("[反馈系统] 反馈提交成功: " .. string.sub(content, 1, 50) .. "...")
    else
        warn("[反馈系统] 反馈提交失败: " .. content)
    end
end

-- 监听系统日志，用于调试
LogService.MessageOut:Connect(function(message, messageType)
    if string.find(message, "反馈系统") then
        -- 处理反馈相关的日志
        print("捕获到反馈系统日志:", message)
    end
end)

-- 提交反馈到Analytics和Roblox反馈系统
local function submitFeedback(player, feedbackText)
    if feedbackText and feedbackText ~= "" then
        -- 截取反馈内容前200个字符用于Analytics（避免字段长度限制）
        local truncatedContent = string.sub(feedbackText, 1, 200)
        if string.len(feedbackText) > 200 then
            truncatedContent = truncatedContent .. "..."
        end
        
        -- 记录到Analytics（包含实际反馈内容）
        local success = pcall(function()
            AnalyticsService:LogCustomEvent(
                player,
                "PlayerFeedbackSubmitted",
                1,
                {
                    FeedbackContent = truncatedContent, -- 反馈内容（截取版本）
                    FeedbackLength = string.len(feedbackText), -- 原始长度
                    FeedbackType = "General",
                    Platform = "InGame",
                    Timestamp = os.time(),
                    PlayerId = tostring(player.UserId), -- 玩家ID
                    PlayerName = player.Name -- 玩家名称
                }
            )
        end)
        
        if success then
            -- 显示成功通知
            game.StarterGui:SetCore("SendNotification", {
                Title = LanguageConfig.Get(10108),
                Text = LanguageConfig.Get(10109),
                Duration = 5
            })
        else
            -- 显示失败通知
            game.StarterGui:SetCore("SendNotification", {
                Title = LanguageConfig.Get(10110),
                Text = LanguageConfig.Get(10111),
                Duration = 5
            })
        end
    end
end

local confirmButton = UIConfig.CreateConfirmButton(contentFrame, function()
    submitFeedback(game.Players.LocalPlayer, feedbackTextBox.Text)

    -- 清空输入框并关闭界面
    feedbackTextBox.Text = ""
    _screenGui.Enabled = false
end)
confirmButton.Position = UDim2.new(0.5, 0, 1, -40)

-- 等待Knit启动
Knit:OnStart():andThen(function()
    -- 注册UI到UIController
    Knit.GetController('UIController').AddUI:Fire(_screenGui)
    
    -- 监听显示反馈UI的事件
    Knit.GetController('UIController').ShowFeedbackUI:Connect(function()
        _screenGui.Enabled = true
    end)
end):catch(warn)