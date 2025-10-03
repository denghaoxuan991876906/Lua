--[=====[
[[SND Metadata]]
author: 'sf '
version: 1.0.0
description: a

[[End Metadata]]
--]=====]
-- 导入必要的系统模块
import("System.Numerics")
-- 状态变量
Run_script        = true               -- 脚本运行标志
loopDelay  = 1           -- 控制脚本运行速度；值越低越快，值越高越慢（单位：秒/循环）
-- 等待指定秒数
function sleep(seconds)
    yield('/wait ' .. tostring(seconds))  -- 执行等待命令
end
function Echo(text)
    yield("/echo " .. text)
end
function IsAddonReady(name)
    return Addons.GetAddon(name).Ready
end
function GetENpcResidentName(dataId)
    local sheet = Excel.GetSheet("ENpcResident")  -- 获取NPC数据表
    if not sheet then return nil, "ENpcResident数据表不可用" end

    local row = sheet:GetRow(dataId)  -- 获取指定ID的NPC数据
    if not row then return nil, "ID为 "..tostring(dataId).." 的记录不存在" end

    local name = row.Singular or row.Name  -- 获取NPC名称
    return name, "ENpcResident"
end
-- NPC信息
SinusCreditsNpc = {name = GetENpcResidentName(1052608), position = Vector3(18.234497, 1.6937256, 19.424683)}  --憧憬湾宇宙信用点NPC
SinusCreditNpc = {name = GetENpcResidentName(1052612), position = Vector3(18.845, 2.243, -18.906)}  -- 憧憬湾信用点NPC
SinusResearchNpc = {name = GetENpcResidentName(1052605), position = Vector3(-18.906, 2.151, 18.845)}  -- 憧憬湾研究NPC
SinusTphNpc = {name = '驾行威', position = Vector3(-55.91, -0.00, -69.43)}  -- 憧憬湾传送NPC
PhaennaCreditNpc = {name = GetENpcResidentName(1052642), position = Vector3(358.816, 53.193, -438.865)}  -- 琉璃星信用点NPC
PhaennaResearchNpc = {name = GetENpcResidentName(1052629), position = Vector3(321.218, 53.193, -401.236)}  -- 琉璃星研究NPC
PhaennaTphNpc = {name = '航行威', position = Vector3(278.49, 52.03, -377.72)}  -- 琉璃星传送NPC
PhaennaCreditsNpc = {name = GetENpcResidentName(1052640), position = Vector3(358.3275, 52.751778, -400.44257)}  -- 琉璃星宇宙信用点NPC
-- 通过DataId直接获取NPC名称
while Run_script do
    -- currentPj = Inventory.GetItemCount(47594)
    -- local creditsNpcName = (Svc.ClientState.TerritoryType == SinusTerritory) and SinusCreditsNpc.name or PhaennaCreditsNpc.name
    -- local e = Entity.GetEntityByName(creditsNpcName)
    -- if e then
    --     Dalamud.Log(string.format("[Cosmic Helper] 选中: %s", creditsNpcName))
    --     e:SetAsTarget()
    -- end
    -- if Entity.Target and Entity.Target.Name == creditsNpcName then
    --     Dalamud.Log(string.format("[Cosmic Helper] 交互: %s", creditsNpcName))
    --     e:Interact()
    --     sleep(1)
    -- end
    -- local quantityToChange = math.floor(currentPj / 900)

    -- if IsAddonReady("SelectIconString") then
    --     yield("/callback SelectIconString true 2")
    -- end
    -- if quantityToChange > 0 then
    --     for i = 1, quantityToChange do
    --         if IsAddonReady("ShopExchangeItem") then
    --             yield(string.format("/callback ShopExchangeItem true 0 1 9"))
    --             yield("/wait 2")
    --         end
    --         if IsAddonReady("ShopExchangeItemDialog") then
    --             yield("/callback ShopExchangeItemDialog true 0")
    --             yield("/wait 2")
    --         end
    --     end
    -- end


    if IsAddonReady("SelectYesno") then
        Echo("SelectYesno 已加载")
    end
    if IsAddonReady("Shop") then
        Echo("Shop 已加载")
    end
    if IsAddonReady("ContextMenu") then
        Echo("ContextMenu 已加载")
    end
    if IsAddonReady("SelectString") then
        Echo("SelectString 已加载")
    end
    if IsAddonReady("SelectOk") then
        Echo("SelectOk 已加载")
    end
    if IsAddonReady("SelectIconString") then
        Echo("SelectIconString 已加载")
    end
    if IsAddonReady("ShopExchangeCurrency") then
        Echo("ShopExchangeCurrency 已加载")
    end
    if IsAddonReady("ShopExchangeItem") then
        Echo("ShopExchangeItem 已加载")
    end
    if IsAddonReady("ShopExchangeItemDialog") then
        Echo("ShopExchangeItemDialog 已加载")

    end
    if IsAddonReady("ShopExchangeCurrencyDialog") then
        Echo("ShopExchangeCurrencyDialog 已加载")
    end
    if Addons.GetAddon("ShopExchangeCurrency").Ready then
        Echo("ShopExchangeCurrency 已加载")
    end
    -- 循环延迟
    sleep(loopDelay)
end