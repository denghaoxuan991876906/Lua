--[=====[
[[SND Metadata]]
author: baanderson40 嗨呀
version: 1.3.4
description: |
  支持: 
  主要功能：
    -移动中遇阻时自动执行跳跃
    -达成经验值或职业积分目标后自动切换职业（基于ICE设置）
    -使用DR自动好运道模块进行抽奖,不再需要移动到抽奖位置
    -可选择在移动前于随机位置等待设定时长
    -自动缴纳宇宙研究点数进行肝武升级
    -自动购买魔晶石 满30000自动购买
    -添加自动丢弃物品功能  请自行设置好DR自动丢弃物品的清单
plugin_dependencies:
- ICE
- vnavmesh
configs:
  遇阻时跳跃:
    description: 当角色在同一位置卡住时间过长时自动执行跳跃
    default: false
  TP:
    description: 是否使用TP功能 注意tp位置憧憬湾和琉璃星不同, 切换地图时需要手动调整tp位置
    default: false
  TP指令:
    description: 提供你想要使用的tp指令 如 /aetp (x,y,z)   建议tp到一个精确坐标 如使用棍哥的tp指令 需要在stp的自定义同义命令功能中将横杠转掉 如i-ching-teleport 转为 ichingtp 再提供 /ichingtp x y z
    default: ""
  职业循环列表:
    description: |
      当达到经验值或职业积分阈值时循环切换的职业列表（具体取决于ICE中的设置）。输入职业简称或全称并按回车，每行一个职业。请在Simple Tweaks插件中启用"切换职业"命令并保持其为默认设置。留空则禁用职业循环功能
    default: []
  自动丢弃物品:
    description: |
      提供DR自动丢弃物品清单的配置组名称,为空则不开启功能,在每次换取魔晶石时自动丢弃清单中的物品
    default: ""
  上报失败任务:
    description: |
      启用后上报未达到评分阶位的失败任务
    default: false
  EX+4小时限时任务:
    description: |
      启用后将根据当前EX+4小时限时任务自动切换制作职业（循环顺序：铸甲匠→雕金匠→制革匠→织布匠→刻木匠→锻铁匠→重复）
    default: false
  EX+2小时限时任务:
    description: |
      启用后将根据当前EX+2小时限时任务自动切换制作职业（循环顺序：制革匠→织布匠→炼金术士→烹调师→铸甲匠→雕金匠→重复）
    default: false
  点位停留时长:
    description: |
      在随机移动到下个点位前的停留时间（分钟）。设为0则禁用自动移动功能
    default: 0
    min: 0
    max: 1440
  雇员探索委托处理:
    description: |
      当雇员探索完成时暂停宇宙任务。离开后不会返回月面基地。选择"停用"可关闭此功能
    default: "N/A"
    is_choice: true
    choices: ["N/A","琉璃星", "憧憬湾"]
  研究点数缴纳:
    description: |
      启用后自动缴纳宇宙研究点数进行肝武升级
    default: false
  使用备用职业:
    description: |
      在缴纳研究点数时使用战士职业。若工具已保存至套装则无效
    default: false
  肝武职业循环:
    description: |
      当肝武工具完成后循环切换的职业列表。不需包含起始/当前职业，从下一个目标职业开始列出。输入职业简称或全称并按回车，每行一个职业。请在Simple Tweaks插件中启用"切换职业"命令并保持其为默认设置。留空则禁用职业循环功能
    default: []
[[End Metadata]]
--]=====]

-- 导入必要的系统模块
import("System.Numerics") 

--[[
********************************************************************************
*                            高级用户设置                                      *
********************************************************************************
]]

loopDelay  = .1           -- 控制脚本运行速度；值越低越快，值越高越慢（单位：秒/循环）
cycleLoops = 100          -- 在循环切换到下一个职业前运行的循环迭代次数
moveOffSet = 5            -- 为点位移动时间添加随机偏移量，最大偏移5分钟
spotRadius = 3            -- 定义移动半径；选择新点位时玩家将在此半径范围内移动
extraRetainerDelay = false  -- 额外的雇员处理延迟

-- 根据当前所在地图（憧憬湾或琉璃星）设置随机移动点坐标
if Svc.ClientState.TerritoryType == 1237 then -- 憧憬湾
    SpotPos = {
        Vector3(9.521,1.705,14.300), -- 传唤铃
        Vector3(8.870, 1.642, -13.272), -- 宇宙好运道
        Vector3(-9.551, 1.705, -13.721), -- 贡献榜
        Vector3(-12.039, 1.612, 16.360), -- 研明威
        Vector3(7.002, 1.674, -7.293), -- 宇宙好运道（内环）
        Vector3(5.471, 1.660, 5.257), -- 传唤铃（内环）
        Vector3(-6.257, 1.660, 6.100), -- 研明威（内环）
        Vector3(-5.919, 1.660, -5.678), -- 贡献榜（内环）
        Vector3(16.6, 1.7, 16.1),--"梅苏艾东克"
    }
elseif Svc.ClientState.TerritoryType == 1291 then --琉璃星
    SpotPos = {
        Vector3(355.522, 52.625, -409.623), -- 传唤铃
        Vector3(353.649, 52.625, -403.039), -- 宇宙信用点兑换处
        Vector3(356.086, 52.625, -434.961), -- 宇宙好运道
        Vector3(330.380, 52.625, -436.684), -- 贡献榜
        Vector3(319.037, 52.625, -417.655), -- 机甲行动站
    }
end
--[[
********************************************************************************
*                       以下内容请勿修改                                       *
********************************************************************************
]]

-- 辅助函数集合
-- 获取当前EX+2小时限时任务对应的职业
function currentexJobs2H()
    local h = getEorzeaHour()  -- 获取当前艾欧泽亚时间的小时数
    local slot = math.floor(h / 2) * 2  -- 每2小时一个周期
    local jobs = exJobs2H[slot]  -- 根据时间段获取对应职业
    return jobs and jobs[1] or nil  -- 返回职业或空值
end

-- 获取当前EX+4小时限时任务对应的职业
function currentexJobs4H()
    local h = getEorzeaHour()  -- 获取当前艾欧泽亚时间的小时数
    local slot = math.floor(h / 4) * 4  -- 每4小时一个周期
    local jobs = exJobs4H[slot]  -- 根据时间段获取对应职业
    return jobs and jobs[1] or nil  -- 返回职业或空值
end

-- 计算两个坐标点之间的距离
function DistanceBetweenPositions(pos1, pos2)
  local distance = Vector3.Distance(pos1, pos2)  -- 使用向量计算距离
  return distance
end

-- 获取当前艾欧泽亚时间的小时数
function getEorzeaHour()
  local et = os.time() * 1440 / 70  -- 现实时间转换为艾欧泽亚时间（1现实秒=70艾欧泽亚秒）
  return math.floor((et % 86400) / 3600)  -- 计算小时数（0-23）
end

