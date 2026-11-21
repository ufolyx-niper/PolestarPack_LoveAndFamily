local addon = ...
local pack, guideID = "love-and-family", "love-and-family/fordring"
if not Polestar.RegisterPack({
    addon = addon, id = pack, title = "爱与家庭", author = "Codex", version = "0.1.0",
    format = 11, license = "MIT", source = "WoW Forever. See README.md.",
}) then return end

-- Native guide schema uses nil for live map coordinates and "e" for Era.
local east, west = 1423, 1422
Polestar.RegisterMapFrames({era = {
    [west] = {c = 0, left = 416.667, right = -3883.333, top = 3366.667, bottom = 500},
}}, pack)
local zh = GetLocale() == "zhCN"
local function name(chinese, english) return zh and chinese or english end
local tirion = {1855, name("提里奥·弗丁", "Tirion Fordring"), east, 5.1, 35.4}
local artist = {11936, name("画家瑞弗蕾", "Artist Renfray"), west, 65.8, 75.4}
local myranda = {11872, name("巫女麦兰达", "Myranda the Hag"), west, 50.8, 77.9}
local taelan = {1842, name("大领主泰兰·弗丁", "Highlord Taelan Fordring"), west, 42, 14.8}
local father = {12126, name("提里奥·弗丁", "Lord Tirion Fordring"), west, 54, 24.5}

local stages = {{5542,5543,5544}, {5742}, {5781}, {5845}, {5846}, {5848}, {5861}, {5862}, {5944}}
local quests = {
    [5542] = {name("恶魔之犬", "Demon Dogs"), 56}, [5543] = {name("血染的天空", "Blood Tinged Skies"), 56},
    [5544] = {name("腐肉虫", "Carrion Grubbage"), 56}, [5742] = {name("救赎", "Redemption"), 56},
    [5781] = {name("遗忘的记忆", "Of Forgotten Memories"), 57}, [5845] = {name("失落的荣耀", "Of Lost Honor"), 58},
    [5846] = {name("爱与家庭", "Of Love and Family"), 58}, [5848] = {name("爱与家庭", "Of Love and Family"), 60},
    [5861] = {name("寻找麦兰达", "Find Myranda"), 60}, [5862] = {name("血色幻象", "Scarlet Subterfuge"), 60},
    [5944] = {name("在梦中", "In Dreams"), 60},
}

