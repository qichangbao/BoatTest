local LanguageConfig = {}
local Text = {
    [10001] = {zh_cn = "提示", en_us = "提示"},
    [10002] = {zh_cn = "确定", en_us = "确定"},
    [10003] = {zh_cn = "取消", en_us = "取消"},
    [10004] = {zh_cn = "启航", en_us = "启航"},
    [10005] = {zh_cn = "止航", en_us = "止航"},
    [10006] = {zh_cn = "添加部件", en_us = "添加部件"},
    [10007] = {zh_cn = "金币", en_us = "金币"},
    [10008] = {zh_cn = "抽奖", en_us = "抽奖"},
    [10009] = {zh_cn = "分解", en_us = "分解"},
    [10010] = {zh_cn = "分解可获得%s金币,是否分解?", en_us = "分解可获得%s金币,是否分解?"},
    [10011] = {zh_cn = "恭喜你获得了: %s", en_us = "恭喜你获得了: %s"},
    [10012] = {zh_cn = "你失去了: %s", en_us = "你失去了: %s"},
    [10013] = {zh_cn = "生命  %s/%s", en_us = "Health  %s/%s"},
    [10014] = {zh_cn = "速度  %s/%s", en_us = "Speed  %s/%s"},
    [10015] = {zh_cn = "冷却时间未到", en_us = "冷却时间未到"},
    [10016] = {zh_cn = "你获得了已有的船部件%s，已自动分解", en_us = "你获得了已有的船部件%s，已自动分解"},
    [10017] = {zh_cn = "添加部件失败，船不存在", en_us = "添加部件失败，船不存在"},
    [10018] = {zh_cn = "添加部件失败，玩家不存在", en_us = "添加部件失败，玩家不存在"},
    [10019] = {zh_cn = "部件添加成功", en_us = "部件添加成功"},
    [10020] = {zh_cn = "船已存在", en_us = "船已存在"},
    [10021] = {zh_cn = "玩家没有可用的船主部件", en_us = "玩家没有可用的船主部件"},
    [10022] = {zh_cn = "船组装成功", en_us = "船组装成功"},
    [10023] = {zh_cn = "你正在使用它，不能分解", en_us = "你正在使用它，不能分解"},
    [10024] = {zh_cn = "是否将出生地设置为本区域?", en_us = "是否将出生地设置为本区域?"},
    [10025] = {zh_cn = "背包", en_us = "背包"},
    [10026] = {zh_cn = "玩家", en_us = "玩家"},
    [10027] = {zh_cn = "赠送", en_us = "赠送"},
    [10028] = {zh_cn = "赠送成功", en_us = "赠送成功"},
    [10029] = {zh_cn = "选择数量", en_us = "选择数量"},
    [10030] = {zh_cn = "不能赠送自己", en_us = "不能赠送自己"},
    [10031] = {zh_cn = "%s赠送给你一些物品", en_us = "%s赠送给你一些物品"},
    [10032] = {zh_cn = "没找到玩家", en_us = "没找到玩家"},
    [10033] = {zh_cn = "玩家列表", en_us = "玩家列表"},
    [10035] = {zh_cn = "欢迎你，请选择你的操作", en_us = "欢迎你，请选择你的操作"},
    [10036] = {zh_cn = "占领", en_us = "占领"},
    [10037] = {zh_cn = "正在占领中，请不要移动...", en_us = "正在占领中，请不要移动..."},
    [10038] = {zh_cn = "恭喜你，成功占领%s", en_us = "恭喜你，成功占领%s"},
    [10039] = {zh_cn = "玩家%s成功占领了%s", en_us = "玩家%s成功占领了%s"},
    [10040] = {zh_cn = "登岛", en_us = "登岛"},
    [10041] = {zh_cn = "交费%s", en_us = "交费%s"},
    [10042] = {zh_cn = "%s岛屿错误", en_us = "%s岛屿错误"},
    [10043] = {zh_cn = "你不是岛主，不能设置出生点", en_us = "你不是岛主，不能设置出生点"},
    [10044] = {zh_cn = "金币不够", en_us = "金币不够"},
    [10045] = {zh_cn = "你收到玩家%s为登陆%s而付的%s金币", en_us = "你收到玩家%s为登陆%s而付的%s金币"},
    [10046] = {zh_cn = "此岛已被%s占领，请选择你的操作", en_us = "此岛已被%s占领，请选择你的操作"},
    [10047] = {zh_cn = "岛主", en_us = "岛主"},
    [10048] = {zh_cn = "离线期间,你总共获得%s金币的收益", en_us = "离线期间,你总共获得%s金币的收益"},
    [10049] = {zh_cn = "你登陆了%s", en_us = "你登陆了%s"},
    [10050] = {zh_cn = "欢迎你进入游戏", en_us = "欢迎你进入游戏"},
    [10051] = {zh_cn = "运气太衰，这是个空箱子", en_us = "运气太衰，这是个空箱子"},
    [10052] = {zh_cn = "速度", en_us = "速度"},
    [10053] = {zh_cn = "生命", en_us = "生命"},
    [10054] = {zh_cn = "幸运", en_us = "幸运"},
    [10055] = {zh_cn = "购买成功", en_us = "购买成功"},
    [10056] = {zh_cn = "金币不足", en_us = "金币不足"},
    [10057] = {zh_cn = "系统错误", en_us = "系统错误"},
    [10058] = {zh_cn = "你不是岛主，不能购买箭塔", en_us = "你不是岛主，不能购买箭塔"},
    [10059] = {zh_cn = "已达到能购买的最大箭塔数量", en_us = "已达到能购买的最大箭塔数量"},
    [10060] = {zh_cn = "拆除成功", en_us = "拆除成功"},
    [10061] = {zh_cn = "你不是岛主，不能拆除箭塔", en_us = "你不是岛主，不能拆除箭塔"},
    [10062] = {zh_cn = "基础箭塔", en_us = "基础箭塔"},
    [10063] = {zh_cn = "中级箭塔", en_us = "中级箭塔"},
    [10064] = {zh_cn = "高级箭塔", en_us = "高级箭塔"},
    [10065] = {zh_cn = "占领失败", en_us = "占领失败"},
    [10066] = {zh_cn = "岛屿管理", en_us = "岛屿管理"},
    [10067] = {zh_cn = "我的岛屿", en_us = "我的岛屿"},
    [10068] = {zh_cn = "箭塔数量", en_us = "箭塔数量"},
    [10069] = {zh_cn = "总收益", en_us = "总收益"},
    [10070] = {zh_cn = "箭塔管理", en_us = "箭塔管理"},
    [10071] = {zh_cn = "不可用", en_us = "不可用"},
    [10072] = {zh_cn = "此岛屿不支持", en_us = "此岛屿不支持"},
    [10073] = {zh_cn = "伤害", en_us = "伤害"},
    [10074] = {zh_cn = "你是否要拆除此箭塔？", en_us = "你是否要拆除此箭塔？"},
    [10075] = {zh_cn = "购买箭塔", en_us = "购买箭塔"},
    [10076] = {zh_cn = "你还没有拥有任何岛屿", en_us = "你还没有拥有任何岛屿"},
    [10077] = {zh_cn = "选择箭塔类型", en_us = "选择箭塔类型"},
    [10078] = {zh_cn = "当前效果", en_us = "当前效果"},
    [10079] = {zh_cn = "%s占领%s失败", en_us = "%s占领%s失败"},
    [10080] = {zh_cn = "%s成功占领%s", en_us = "%s成功占领%s"},
    [10081] = {zh_cn = "%s开始攻打%s", en_us = "%s开始攻打%s"},
    [10082] = {zh_cn = "无名岛", en_us = "无名岛"},
    [10083] = {zh_cn = "你是否登船", en_us = "你是否登船"},
}

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")

local curCountryCode = 'zh_cn'

-- 只在客户端获取玩家地区信息
if RunService:IsClient() and Players.LocalPlayer then
    local success, countryCode = pcall(function()
        return LocalizationService:GetCountryRegionForPlayerAsync(Players.LocalPlayer)
    end)
    
    if success and countryCode then
        if countryCode == "CN" then
            curCountryCode = 'zh_cn'
        else
            curCountryCode = 'en_us'
        end
    end
end

function LanguageConfig.Get(key)
    return Text[key][curCountryCode]
end

return LanguageConfig