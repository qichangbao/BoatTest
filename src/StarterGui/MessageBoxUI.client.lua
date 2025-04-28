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

local _messageBoxGui = nil

local function CreateMessageBoxGui()
    local gui = Instance.new('ScreenGui')
    gui.Name = 'MessageBoxUI'
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

    -- 模态背景
    local modalFrame = Instance.new('Frame')
    modalFrame.Size = UDim2.new(1, 0, 1, 0)
    modalFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    modalFrame.BackgroundTransparency = 1
    modalFrame.Parent = gui

    local mainFrame = Instance.new('Frame')
    mainFrame.Size = UDim2.new(0.4, 0, 0.3, 0)
    mainFrame.Position = UDim2.new(0.3, 0, 0.35, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.Parent = gui

    -- 关闭按钮
    local closeButton = Instance.new('TextButton')
    closeButton.Name = 'CloseButton'
    closeButton.Size = UDim2.new(0.1, 0, 0.15, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    closeButton.Text = 'X'
    closeButton.Font = Enum.Font.SourceSansSemibold
    closeButton.TextSize = 20
    closeButton.Parent = mainFrame

    -- 标题
    local titleLabel = Instance.new('TextLabel')
    titleLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
    titleLabel.Font = Enum.Font.SourceSansSemibold
    titleLabel.TextSize = 22
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = mainFrame

    -- 内容
    local contentLabel = Instance.new('TextLabel')
    contentLabel.Size = UDim2.new(0.8, 0, 0.5, 0)
    contentLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
    contentLabel.Font = Enum.Font.SourceSans
    contentLabel.TextSize = 18
    contentLabel.TextWrapped = true
    contentLabel.TextColor3 = Color3.new(1, 1, 1)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Parent = mainFrame

    -- 按钮容器
    local buttonContainer = Instance.new('Frame')
    buttonContainer.Size = UDim2.new(0.8, 0, 0.2, 0)
    buttonContainer.Position = UDim2.new(0.1, 0, 0.8, 0)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mainFrame

    local uiListLayout = Instance.new('UIListLayout')
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    uiListLayout.Padding = UDim.new(0.1, 0)
    uiListLayout.Parent = buttonContainer

    return {
        Gui = gui,
        MainFrame = mainFrame,
        Title = titleLabel,
        Content = contentLabel,
        CloseButton = closeButton,
        ButtonContainer = buttonContainer
    }
end

local function Show(config)
    if _messageBoxGui then
        _messageBoxGui.Gui:Destroy()
    end

    _messageBoxGui = CreateMessageBoxGui()
    
    -- 设置基础属性
    _messageBoxGui.Title.Text = config.Title or LanguageConfig:Get(10001)
    _messageBoxGui.Content.Text = config.Content or ''

    -- 创建操作按钮
    local confirmButton = Instance.new('TextButton')
    confirmButton.Size = UDim2.new(0.4, 0, 0.8, 0)
    confirmButton.Text = config.ConfirmText or LanguageConfig:Get(10002)
    confirmButton.Font = Enum.Font.SourceSansSemibold
    confirmButton.TextSize = 18
    confirmButton.Parent = _messageBoxGui.ButtonContainer

    local cancelButton = Instance.new('TextButton')
    cancelButton.Size = UDim2.new(0.4, 0, 0.8, 0)
    cancelButton.Text = config.CancelText or LanguageConfig:Get(10003)
    cancelButton.Font = Enum.Font.SourceSansSemibold
    cancelButton.TextSize = 18
    cancelButton.Parent = _messageBoxGui.ButtonContainer

    -- 事件绑定
    confirmButton.MouseButton1Click:Connect(function()
        if config.OnConfirm then
            config.OnConfirm()
        end
        _messageBoxGui.Gui:Destroy()
        _messageBoxGui = nil
    end)

    cancelButton.MouseButton1Click:Connect(function()
        if config.OnCancel then
            config.OnCancel()
        end
        _messageBoxGui.Gui:Destroy()
        _messageBoxGui = nil
    end)

    _messageBoxGui.CloseButton.MouseButton1Click:Connect(function()
        if config.OnClose then
            config.OnClose()
        end
        _messageBoxGui.Gui:Destroy()
        _messageBoxGui = nil
    end)
end

Knit:OnStart():andThen(function()
    Knit.GetController('UIController').ShowMessageBox:Connect(Show)
end)