-- 通过DataId直接获取NPC名称
function GetENpcResidentName(dataId)
    local sheet = Excel.GetSheet("ENpcResident")  -- 获取NPC数据表
    if not sheet then return nil, "ENpcResident数据表不可用" end

    local row = sheet:GetRow(dataId)  -- 获取指定ID的NPC数据
    if not row then return nil, "ID为 "..tostring(dataId).." 的记录不存在" end

    local name = row.Singular or row.Name  -- 获取NPC名称
    return name, "ENpcResident"
end

-- 在指定半径范围内随机生成一个位置点
function GetRandomSpotAround(radius, minDist)
    minDist = minDist or 0  -- 最小距离，默认为0
    if #SpotPos == 0 then return nil end  -- 如果没有预设点位，返回空
    if #SpotPos == 1 then  -- 如果只有一个预设点位
        lastSpotIndex = 1
        return SpotPos[1]
    end
    -- 随机选择一个与上次不同的预设点位
    local spotIndex
    repeat
        spotIndex = math.random(1, #SpotPos)
    until spotIndex ~= lastSpotIndex
    lastSpotIndex = spotIndex
    local center = SpotPos[spotIndex]  -- 选中的预设点位作为中心
    
    -- 在中心点周围随机生成一个位置
    local u = math.random()
    local distance = math.sqrt(u) * (radius - minDist) + minDist  -- 随机距离
    local angle = math.random() * 2 * math.pi  -- 随机角度
    local offsetX = math.cos(angle) * distance  -- X轴偏移
    local offsetZ = math.sin(angle) * distance  -- Z轴偏移
    return Vector3(center.X + offsetX, center.Y, center.Z + offsetZ)  -- 返回新位置
end

-- 检查指定插件是否已安装并加载
function HasPlugin(name)
    for plugin in luanet.each(Svc.PluginInterface.InstalledPlugins) do
        if plugin.InternalName == name and plugin.IsLoaded then
            return true
        end
    end
    return false
end

-- 检查指定UI面板是否准备就绪
function IsAddonReady(name)
    local a = Addons.GetAddon(name)
    return a and a.Ready
end

-- 检查指定UI面板是否存在
function IsAddonExists(name)
    local a = Addons.GetAddon(name)
    return a and a.Exists
end

-- 重置跳跃检测状态
function JumpReset()
  lastPos, jumpCount = nil, 0  -- 重置位置记录和跳跃计数
end

-- 根据地图ID获取本地化的地名
function PlaceNameByTerritory(id)
    local terr = Excel.GetSheet("TerritoryType"); if not terr then return nil end  -- 获取地图数据表
    local row  = terr:GetRow(id);                  if not row  then return nil end  -- 获取指定地图数据
    local pn   = row.PlaceName;                    if not pn   then return nil end  -- 获取地名数据

    -- 处理不同格式的地名数据
    if type(pn) == "string" and #pn > 0 then return pn end

    if type(pn) == "userdata" then
        local ok,val = pcall(function() return pn.Value end)
        if ok and val then
            local ok2,name = pcall(function() return val.Singular or val.Name or val:ToString() end)
            if ok2 and name and name ~= "" then return name end
        end
        local okId,rid = pcall(function() return pn.RowId end)
        if okId and type(rid) == "number" then
            local place = Excel.GetSheet("PlaceName"); if not place then return nil end
            local prow  = place:GetRow(rid);           if not prow  then return nil end
            local ok3,name = pcall(function() return prow.Singular or prow.Name or prow:ToString() end)
            if ok3 and name and name ~= "" then return name end
        end
        return nil
    end

    if type(pn) == "number" then
        local place = Excel.GetSheet("PlaceName"); if not place then return nil end
        local prow  = place:GetRow(pn);            if not prow  then return nil end
        local ok,name = pcall(function() return prow.Singular or prow.Name or prow:ToString() end)
        if ok and name and name ~= "" then return name end
    end

    return nil
end

-- 获取当前职业的评分
function RetrieveClassScore()
    classScoreAll = {}  -- 存储所有职业的评分
    -- 如果评分面板未打开，则打开它
    if not IsAddonExists("WKSScoreList") then
        yield("/callback WKSHud true 18")
        sleep(.5)
    end
    local scoreAddon = Addons.GetAddon("WKSScoreList")  -- 获取评分面板
    -- 制作职业行索引
    local dohRows = {2, 21001, 21002, 21003, 21004, 21005, 21006, 21007}
    for _, dohRows in ipairs(dohRows) do
        -- 获取职业名称和评分节点
        local nameNode  = scoreAddon:GetNode(1, 2, 7, dohRows, 4)
        local scoreNode = scoreAddon:GetNode(1, 2, 7, dohRows, 5)
        if nameNode and scoreNode then
            -- 存储职业名称和评分
            table.insert(classScoreAll, {
                className  = string.lower(nameNode.Text),
                classScore = scoreNode.Text
            })
        end
    end
    -- 采集职业行索引
    local dolRows = {2, 21001, 21002}
    for _, dolRows in ipairs(dolRows) do
        -- 获取职业名称和评分节点
        local nameNode  = scoreAddon:GetNode(1, 8, 13, dolRows, 4)
        local scoreNode = scoreAddon:GetNode(1, 8, 13, dolRows, 5)
        if nameNode and scoreNode then
            -- 存储职业名称和评分
            table.insert(classScoreAll, {
                className  = string.lower(nameNode.Text),
                classScore = scoreNode.Text
            })
        end
    end
    -- 找到当前职业的评分
    for i, entry in ipairs(classScoreAll) do
        if Player.Job.Name == entry.className then
            currentScore = entry.classScore
            break
        end
    end
    return currentScore
end

-- 获取肝武研究进度
function RetrieveRelicResearch()
    -- 如果正在制作、采集或任务信息面板打开，则返回0
    if Svc.Condition[CharacterCondition.crafting]
       or Svc.Condition[CharacterCondition.gathering]
       or IsAddonExists("WKSMissionInfomation") then
        if IsAddonExists("WKSToolCustomize") then
            yield("/callback WKSToolCustomize true -1")  -- 关闭工具定制面板
        end
        return 0
    end
    -- 如果工具定制面板未打开，则尝试打开
    if not IsAddonExists("WKSToolCustomize") and IsAddonExists("WKSHud") then
        yield("/callback WKSHud true 15")
        sleep(.25)
    end
    if not IsAddonExists("WKSToolCustomize") then
        return 0  -- 面板无法打开，返回0
    end
    -- 检查肝武各阶段的完成情况
    local ToolAddon = Addons.GetAddon("WKSToolCustomize")
    local rows = {4, 41001, 41002, 41003, 41004, 41005, 41006, 41007}
    local checked = 0
    for _, row in ipairs(rows) do
        -- 获取当前进度和所需进度节点
        local currentNode = ToolAddon:GetNode(1, 55, 68, row, 4, 5)
        local requiredNode = ToolAddon:GetNode(1, 55, 68, row, 4, 7)
        if not currentNode or not requiredNode then break end
        
        -- 转换为数字进行比较
        local current  = toNumber(currentNode.Text)
        local required = toNumber(requiredNode.Text)
        if current == nil or required == nil then break end
        
        if required == 0 then return 1 end  -- 肝武已完成
        if current < required then return 0 end  -- 阶段未完成
        checked = checked + 1
    end
    return (checked > 0) and 2 or 0  -- 2 = 阶段已完成
end

-- 等待指定秒数
function sleep(seconds)
    yield('/wait ' .. tostring(seconds))  -- 执行等待命令
end

-- 将字符串转换为数字
function toNumber(s)
    if type(s) ~= "string" then return tonumber(s) end
    s = s:match("^%s*(.-)%s*$")  -- 去除前后空格
    s = s:gsub(",", "")  -- 去除千位分隔符
    return tonumber(s)  -- 转换为数字
end

-- 工作函数集合
-- 检查宇宙信用点
function CheckCredits()
    if currentCredits >= CreditThreshold and Svc.Condition[CharacterCondition.normalConditions] and not Player.IsBusy then
        Dalamud.Log(string.format("[CosmicCredit] 信用点已达到阈值！准备停止探索并开始兑换。"))
        curPos = Svc.ClientState.LocalPlayer.Position  -- 获取当前位置
        yield('/ice stop')
        local creditsNpcName = (Svc.ClientState.TerritoryType == SinusTerritory) and SinusCreditsNpc.name or PhaennaCreditsNpc.name
        -- 根据当前所在地图处理导航
        if Svc.ClientState.TerritoryType == SinusTerritory then  -- 憧憬湾
            -- 如果距离传送点太远，则返回
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
            -- 等待角色状态稳定
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            -- 导航到梅苏艾东克（信用点NPC）
            IPC.vnavmesh.PathfindAndMoveTo(SinusCreditsNpc.position, false)
            Dalamud.Log("[Cosmic Helper] 去找梅苏艾东克")
            sleep(1)
            -- 监控导航状态，到达附近后停止
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, SinusCreditsNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] 距离梅苏艾东克够近了，停止导航.")
                    IPC.vnavmesh.Stop()
                end
            end
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then  -- 琉璃星
            -- 如果距离传送点太远，则返回
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
            -- 等待角色状态稳定
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            -- 导航到梅苏艾东克（信用点NPC）
            IPC.vnavmesh.PathfindAndMoveTo(PhaennaCreditsNpc.position, false)
            Dalamud.Log("[Cosmic Helper] 去找梅苏艾东克")
            sleep(1)
            -- 监控导航状态，到达附近后停止
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, PhaennaCreditsNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] 距离梅苏艾东克够近了，停止导航.")
                    IPC.vnavmesh.Stop()
                end
            end
        end
        -- 选中信用点NPC并交互
        local e = Entity.GetEntityByName(creditsNpcName)
        if e then
            Dalamud.Log(string.format("[Cosmic Helper] 选中: %s", creditsNpcName))
            e:SetAsTarget()
        end
        if Entity.Target and Entity.Target.Name == creditsNpcName then
            Dalamud.Log(string.format("[Cosmic Helper] 交互: %s", creditsNpcName))
            e:Interact()
            sleep(1)
        end
        if IsAddonReady("SelectIconString") then
            yield("/callback SelectIconString true 1")  -- 选择第二个选项
            sleep(1)
        end
        if Addons.GetAddon("ShopExchangeCurrency").Ready then
            yield(string.format("/callback ShopExchangeCurrency true 4 -1 1 %d", ShopCategoryIndex))
            yield("/wait 2")

            local currentCredits = Inventory.GetItemCount(CreditItemID)
            local quantityToBuy = math.floor(currentCredits / ItemPrice)
            
            if quantityToBuy > 0 then
                yield(string.format("/callback ShopExchangeCurrency true 0 %d %d", ShopItemIndex, quantityToBuy))
                yield("/wait 2")
                
                if Addons.GetAddon("SelectYesno").Ready then
                     yield("/callback SelectYesno true 0")
                     yield("/wait 2")
                end
            end
            
            yield("/callback ShopExchangeCurrency true -1")
            -- 检查是否启用了自动丢弃物品功能
            if DiscardConfig and DiscardConfig ~= "" then
                -- 自动丢弃清单中的物品
                yield(string.format("/pdrdiscard %s", DiscardConfig))
            end
            yield("/wait 4")
        end
        -- 抽奖结束后处理
        if not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
            job = Player.Job
            -- 如果启用了TP功能，则使用TP
            if isTP and tpStr then
                sleep(1) 
                useTP()
            else
                -- 否则移动到随机位置
                if job.IsCrafter then
                    aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
                    IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
                    Dalamud.Log("[Cosmic Helper] 前往随机位置 " .. tostring(aroundSpot))
                    lastMoveTime = os.time()
                    sleep(1)
                end
                -- 监控导航状态
                while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                    sleep(.2)
                    curPos = Svc.ClientState.LocalPlayer.Position
                    if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                        Dalamud.Log("[Cosmic Helper] 接近随机位置，停止导航")
                        IPC.vnavmesh.Stop()
                        break
                    end
                end
            end
            -- 关闭自动对话
            if EnabledAutoText then
                yield("/at disable")
                EnabledAutoText = false
            end
            sleep(1)
            -- 重新开启ICE
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
            yield("/ice start")
        end
    end
