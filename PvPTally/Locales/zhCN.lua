-- PvP Tally: 简体中文.

local _, ns = ...

if GetLocale() ~= "zhCN" then
	return
end
local L = ns.L

L.COL_PLAYER = "玩家"
L.COL_RACE = "种族"
L.COL_LEVEL = "等级"
L.COL_GUILD = "公会"
L.COL_KILLS = "击杀"
L.COL_DEATHS = "死亡"
L.COL_FIRST = "首次交战"

L.D_RESULT = "结果"
L.D_DATE = "日期"
L.D_ZONE = "区域"
L.D_OPP = "对方等级"
L.D_MINE = "我的等级"

L.DATE_SHORT = "%y/%m/%d %H:%M"
L.DATE_LONG = "%Y/%m/%d %H:%M"

L.WIN = "胜利"
L.LOSS = "失败"
L.EXTRA = "%d次击杀和%d次死亡没有详细记录（导入的或较早的战斗）"
L.EMPTY = "尚未记录任何野外PvP战斗。"
L.SEARCH = "搜索"
L.SUMMARY = "玩家：%s   击杀：%s   死亡：%s   K/D：%s"

L.IMPORT_BUTTON = "从Spy导入"
L.IMPORT_TOOLTIP = "复制Spy为此角色记录的击杀和死亡。已在PvP Tally中的战斗不会重复计算。"
L.IMPORT_DONE = "已从Spy导入：%d名玩家，%d场有详细记录的战斗。"
L.IMPORT_NOTHING = "Spy没有可导入的新数据。"
L.SPY_NOT_FOUND = "未找到此角色的Spy数据（Spy是否已安装并启用？）。"
L.EXPAND_ALL = "全部展开"
L.COLLAPSE_ALL = "全部折叠"

L.NOTIFY_KILL = "你击杀了%s。%s"
L.NOTIFY_GROUP_KILL = "你的队伍击杀了%s。%s"
L.NOTIFY_DEATH = "%s击杀了你。%s"
L.SCORE = "（击杀 %d / 死亡 %d）"

L.TT_FIRST = "首次交战"
L.TT_LAST = "最近交战"
L.TT_HINT = "点击：查看战斗。右键点击：删除。"
L.TT_COORDS = "坐标：%.1f, %.1f"

L.HOW_kill = "你的致命一击"
L.HOW_group = "队伍的致命一击；你参与了战斗"
L.HOW_recap = "从死亡摘要中读取的击杀者"
L.HOW_targeting = "推测的击杀者：唯一以你为目标的敌人"
L.HOW_spy = "从Spy导入"
L.HOW_test = "为测试手动添加（/tally skull）"

L.DELETE_CONFIRM = "要从PvP Tally中删除%s及其所有战斗吗？"
L.RESET_CONFIRM = "要删除PvP Tally为此角色记录的所有战斗吗？"
L.RESET_DONE = "此角色的所有数据已删除。"

L.SETTINGS_BUTTON = "选项"
L.SETTINGS_CHAT_HEADER = "聊天"
L.SETTINGS_NOTIFY_KILLS = "每次击杀（你或你的队伍）时显示聊天消息"
L.SETTINGS_NOTIFY_DEATHS = "每次死亡时显示聊天消息"
L.SETTINGS_SKULL_HEADER = "骷髅"
L.SETTINGS_NAMEPLATE_MARKS = "在你列表中每个玩家的姓名版上显示骷髅"
L.SETTINGS_MARK_SIZE = "骷髅大小"
L.SETTINGS_MARK_SIZE_SMALL = "小"
L.SETTINGS_MARK_SIZE_MEDIUM = "中"
L.SETTINGS_MARK_SIZE_LARGE = "大"
L.SETTINGS_PORTRAIT_MARKS = "在目标和焦点头像上显示骷髅"
L.SETTINGS_PORTRAIT_MARKS_NOTE = "以防其他插件替换了姓名版：覆盖你列表中玩家的头像。"
L.SETTINGS_NAMEPLATE_MARKS_NOTE = "仅显示在游戏显示的姓名版上：请在游戏设置中开启敌方和友方姓名版。"
L.SETTINGS_IN_COMBAT = "战斗中无法打开选项。"
L.SETTINGS_UNAVAILABLE = "此游戏客户端没有插件选项面板。"

L.MINIMAP_LEFT = "左键点击：打开 / 关闭"
L.MINIMAP_RIGHT = "右键点击：选项"
L.MINIMAP_DRAG = "拖动：移动此按钮"
L.MINIMAP_HIDDEN = "小地图按钮已隐藏。输入 /tally minimap 可重新显示。"

L.HELP = "命令：/tally（打开），/tally settings（选项），/tally import（从Spy导入），/tally minimap，/tally notify，/tally reset，/tally debug，/tally test，/tally test clear，/tally skull"
L.TEST_ADDED = "已添加%d名测试玩家（Test Reg以及每个种族的男性和女性）。使用 /tally test clear 删除。"
L.TEST_MALE = "男"
L.TEST_FEMALE = "女"
L.TEST_REMOVED = "测试玩家已删除。"
L.SKULL_ADDED = "已将%s添加为测试玩家：其姓名版现在会显示骷髅。用/tally test clear删除。"
L.SKULL_EXISTS = "%s已在你的列表中。"
L.SKULL_USAGE = "用法：/tally skull 名 姓（与游戏中写法一致），或选中一名玩家后输入/tally skull。"
L.NOTIFY_ON = "击杀和死亡的聊天消息：开启。"
L.NOTIFY_OFF = "击杀和死亡的聊天消息：关闭。"