-- Siblings share prerequisites. Only a strictly later stage proves a pickup obsolete.
local following = {}
for index = #stages, 1, -1 do
    local stage = stages[index]
    for _, id in ipairs(stage) do
        quests[id].previous, quests[id].later = stages[index - 1], following
    end
    following = {unpack(following)}
    for _, id in ipairs(stage) do following[#following + 1] = id end
end

local function endpoint(verb, id, npc, note)
    return {t = verb, quest = id, title = quests[id][1], npc = npc[1], npcName = npc[2],
        map = npc[3], x = npc[4], y = npc[5], f = npc[3] == west and "e" or nil, note = note}
end
local function accept(id, npc, note)
    local goal = endpoint("accept", id, npc, note)
    goal.minLevel, goal.qlvl = 52, quests[id][2]
    goal.preAll, goal.closedBy = quests[id].previous, quests[id].later
    return goal
end
local function turnin(id, npc, note) return endpoint("turnin", id, npc, note) end
local function step(title, ...) return {title = title, goals = {...}} end
local function kill(id, oi, npc, target, count, x, y, note)
    return {t = "kill", quest = id, oi = oi, npc = npc, target = target, count = count,
        map = east, x = x, y = y, note = note}
end
local function collect(id, item, itemName, count, x, y, note)
    return {t = "collect", quest = id, oi = 1, item = item, itemName = itemName, count = count,
        map = east, x = x, y = y, note = note}
end
local meat = collect(5544, 13853, name("食腐虫肉块", "Slab of Carrion Worm Meat"), 15, 13.5, 64,
    "沿路杀腐肉虫，逐只拾取。北部的腐肉吞噬者也掉肉；组队时各看自己日志里的数量。")
meat.fromNpcs = {{npc = 8603, npcName = name("腐肉虫", "Carrion Grub")}}
local hammer = collect(5781, 14613, name("泰兰之锤", "Taelan's Hammer"), 1, 23.6, 73.8,
    "到墓室外的弗丁墓碑旁，先等队友到齐。点地上的一堆泥土引出伏兵，击败米库提奥·污血，从他身上拾取泰兰之锤。")
hammer.fromNpcs = {{npc = 11886, npcName = name("米库提奥·污血", "Mercutio Filthgorger")}}
local banner = collect(5845, 14625, name("失落荣耀的象征", "Symbol of Lost Honor"), 1, 62.5, 26.8,
    "去东瘟疫东北的北谷，从废墟旁下水，到湖底点沉没的旗帜，取回失落荣耀的象征。")
banner.object, banner.objName = 177264, name("失落荣耀的象征", "Symbol of Lost Honor")
local outside = "到东瘟疫西北的病木林，过桥进斯坦索姆正门，走血色区。组队时先确认有人能开血色堡垒内门，可带血色十字军钥匙。"
local inside = "进十字军广场，向西进血色堡垒。沿大厅到档案管理员加尔福德的房间，进屋看右墙，点画着双月的「未完成的油画」。全队各自拿到画，再烧档案。"
local painting = collect(5848, 14679, name("爱与家庭", "Of Love and Family"), 1, 26.5, 10.4, outside)
painting.object, painting.objName = 177287, name("未完成的油画", "Unfinished Painting")

local function updatePainting()
    local inStratholme = Polestar.Compat.GetInstanceMapID() == 329
    local note = inStratholme and inside or outside
    if painting.note == note then return end
    painting.note = note
    if inStratholme then
        painting.map, painting.x, painting.y, painting.f = nil, nil, nil, nil
    else
        painting.map, painting.x, painting.y, painting.f = east, 26.5, 10.4, nil
    end
    local engine = Polestar.Engine
    local active = engine and engine.GetGuide()
    if active and active.id == guideID then engine.RequestUpdate() end
end

local steps = {
    step("东瘟疫河畔 · 在提里奥的小屋接三项委托",
        accept(5542, tirion, "留三个任务栏空位。沿东、西瘟疫交界的索多里尔河往北，在东岸小屋找提里奥。"),
        accept(5543, tirion), accept(5544, tirion)),
    step("东瘟疫西南 · 幼犬、蝙蝠和虫肉一起做",
        kill(5542, 1, 8596, name("瘟疫幼犬", "Plaguehound Runt"), 20, 17.3, 56.4, "沿西南低地找幼犬，途中一起打瘟疫蝙蝠、捡虫肉。"),
        kill(5543, 1, 8600, name("瘟疫蝙蝠", "Plaguebat"), 30, 15, 58.8, "只打名字叫瘟疫蝙蝠的目标。"),
        meat),
    step("东瘟疫中部至北部 · 补齐另外两种犬",
        kill(5542, 2, 8597, name("瘟疫犬", "Plaguehound"), 20, 46.2, 51.8, "中部沿路找普通瘟疫犬，数量看自己的日志。"),
        kill(5542, 3, 8598, name("狂怒的瘟疫犬", "Frenzied Plaguehound"), 5, 43.1, 31.2, "继续北上找 57–58 级的狂怒的瘟疫犬。刚到 52 级可结伴，或稍后回来补。")),
    step("回河边小屋 · 交齐三项委托",
        turnin(5542, tirion), turnin(5543, tirion), turnin(5544, tirion)),
    step("河畔 · 坐下听提里奥讲往事", accept(5742, tirion),
        endpoint("complete", 5742, tirion, "在他身边坐下（/sit），再次交谈，逐项回应，直到日志显示可交。")),
    step("接受提里奥的请求 · 前往墓地", turnin(5742, tirion),
        accept(5781, tirion, "南边墓地的泥土会引出一队敌人，出发前可找队友帮忙。")),
    step("东瘟疫南部 · 在墓碑旁找回战锤", hammer),
    step("回小屋交锤 · 打听失落的战旗", turnin(5781, tirion), accept(5845, tirion)),
    step("北谷 · 潜到湖底取旗", banner),
    step("回小屋交旗 · 问起一家人的肖像", turnin(5845, tirion), accept(5846, tirion)),
    step("凯尔达隆 · 在岛上找画家，再接取画任务",
        turnin(5846, artist, "到西瘟疫达隆米尔湖，过桥上凯尔达隆岛，向左找城堡外的小屋。画家的幽灵就在屋里。"),
        accept(5848, artist, "画家会给第二个同名任务。每人确认日志要求取画后，再组斯坦索姆正门队。可以在这里暂停。")),
    step("斯坦索姆 · 从正门到血色堡垒取画", painting),
    step("回东瘟疫河畔 · 把画交给提里奥", turnin(5848, tirion), accept(5861, tirion, "带上他给的礼物，去西瘟疫南部找巫女麦兰达。")),
    step("悔恨岭 · 找巫女麦兰达并取得伪装",
        turnin(5861, myranda, "她站在通往乌瑟尔之墓的岔路树桩上。"),
        accept(5862, myranda, "接任务后再同她说话，请她施加血色伪装，看见伪装效果再出发。")),
    step("壁炉谷 · 把礼物带给泰兰",
        turnin(5862, taelan, "确认身上有血色伪装，沿路北上壁炉谷，进玛登霍尔德城堡上楼。途中避战；伪装消失就回麦兰达处补。让队友都交完礼物再开护送。"),
        accept(5944, taelan, "队友到齐、能接的人都准备好再触发。出城后会遇到精英，留在泰兰身旁。")),
    step("在梦中 · 跟随泰兰出城到路边哨塔",
        {t = "complete", quest = 5944, title = quests[5944][1],
            note = "让泰兰带路，沿途保护他。到塔前留在附近，看伊森利恩和提里奥的剧情；泰兰在剧情中倒下时继续等。只有日志明确显示失败，才放弃失败的护送，必要时找麦兰达补伪装，等泰兰回到城堡重接。"}),
    step("西瘟疫哨塔 · 向赶来的提里奥选奖",
        turnin(5944, father, "等父亲说完话，在哨塔前向他选五件奖励中的一件。重登后日志仍可交，就保留任务，在塔前找他；若他已离场，可等下一队护送经过再查看。")),
}

if Polestar.RegisterGuide({
    id = guideID, pack = pack, title = "爱与家庭 · 提里奥的完整任务链", category = "Miscellaneous",
    minLevel = 52, maxLevel = 60, zone = east, zoneName = "东瘟疫之地", version = 1,
    keywords = {"爱与家庭", "弗丁", "在梦中", "斯坦索姆", "Of Love and Family", "In Dreams", "Tirion"},
    why = "从河边小屋接起三项委托，找回战锤、旗帜和全家福，陪泰兰走完壁炉谷的最后一程。", steps = steps,
}) then
    Polestar.OnLogin(updatePainting)
    Polestar.RegisterEvent("PLAYER_ENTERING_WORLD", updatePainting)
    Polestar.RegisterEvent("ZONE_CHANGED_NEW_AREA", updatePainting)
end