end
-- 检查是否需要处理月球信用点（达到上限时进行抽奖）
function ShouldCredit()
    -- 检查是否达到信用点上限且角色处于正常状态
    if lunarCredits >= 1000 and Svc.Condition[CharacterCondition.normalConditions] and not Player.IsBusy then
        -- 如果自动对话未启用，则启用它
        yield("/pdr cosfortune ()")
        sleep(2)
        -- 重新开启ICE
        Dalamud.Log("[Cosmic Helper] 开启 ICE")
        yield("/ice start")
    end
end

-- 使用TP功能
function useTP()
    curPos = Svc.ClientState.LocalPlayer.Position  -- 获取当前位置
    
    -- 根据当前所在地图处理
    if Svc.ClientState.TerritoryType == SinusTerritory then  -- 憧憬湾
        -- 如果距离传送点太远，则返回
        if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
            Dalamud.Log("[Cosmic Helper] 宇宙返回")
            yield('/gaction 任务指令1')
            sleep(5)
        end
        -- 等待角色状态稳定
        while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
            sleep(.5)
        end
        -- 导航到换区NPC附近
        IPC.vnavmesh.PathfindAndMoveTo(SinusTphNpc.position, false)
        Dalamud.Log("[Cosmic Helper] 假装去找换区NPC")
        sleep(1)
        -- 到达附近后停止导航
        while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
            sleep(.02)
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, SinusTphNpc.position) < 5 then
                Dalamud.Log("[Cosmic Helper] 距离换区NPC够近了，停止导航.")
                IPC.vnavmesh.Stop()
            end
        end
        -- 选中换区NPC
        local e = Entity.GetEntityByName(SinusTphNpc.name)
        if e then
            Dalamud.Log("[Cosmic Helper] 选中: " .. SinusTphNpc.name)
            e:SetAsTarget()
        end
    elseif Svc.ClientState.TerritoryType == PhaennaTerritory then  -- 琉璃星
        -- 如果距离传送点太远，则返回
        if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
            Dalamud.Log("[Cosmic Helper] 宇宙返回")
            yield('/gaction 任务指令1')
            sleep(5)
        end
        -- 等待角色状态稳定
        while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
            sleep(.5)
        end
        -- 导航到换区NPC附近
        IPC.vnavmesh.PathfindAndMoveTo(PhaennaTphNpc.position, false)
        Dalamud.Log("[Cosmic Helper] 假装去找换区NPC")
        sleep(1)
        -- 到达附近后停止导航
        while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
            sleep(.02)
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, PhaennaTphNpc.position) < 5 then
                Dalamud.Log("[Cosmic Helper] 距离换区NPC够近了，停止导航.")
                IPC.vnavmesh.Stop()
                break
            end
        end
        -- 选中换区NPC
        local e = Entity.GetEntityByName(PhaennaTphNpc.name)
        if e then
            Dalamud.Log("[Cosmic Helper] 选中: " .. PhaennaTphNpc.name)
            e:SetAsTarget()
        end
    end
    
    -- 执行TP指令
    sleep(3)
    yield(tpStr)
    sleep(3)
