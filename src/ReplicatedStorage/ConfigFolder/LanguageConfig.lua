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
    [10011] = {zh_cn = "恭喜您获得了: %s", en_us = "恭喜您获得了: %s"},
    [10012] = {zh_cn = "您失去了: %s", en_us = "您失去了: %s"},
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