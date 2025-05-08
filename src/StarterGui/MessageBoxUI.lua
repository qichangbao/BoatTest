--[[
模块名称：通用提示框系统
功能：实现可配置的模态对话框，支持回调函数和动态参数
作者：Trea AI
版本：1.0.0
最后修改：2024-05-28
]]
print('MessageBoxUI.client.lua loaded')

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Knit = require(ReplicatedStorage.Packages.Knit.Knit)
local LanguageConfig = require(ReplicatedStorage:WaitForChild("ConfigFolder"):WaitForChild("LanguageConfig"))
local PlayerGui = Players.LocalPlayer:WaitForChild('PlayerGui')

local MessageBoxUI = {}
function MessageBoxUI:Init()
    local gui = Instance.new('ScreenGui')
    gui.Name = 'MessageBoxUI_Gui'
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    self.mainFrame = Instance.new('Frame')
    self.mainFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
    self.mainFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    self.mainFrame.Visible = false
    self.mainFrame.Parent = gui

    -- 关闭按钮
    self.closeButton = Instance.new('TextButton')
    self.closeButton.Name = 'CloseButton'
    self.closeButton.Size = UDim2.new(0.1, 0, 0.15, 0)
    self.closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    self.closeButton.Text = 'X'
    self.closeButton.Font = Enum.Font.Arimo
    self.closeButton.TextSize = 20
    self.closeButton.Parent = self.mainFrame

    -- 标题
    self.titleLabel = Instance.new('TextLabel')
    self.titleLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    self.titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
    self.titleLabel.Font = Enum.Font.Arimo
    self.titleLabel.TextSize = 22
    self.titleLabel.TextColor3 = Color3.new(1, 1, 1)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Parent = self.mainFrame

    -- 内容
    self.contentLabel = Instance.new('TextLabel')
    self.contentLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
    self.contentLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
    self.contentLabel.Font = Enum.Font.Arimo
    self.contentLabel.TextSize = 18
    self.contentLabel.TextWrapped = true
    self.contentLabel.TextColor3 = Color3.new(1, 1, 1)
    self.contentLabel.BackgroundTransparency = 1
    self.contentLabel.Parent = self.mainFrame

    -- 按钮容器
    local buttonContainer = Instance.new('Frame')
    buttonContainer.Size = UDim2.new(0.8, 0, 0.2, 0)
    buttonContainer.Position = UDim2.new(0.1, 0, 0.8, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = self.mainFrame

    -- 创建操作按钮
    self.confirmButton = Instance.new('TextButton')
    self.confirmButton.Size = UDim2.new(0.4, 0, 0.8, 0)
    self.confirmButton.Font = Enum.Font.Arimo
    self.confirmButton.TextSize = 18
    self.confirmButton.Parent = buttonContainer

    self.cancelButton = Instance.new('TextButton')
    self.cancelButton.Size = UDim2.new(0.4, 0, 0.8, 0)
    self.cancelButton.Font = Enum.Font.Arimo
    self.cancelButton.TextSize = 18
    self.cancelButton.Parent = buttonContainer

    local uiListLayout = Instance.new('UIListLayout')
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    uiListLayout.Padding = UDim.new(0.1, 0)
    uiListLayout.Parent = buttonContainer
end

function MessageBoxUI:Show(config)
    -- 设置基础属性
    self.mainFrame.Visible = true
    self.titleLabel.Text = config.Title or LanguageConfig:Get(10001)
    self.contentLabel.Text = config.Content or ''

    self.confirmButton.Text = config.ConfirmText or LanguageConfig:Get(10002)
    self.cancelButton.Text = config.CancelText or LanguageConfig:Get(10003)
    -- 事件绑定
    self.confirmButton.MouseButton1Click:Connect(function()
        if config.OnConfirm then
            config.OnConfirm()
        end
        self.mainFrame.Visible = false
    end)

    self.cancelButton.MouseButton1Click:Connect(function()
        if config.OnCancel then
            config.OnCancel()
        end
        self.mainFrame.Visible = false
    end)

    self.closeButton.MouseButton1Click:Connect(function()
        if config.OnClose then
            config.OnClose()
        end
        self.mainFrame.Visible = false
    end)
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').ShowMessageBox:Connect(MessageBoxUI.Show)
end)

return MessageBoxUI