end

-- 检查是否需要切换职业
function ShouldCycle()
    -- 如果信用点达到上限，则不切换职业
    if LimitConfig > 0 and lunarCredits >= LimitConfig then
        return
    end
    
    -- 检查角色是否处于正常状态
    if Svc.Condition[CharacterCondition.normalConditions] then
        -- 如果正在执行任务或角色忙碌，则重置循环计数
        if (IsAddonExists("WKSMission")
        or IsAddonExists("WKSMissionInfomation")
        or IsAddonExists("WKSReward")
        or Player.IsBusy) then
            cycleCount = 0
            return
        else
            -- 否则增加循环计数并记录日志
            cycleCount = cycleCount + 1
            Dalamud.Log("[Cosmic Helper] 职业循环次数: " .. cycleCount)
        end
    end
    
    -- 每20次循环输出一次提示
    if cycleCount > 0 and cycleCount % 20 == 0 then
            yield("/echo [Cosmic Helper] 职业循环次数: " .. cycleCount .. "/" .. cycleLoops)
    end
    
    -- 达到循环次数阈值时切换职业
    if cycleCount >= cycleLoops then
        -- 如果已到达职业列表末尾，则退出脚本
        if jobCount == totalJobs then
            Dalamud.Log("[Cosmic Helper] 已到达职业列表末尾。正在退出脚本")
            yield("/echo [Cosmic Helper] 已到达职业列表末尾。正在退出脚本")
            Run_script = false
            return
        end
        -- 切换到下一个职业
        Dalamud.Log("[Cosmic Helper] 正在切换到 -> " .. JobsConfig[jobCount])
        yield("/echo [Cosmic Helper] 正在切换到 -> " .. JobsConfig[jobCount])
        yield("/equipjob " .. JobsConfig[jobCount])  -- 执行职业切换命令
        sleep(2)
        -- 重新开启ICE
        Dalamud.Log("[Cosmic Helper] 开启 ICE")
        yield("/ice start")
        jobCount = jobCount + 1  -- 更新职业计数
        cycleCount = 0  -- 重置循环计数
    end
end

-- 根据EX+限时任务切换职业
function ShouldExTime()
    CurJob = Player.Job.Abbreviation  -- 获取当前职业简称
    
    -- 处理EX+4小时限时任务
    if Ex4TimeConfig then
        Cur4ExJob = currentexJobs4H()  -- 获取当前应选职业
        if Cur4ExJob and CurJob ~= Cur4ExJob then  -- 如果当前职业不符
            local waitcount = 0
            -- 等待任务结束
            while IsAddonExists("WKSMissionInfomation") do
                sleep(.1)
                waitcount = waitcount + 1
                if waitcount >= 50 then
                    Dalamud.Log("[Cosmic Helper] 等待任务结束切换职业.")
                    yield("/echo [Cosmic Helper] 等待任务结束切换职业.")
                    waitcount = 0
                end
            end
            -- 切换职业
            Dalamud.Log("[Cosmic Helper] 停止 ICE")
            yield("/ice stop")
            sleep(1)
            yield("/echo 当前 EX+ time: " .. getEorzeaHour() .. " 切换到 " .. Cur4ExJob)
            yield("/equipjob " .. Cur4ExJob)  -- 执行职业切换命令
            sleep(1)
            -- 重新开启ICE
            yield("/ice start")
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
        end
    -- 处理EX+2小时限时任务
    elseif Ex2TimeConfig then
        Cur2ExJob = currentexJobs2H()  -- 获取当前应选职业
        if Cur2ExJob and CurJob ~= Cur2ExJob then  -- 如果当前职业不符
            local waitcount = 0
            -- 等待任务结束
            while IsAddonExists("WKSMissionInfomation") do
                sleep(.1)
                waitcount = waitcount + 1
                if waitcount >= 50 then
                    Dalamud.Log("[Cosmic Helper] 等待任务结束切换职业.")
                    yield("/echo [Cosmic Helper] 等待任务结束切换职业.")
                    waitcount = 0
                end
            end
            -- 切换职业
            Dalamud.Log("[Cosmic Helper] 停止 ICE")
            yield("/ice stop")
            sleep(1)
            yield("/echo 当前 EX+ time: " .. getEorzeaHour() .. " 切换到 " .. Cur2ExJob)
            yield("/equipjob " .. Cur2ExJob)  -- 执行职业切换命令
            sleep(1)
            -- 重新开启ICE
            yield("/ice start")
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
        end
    end
end

-- 检查是否需要跳跃（角色卡住时）
function ShouldJump()
  -- 如果角色未移动，则重置跳跃检测
  if not Player.IsMoving then JumpReset(); return end
  
  local pos = Svc.ClientState.LocalPlayer.Position  -- 获取当前位置
  -- 如果是首次记录位置，则初始化
  if not lastPos then lastPos = pos; jumpCount = 0; return end
  
  -- 如果移动距离足够，则重置跳跃检测
  if DistanceBetweenPositions(pos, lastPos) >= 4 then
    JumpReset(); return
  end
  
  -- 否则增加跳跃计数，达到阈值时执行跳跃
  jumpCount = (jumpCount or 0) + 1
  if jumpCount >= 5 then
    yield("/gaction 跳跃")  -- 执行跳跃命令
    Dalamud.Log("[Cosmic Helper] 位置没有发生变化 跳一下")
    JumpReset()  -- 重置跳跃检测
  end
end

