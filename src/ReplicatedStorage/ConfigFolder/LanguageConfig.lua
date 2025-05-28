local LanguageConfig = {}
LanguageConfig.Text = {
    [10001] = {zh_cn = "提示", en_us = "提示"},
    [10002] = {zh_cn = "确定", en_us = "确定"},
    [10003] = {zh_cn = "取消", en_us = "取消"},
    [10004] = {zh_cn = "启航", en_us = "启航"},
    [10005] = {zh_cn = "止航", en_us = "止航"},
    [10006] = {zh_cn = "添加部件", en_us = "添加部件"},
    [10007] = {zh_cn = "黄金", en_us = "黄金"},
    [10008] = {zh_cn = "抽奖", en_us = "抽奖"},
    [10009] = {zh_cn = "分解", en_us = "分解"},
    [10010] = {zh_cn = "分解可获得%s黄金,是否分解?", en_us = "分解可获得%s黄金,是否分解?"},
    [10011] = {zh_cn = "恭喜你获得了: %s", en_us = "恭喜你获得了: %s"},
    [10012] = {zh_cn = "你失去了: %s", en_us = "你失去了: %s"},
    [10013] = {zh_cn = "生命值", en_us = "Health"},
    [10014] = {zh_cn = "速度", en_us = "Speed"},
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
    [10044] = {zh_cn = "黄金不够", en_us = "黄金不够"},
    [10045] = {zh_cn = "你收到玩家%s为登陆%s而付的%s黄金", en_us = "你收到玩家%s为登陆%s而付的%s黄金"},
    [10046] = {zh_cn = "此岛已被%s占领，请选择你的操作", en_us = "此岛已被%s占领，请选择你的操作"},
    [10047] = {zh_cn = "岛主:%s", en_us = "岛主:%s"},
    [10048] = {zh_cn = "离线期间,你总共获得%s黄金的收益", en_us = "离线期间,你总共获得%s黄金的收益"},
}

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local curCountryCode = 'zh_cn'
local countryCode = LocalizationService:GetCountryRegionForPlayerAsync(Players.LocalPlayer)
if countryCode == "CN" then
    curCountryCode = 'zh_cn'
else
    curCountryCode = 'en_us'
end

function LanguageConfig:Get(key)
    return self.Text[key][curCountryCode]
end

return LanguageConfig