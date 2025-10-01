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
while Run_script do
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
    -- 循环延迟
    sleep(loopDelay)
end