-- 检查是否需要移动到新位置
function ShouldMove()
    -- 如果信用点达到上限，则不移动
    if LimitConfig > 0 and lunarCredits >= LimitConfig then
        return
    end
    
    -- 初始化最后移动时间
    if lastMoveTime == nil then
        lastMoveTime = os.time()
        return
    end
    
    -- 初始化随机偏移量
    if offSet == nil then
        offSet = math.random(-moveOffSet, moveOffSet)
    end
    
    -- 计算移动间隔（基础时间+随机偏移）
    local interval = math.max(1, MoveConfig + offSet)
    -- 检查是否达到移动时间
    if os.time() - lastMoveTime >= interval * 60 then
        local waitcount = 0
        -- 等待任务结束
        while IsAddonExists("WKSMissionInfomation") do
            sleep(.1)
            waitcount = waitcount + 1
            Dalamud.Log("[Cosmic Helper] 等待移动")
            if waitcount >= 10 then
                yield("/echo [Cosmic Helper] 等待移动.")
                waitcount = 0
            end
        end
        
        -- 停止ICE
        Dalamud.Log("[Cosmic Helper] Stopping ICE")
        yield("/ice stop")
        
        curPos = Svc.ClientState.LocalPlayer.Position  -- 获取当前位置
        
        -- 根据当前所在地图处理返回
        if Svc.ClientState.TerritoryType == SinusTerritory then  -- 憧憬湾
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then  -- 琉璃星
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
        end
        
        -- 等待角色状态稳定
        while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
            sleep(.5)
        end
        
        -- 如果启用了TP功能，则使用TP
        if isTP and tpStr then 
            sleep(1) 
            useTP()
        else
            -- 否则移动到随机位置
            aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
            IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
            Dalamud.Log("[Cosmic Helper] 移动到随机位置 " .. tostring(aroundSpot))
            sleep(1)
            -- 监控导航状态，到达附近后停止
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                    Dalamud.Log("[Cosmic Helper] 接近随机位置，停止导航")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        end
        
        -- 重新开启ICE
        yield("/ice start")
        Dalamud.Log("[Cosmic Helper] 开启 ICE")
        lastMoveTime = os.time()  -- 更新最后移动时间
        offSet = nil  -- 重置偏移量
    end
end

-- 处理肝武相关操作（缴纳研究点数、切换职业）
function ShouldRelic()
    -- 获取肝武研究进度
    local researchStatus = RetrieveRelicResearch()
    
    -- 0: 阶段未完成，不处理
    if researchStatus == 0 then
        return
    -- 1: 肝武已完成，切换到下一个职业
    elseif researchStatus == 1 then
        yield("/ice stop")  -- 停止ICE
        
        -- 关闭相关面板
        if IsAddonExists("WKSMission") then
            yield("/callback WKSMission true -1")
        end
        if IsAddonExists("WKSToolCustomize") then
            yield("/callback WKSToolCustomize true -1")
        end
        
        -- 如果已到达职业列表末尾，则退出脚本
        if jobCount == totalRelicJobs then
            Dalamud.Log("[Cosmic Helper] 已到达职业列表末尾。正在退出脚本.")
            yield("/echo [Cosmic Helper] 已到达职业列表末尾。正在退出脚本.")
            Run_script = false
            return
        end
        
        -- 切换到下一个职业
        Dalamud.Log("[Cosmic Helper] 切换到 -> " .. RelicJobsConfig[jobCount])
        yield("/echo [Cosmic Helper] 切换到 -> " .. RelicJobsConfig[jobCount])
        yield("/equipjob " .. RelicJobsConfig[jobCount])  -- 执行职业切换命令
        sleep(1)
        jobCount = jobCount + 1  -- 更新职业计数
        
        -- 如果新阶段未完成，则重新开启ICE
        if RetrieveRelicResearch() == 0 then
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
            yield("/ice start")
        end
        return
    -- 2: 阶段已完成，缴纳研究点数
    elseif researchStatus == 2 then
        -- 启用自动对话
        if not IPC.TextAdvance.IsEnabled() then
            yield("/at enable")
            EnabledAutoText = true
        end
        
        Dalamud.Log("[Cosmic Helper] 肝武完成")
        yield("/echo [Cosmic Helper] 肝武完成")
        
        -- 等待任务信息面板关闭
        local waitcount = 0
        while IsAddonReady("WKSMissionInfomation") do
            sleep(.1)
            waitcount = waitcount + 1
            Dalamud.Log("[Cosmic Helper] 等待移动")
            if waitcount >= 20 then
                yield("/echo [Cosmic Helper] 等待移动.")
                waitcount = 0
            end
        end
        
        -- 停止ICE
        Dalamud.Log("[Cosmic Helper] Stopping ICE")
        yield("/ice stop")
        
        curPos = Svc.ClientState.LocalPlayer.Position  -- 获取当前位置
        
        -- 根据当前所在地图导航到研明威（研究点数NPC）
        if Svc.ClientState.TerritoryType == SinusTerritory then  -- 憧憬湾
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
            -- 等待角色状态稳定
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            -- 导航到研明威
            IPC.vnavmesh.PathfindAndMoveTo(SinusResearchNpc.position, false)
            Dalamud.Log("[Cosmic Helper] 去找研明威")
            sleep(1)
            -- 到达附近后停止导航
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, SinusResearchNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] 接近研明威，停止导航.")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then  -- 琉璃星
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
            -- 等待角色状态稳定
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            -- 导航到研明威
            IPC.vnavmesh.PathfindAndMoveTo(PhaennaResearchNpc.position, false)
            Dalamud.Log("[Cosmic Helper] 去找研明威")
            sleep(1)
            -- 到达附近后停止导航
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.02)
                curPos = Svc.ClientState.LocalPlayer.Position
                if DistanceBetweenPositions(curPos, PhaennaResearchNpc.position) < 5 then
                    Dalamud.Log("[Cosmic Helper] 接近研明威，停止导航.")
                    IPC.vnavmesh.Stop()
                    break
                end
            end
        end
        
        CurJob = Player.Job  -- 记录当前职业
        sleep(.1)
        
        -- 如果启用了备用职业，则切换到战士
        if AltJobConfig then yield("/equipjob war") end
        
        -- 选中研明威并交互
        local e = Entity.GetEntityByName(SinusResearchNpc.name)
        if e then
            Dalamud.Log("[Cosmic Helper] 选中: " .. SinusResearchNpc.name)
            e:SetAsTarget()
        end
        if Entity.Target and Entity.Target.Name == SinusResearchNpc.name then
            Dalamud.Log("[Cosmic Helper] 交互: " .. SinusResearchNpc.name)
            Entity.Target:Interact()
            sleep(1)
        end
        
        -- 处理缴纳研究点数的界面交互
        while not IsAddonReady("SelectString") do
            sleep(1)
        end
        if IsAddonReady("SelectString") then
            yield("/callback SelectString true 0")  -- 选择第一个选项
            sleep(1)
        end
        
        while not IsAddonReady("SelectIconString") do
            sleep(1)
        end
        if IsAddonReady("SelectIconString") then
            StringId = CurJob.Id - 8  -- 计算职业对应的ID
            yield("/callback SelectIconString true " .. StringId)  -- 选择对应职业
        end
        
        while not IsAddonReady("SelectYesno") do
            sleep(1)
        end
        if IsAddonReady("SelectYesno") then
            yield("/callback SelectYesno true 0")  -- 确认
        end
        
        -- 等待确认界面关闭
        while IsAddonExists("SelectYesno") do
            sleep(1)
        end
        
        -- 切换回原职业
        if AltJobConfig then yield("/equipjob " .. CurJob.Name) end
        
        -- 处理后续移动
        if CurJob.IsCrafter then
            if isTP and tpStr then 
                sleep(1) 
                useTP()
            else
                aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
                IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
                Dalamud.Log("[Cosmic Helper] 移动到随机位置 " .. tostring(aroundSpot))
                lastMoveTime = os.time()
                sleep(2)
                -- 监控导航状态
                while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                    sleep(.2)
                    curPos = Svc.ClientState.LocalPlayer.Position
                    if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                        Dalamud.Log("[Cosmic Helper] 接近随机位置，停止导航")
                        IPC.vnavmesh.Stop()
                        break
                    end
                end
            end
        end
        
        -- 关闭自动对话
        if EnabledAutoText then
            yield("/at disable")
            EnabledAutoText = false
        end
        
        -- 如果新阶段未完成，则重新开启ICE
        if RetrieveRelicResearch() == 0 then
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
            yield("/ice start")
        end
    end
end

-- 处理失败任务上报
function ShouldReport()
    curJob = Player.Job  -- 获取当前职业
    -- 当任务信息面板打开且当前职业是制作职业时
    while IsAddonExists("WKSMissionInfomation") and curJob.IsCrafter do
        -- 当配方手册打开且角色处于正常状态时
        while IsAddonExists("WKSRecipeNotebook") and Svc.Condition[CharacterCondition.normalConditions] do
            sleep(.1)
            reportCount = reportCount + 1
            -- 每50次循环上报一次失败任务
            if reportCount >= 50 then
                yield("/callback WKSMissionInfomation true 11")
                Dalamud.Log("[Cosmic Helper] 记录失败任务")
                yield("/echo [Cosmic Helper] 记录失败任务")
                reportCount = 0
            end
        end
        reportCount = 0
        sleep(.1)
    end
    
    -- 如果启用了EX+限时任务，则处理职业切换
    if Ex4TimeConfig or Ex2TimeConfig then
        ShouldExTime()
    end
end

-- 处理雇员探索委托
function ShouldRetainer()
    -- 检查是否有雇员探索完成
    if IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() then
        local waitcount = 0
        -- 等待任务结束
        while IsAddonExists("WKSMissionInfomation") do
            sleep(.2)
            waitcount = waitcount + 1
            Dalamud.Log("[Cosmic Helper] 等待收雇员")
            if waitcount >= 15 then
                yield("/echo [Cosmic Helper] 等待收雇员")
                waitcount = 0
            end
        end
        
        -- 停止ICE
        Dalamud.Log("[Cosmic Helper] Stopping ICE")
        yield("/ice stop")
        
        -- 根据配置的区域处理导航
        if SelectedBell.zone == "憧憬湾" then
            curPos = Svc.ClientState.LocalPlayer.Position
            -- 如果距离传送点太远，则返回
            if DistanceBetweenPositions(curPos, SinusGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
        elseif SelectedBell.zone == "琉璃星" then
            curPos = Svc.ClientState.LocalPlayer.Position
            -- 如果距离传送点太远，则返回
            if DistanceBetweenPositions(curPos, PhaennaGateHub) > 75 then
                Dalamud.Log("[Cosmic Helper] 宇宙返回")
                yield('/gaction 任务指令1')
                sleep(5)
            end
        else
            -- 否则使用以太水晶移动
            IPC.Lifestream.ExecuteCommand(SelectedBell.aethernet)
            Dalamud.Log("[Cosmic Helper] 移动到 " .. tostring(SelectedBell.aethernet))
            sleep(2)
        end
        
        -- 等待角色状态稳定
        while Svc.Condition[CharacterCondition.betweenAreas]
            or Svc.Condition[CharacterCondition.casting]
            or Svc.Condition[CharacterCondition.betweenAreasForDuty]
            or IPC.Lifestream.IsBusy() do
            sleep(.5)
        end
        sleep(2)
        
        -- 导航到传唤铃
        if SelectedBell.position ~= nil then
            IPC.vnavmesh.PathfindAndMoveTo(SelectedBell.position, false)
            Dalamud.Log("[Cosmic Helper] 移动到传唤铃")
            sleep(2)
        end
        
        -- 到达传唤铃附近后停止导航
        while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                sleep(.2)
            curPos = Svc.ClientState.LocalPlayer.Position
            if DistanceBetweenPositions(curPos, SelectedBell.position) < 3 then
                Dalamud.Log("[Cosmic Helper] 足够接近传唤铃")
                IPC.vnavmesh.Stop()
                break
            end
        end
        
        -- 选中传唤铃
        while Svc.Targets.Target == nil or Svc.Targets.Target.Name:GetText() ~= "传唤铃" do
            Dalamud.Log("[Cosmic Helper] Targeting 传唤铃")
            yield("/target 传唤铃")
            sleep(1)
        end
        
        -- 与传唤铃交互，打开雇员列表
        if not Svc.Condition[CharacterCondition.occupiedSummoningBell] then
            Dalamud.Log("[Cosmic Helper] 交互传唤铃")
            while not IsAddonReady("RetainerList") do
                yield("/interact")
                sleep(1)
            end
            if IsAddonReady("RetainerList") then
                Dalamud.Log("[Cosmic Helper] Enable AutoRetainer")
                yield("/ays e")  -- 启用AutoRetainer处理
                sleep(1)
            end
        end
        
        -- 等待雇员处理完成
        while IPC.AutoRetainer.IsBusy() do
            sleep(1)
        end
        sleep(2)
        
        -- 关闭雇员列表
        if IsAddonExists("RetainerList") then
            Dalamud.Log("[Cosmic Helper] 关闭雇员列表")
            yield("/callback RetainerList true -1")
            sleep(1)
        end
        
        -- 额外延迟处理
        if extraRetainerDelay then
            sleep(5)  -- 等待脚本
            while Svc.Condition[CharacterCondition.occupiedSummoningBell] do
                sleep(.1)
            end
            sleep(2)
            while Svc.Condition[CharacterCondition.occupiedSummoningBell] do
                sleep(.1)
            end
        end
        
        -- 处理后续移动
        if Svc.ClientState.TerritoryType == SinusTerritory then  -- 憧憬湾
            if isTP and tpStr then 
                sleep(1) 
                useTP()
            else
                aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
                IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
                Dalamud.Log("[Cosmic Helper] 移动到随机位置 " .. tostring(aroundSpot))
                sleep(1)
                -- 监控导航状态
                while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                    sleep(.2)
                    curPos = Svc.ClientState.LocalPlayer.Position
                    if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                        Dalamud.Log("[Cosmic Helper] 接近随机位置，停止导航")
                        IPC.vnavmesh.Stop()
                        break
                    end
                end
            end
            sleep(1)
            -- 重新开启ICE
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
            yield("/ice start")
            return
        elseif Svc.ClientState.TerritoryType == PhaennaTerritory then  -- 琉璃星
            if isTP and tpStr then 
                sleep(1) 
                useTP()
            else
                aroundSpot = GetRandomSpotAround(spotRadius, minRadius)
                IPC.vnavmesh.PathfindAndMoveTo(aroundSpot, false)
                Dalamud.Log("[Cosmic Helper] 移动到随机位置 " .. tostring(aroundSpot))
                sleep(1)
                -- 监控导航状态
                while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                    sleep(.2)
                    curPos = Svc.ClientState.LocalPlayer.Position
                    if DistanceBetweenPositions(curPos, aroundSpot) < 3 then
                        Dalamud.Log("[Cosmic Helper] 接近随机位置，停止导航")
                        IPC.vnavmesh.Stop()
                        break
                    end
                end
            end
            sleep(1)
            -- 重新开启ICE
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
            yield("/ice start")
            return
        else
            -- 否则传送回宇宙区域
            Dalamud.Log("[Cosmic Helper] Teleport to Cosmic")
            yield("/li Cosmic")
            sleep(3)
        end
        
        -- 确保成功传送到宇宙区域
        local cosmicCount = 0
        while not Svc.ClientState.TerritoryType ~= SinusTerritory
            and Svc.ClientState.TerritoryType ~= PhaennaTerritory do
            if not IPC.Lifestream.IsBusy() then
                    cosmicCount = cosmicCount + 1
                    if cosmicCount >=  20 then
                        Dalamud.Log("[Cosmic Helper] Failed to teleport to Cosmic. Trying agian.")
                        yield("/echo [Cosmic Helper] Failed to teleport to Cosmic. Trying agian.")
                        yield("/li Cosmic")
                        cosmicCount = 0
                    end
            else
                cosmicCount = 0
            end
            sleep(.5)
        end
        
        -- 回到宇宙区域后处理
        if Svc.ClientState.TerritoryType == SinusTerritory
            or Svc.ClientState.TerritoryType == PhaennaTerritory then
            while Svc.Condition[CharacterCondition.betweenAreas]
               or Svc.Condition[CharacterCondition.casting]
               or Svc.Condition[CharacterCondition.occupied33] do
                sleep(.5)
            end
            Dalamud.Log("[Cosmic Helper] 宇宙返回")
            yield('/gaction 任务指令1')
            sleep(5)
            while Svc.Condition[CharacterCondition.betweenAreas] or Svc.Condition[CharacterCondition.casting] do
                sleep(.5)
            end
            sleep(1)
            -- 重新开启ICE
            Dalamud.Log("[Cosmic Helper] 开启 ICE")
            yield("/ice start")
        end
    end
end

-- 初始执行一次TP（如果启用）
function tpOnce()
    if isTP and tpStr and tpOnceFlag then
        useTP()
        tpOnceFlag = false  -- 执行后标记为已执行
    end
end

--[[
********************************************************************************
*                                脚本设置                                       *
********************************************************************************
]]

-- 配置变量（从配置中读取）
JumpConfig      = Config.Get("遇阻时跳跃")          -- 遇阻时跳跃开关
isTP            = Config.Get("TP")                  -- TP功能开关
tpStr           = Config.Get("TP指令")              -- TP指令内容
JobsConfig      = Config.Get("职业循环列表")        -- 职业循环列表
--LimitConfig     = Config.Get("月球信用点上限")      -- 月球信用点上限
FailedConfig    = Config.Get("上报失败任务")        -- 上报失败任务开关
Ex4TimeConfig   = Config.Get("EX+4小时限时任务")    -- EX+4小时限时任务开关
Ex2TimeConfig   = Config.Get("EX+2小时限时任务")    -- EX+2小时限时任务开关
MoveConfig      = Config.Get("点位停留时长")        -- 点位停留时长
RetainerConfig  = Config.Get("雇员探索委托处理")    -- 雇员探索委托处理设置
ResearchConfig  = Config.Get("研究点数缴纳")        -- 研究点数缴纳开关
AltJobConfig    = Config.Get("使用备用职业")        -- 使用备用职业开关
RelicJobsConfig = Config.Get("肝武职业循环")        -- 肝武职业循环列表
DiscardConfig     = Config.Get("自动丢弃物品")      -- 自动丢弃物品清单配置组名称



-- 状态变量
Run_script        = true               -- 脚本运行标志
lastPos           = nil                -- 上次位置记录
totalJobs         = JobsConfig.Count   -- 职业循环列表总数
totalRelicJobs    = RelicJobsConfig.Count  -- 肝武职业循环列表总数
reportCount       = 0                  -- 上报计数
cycleCount        = 0                  -- 循环计数
jobCount          = 0                  -- 职业计数
lunarCredits      = 0                  -- 月球信用点数量
lunarCycleCount   = 0                  -- 月球信用点循环计数
lastSpotIndex     = nil                -- 上次点位索引
lastMoveTime      = nil                -- 上次移动时间
offSet            = nil                -- 时间偏移量
minRadius         = .5                 -- 最小移动半径
SelectedBell      = nil                -- 选中的传唤铃
ClassScoreAll     = {}                 -- 所有职业评分
currentCredits      = 0                   -- 宇宙信用点数

-- 角色状态枚举
CharacterCondition = {
    normalConditions                   = 1, -- 正常状态（移动或站立）
    mounted                            = 4, -- 骑乘中
    crafting                           = 5, -- 制作中
    gathering                          = 6, -- 采集中
    casting                            = 27, -- 施法中
    occupiedInQuestEvent               = 32, -- 任务事件中
    occupied33                         = 33, -- 占用状态33
    occupiedMateriaExtractionAndRepair = 39, --  materia提取和修理中
    executingCraftingAction            = 40, -- 执行制作动作
    preparingToCraft                   = 41, -- 准备制作
    executingGatheringAction           = 42, -- 执行采集动作
    betweenAreas                       = 45, -- 区域间移动中
    jumping48                          = 48, -- 跳跃中
    occupiedSummoningBell              = 50, -- 传唤铃操作中
    mounting57                         = 57, -- 正在骑乘
    unknown85                          = 85, -- 采集相关状态
}


-- 读取职业数据表
local sheet = Excel.GetSheet("ClassJob")
assert(sheet, "ClassJob数据表未找到")
Jobs = {}
-- 职业ID范围8-18（制作和采集职业）
for id = 8, 18 do
    local row = sheet:GetRow(id)
    if row then
        local name = row.Name or row["Name"]
        local abbr = row.Abbreviation or row["Abbreviation"]
        if name and abbr then
            Jobs[id] = { name = name, abbr = abbr }  -- 存储职业名称和简称
        else
            print(("ClassJob %d: 缺少名称/简称"):format(id))
        end
    else
        print(("ClassJob %d: 记录未找到"):format(id))
    end
end

--[[职业参考
Jobs[id].name 或 Jobs[id].abbr
8  - CRP 刻木匠
9  - BSM 锻铁匠
10 - ARM 铸甲匠
11 - GSM 雕金匠
12 - LTW 制革匠
13 - WVR 织布匠
14 - ALC 炼金术士
15 - CUL 烹调师
16 - MIN 采矿工
17 - BTN 园艺工
18 - FSH 捕鱼人
]]

-- 位置信息
SinusGateHub = Vector3(0,0,0)  -- 憧憬湾传送点
PhaennaGateHub = Vector3(340.721, 52.864, -418.183)  -- 琉璃星传送点

-- 传唤铃位置信息
SummoningBell = {
    {zone = "琉璃星", aethernet = nil, position = Vector3(358.380, 52.625, -409.429)},
    {zone = "憧憬湾", aethernet = nil, position = Vector3(10.531, 1.612, 17.287)},
}

-- 根据配置选择传唤铃
if RetainerConfig ~= "N/A" then
    for _, bell in ipairs(SummoningBell) do
        if bell.zone == RetainerConfig then
            SelectedBell = bell
            break
        end
    end
end

-- 监控的物品和阈值
CreditItemID = 45690      -- 宇宙信用点的物品ID
CreditThreshold = 30000   -- 触发兑换的数量阈值
-- 要兑换的物品信息
ItemToBuyName = "名匠魔晶石拾壹型"
ItemPrice = 450           -- 物品单价
-- 购买流程设置
-- 在商店界面(Addon: ShopExchangeCurrency)中，"其他"分类是第几个？
-- 这里我们假设是第4个（索引为3）。
ShopCategoryIndex = 3
-- 在"其他"分类中，"名匠魔晶石拾贰型"是第35个物品（要算上前面的那4件衣服），所以索引是34。
ShopItemIndex = 43

-- 地图ID
SinusTerritory = 1237      -- 憧憬湾
PhaennaTerritory = 1291    -- 琉璃星
-- NPC信息
SinusCreditsNpc = {name = GetENpcResidentName(1052608), position = Vector3(18.234497, 1.6937256, 19.424683)}  --憧憬湾宇宙信用点NPC
SinusCreditNpc = {name = GetENpcResidentName(1052612), position = Vector3(18.845, 2.243, -18.906)}  -- 憧憬湾信用点NPC
SinusResearchNpc = {name = GetENpcResidentName(1052605), position = Vector3(-18.906, 2.151, 18.845)}  -- 憧憬湾研究NPC
SinusTphNpc = {name = '驾行威', position = Vector3(-55.91, -0.00, -69.43)}  -- 憧憬湾传送NPC
PhaennaCreditNpc = {name = GetENpcResidentName(1052642), position = Vector3(358.816, 53.193, -438.865)}  -- 琉璃星信用点NPC
PhaennaResearchNpc = {name = GetENpcResidentName(1052629), position = Vector3(321.218, 53.193, -401.236)}  -- 琉璃星研究NPC
PhaennaTphNpc = {name = '航行威', position = Vector3(278.49, 52.03, -377.72)}  -- 琉璃星传送NPC
PhaennaCreditsNpc = {name = GetENpcResidentName(1052640), position = Vector3(358.3275, 52.751778, -400.44257)}  -- 琉璃星宇宙信用点NPC
-- EX+4小时限时任务对应的职业
exJobs4H = {
    [0] = {Jobs[10].abbr},   -- ARM 铸甲匠 00:00–03:59
    [4] = {Jobs[11].abbr},   -- GSM 雕金匠 04:00–07:59
    [8] = {Jobs[12].abbr},   -- LTW 制革匠 08:00–11:59
    [12] = {Jobs[13].abbr},  -- WVR 织布匠 12:00–15:59
    [16] = {Jobs[14].abbr},  -- ALC 炼金术士 16:00–19:59
    [20] = {Jobs[15].abbr},  -- CUL 烹调师 20:00–23:59
}

-- EX+2小时限时任务对应的职业
exJobs2H = {
  [0]  = {Jobs[12].abbr},   -- LTW 制革匠 00:00-02:59
  [4]  = {Jobs[13].abbr},   -- WVR 织布匠 04:00-05:59
  [8]  = {Jobs[14].abbr},   -- ALC 炼金术士 08:00-09:59
  [12] = {Jobs[15].abbr},   -- CUL 烹调师 12:00-13:59
  [16] = {Jobs[10].abbr},   -- ARM 铸甲匠 16:00-17:59
  [20] = {Jobs[11].abbr},   -- GSM 雕金匠 20:00-21:59
}

--[[
********************************************************************************
*                            脚本主循环开始                                    *
********************************************************************************
]]


yield("/echo Cosmic Helper 已启动!")

-- 插件检查
if JobsConfig.Count > 0 and not HasPlugin("SimpleTweaksPlugin") then
    yield("/echo [Cosmic Helper] 职业循环需要SimpleTweaks插件。脚本将在不切换职业的情况下继续运行。")
    JobsConfig = nil
end
if LimitConfig > 0 and not HasPlugin("TextAdvance") then
    yield("/echo [Cosmic Helper] 月球信用点抽奖需要TextAdvance插件。脚本将在不进行抽奖的情况下继续运行。")
    LimitConfig = 0
end
if ResearchConfig and not HasPlugin("TextAdvance") then
    yield("/echo [Cosmic Helper] 研究点数缴纳需要TextAdvance插件。脚本将在不提交研究点数的情况下继续运行。")
    ResearchConfig = 0
end
if RetainerConfig ~= "N/A" and not HasPlugin("AutoRetainer") then
    yield("/echo [Cosmic Helper] 雇员处理需要AutoRetainer插件。脚本将在不处理雇员的情况下继续运行。")
    RetainerConfig = "N/A"
end
local job = Player.Job
if not job.IsCrafter and MoveConfig > 0 then
    yield("/echo [Cosmic Helper] 只有制作职业可以移动。脚本将继续运行。")
    MoveConfig = 0
end
if RelicJobsConfig.Count > 0 and not HasPlugin("SimpleTweaksPlugin") then
    yield("/echo [Cosmic Helper] 职业循环需要SimpleTweaks插件。脚本将在不切换职业的情况下继续运行。")
    RelicJobsConfig = nil
end
if Ex4TimeConfig and Ex2TimeConfig then
    yield("/echo [Cosmic Helper] 同时启用EX+两种限时任务不受支持。脚本将只处理EX+4小时任务。")
    Ex2TimeConfig = false
end

-- 启用插件选项
yield("/tweaks enable EquipJobCommand true")

-- 主循环
tpOnceFlag = true  -- 初始TP标志
while Run_script do
    -- 获取当前月球信用点数量
    if IsAddonExists("WKSHud") then
        lunarCredits = Addons.GetAddon("WKSHud"):GetNode(1, 15, 17, 3).Text:gsub("[^%d]", "")
        lunarCredits = tonumber(lunarCredits)
    end
    currentCredits = Inventory.GetItemCount(CreditItemID)
    --yield("/echo [Cosmic Helper] 现在宇宙信用点数量:".. tostring(currentCredits))
    -- 执行各功能检查
    if JumpConfig then
        ShouldJump()  -- 遇阻跳跃检查
    end
    if ResearchConfig then
        tpOnce()  -- 初始TP执行
        ShouldRelic()  -- 肝武处理
    end
    if RetainerConfig ~= "N/A" then
        ShouldRetainer()  -- 雇员处理
    end
    CheckCredits()    --宇宙信用点处理
    if LimitConfig > 0 then
        ShouldCredit()  -- 信用点处理
    end
    if FailedConfig then
        ShouldReport()  -- 失败任务上报
    end
    if Ex2TimeConfig or Ex4TimeConfig then
        tpOnce()  -- 初始TP执行
        ShouldExTime()  -- EX+限时任务处理
    end
    if MoveConfig > 0 then
        ShouldMove()  -- 移动处理
    end
    if totalJobs > 0 then
        tpOnce()  -- 初始TP执行
        ShouldCycle()  -- 职业循环处理
    end
    
    -- 循环延迟
    sleep(loopDelay)
end
