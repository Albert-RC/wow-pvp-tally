-- PvP Tally: 繁體中文.

local _, ns = ...

if GetLocale() ~= "zhTW" then
	return
end
local L = ns.L

L.COL_PLAYER = "玩家"
L.COL_RACE = "種族"
L.COL_LEVEL = "等級"
L.COL_GUILD = "公會"
L.COL_KILLS = "擊殺"
L.COL_DEATHS = "死亡"
L.COL_FIRST = "首次交戰"
L.COL_NOTE = "備註"

L.D_RESULT = "結果"
L.D_DATE = "日期"
L.D_ZONE = "區域"
L.D_OPP = "對方等級"
L.D_MINE = "我的等級"

L.DATE_SHORT = "%y/%m/%d %H:%M"
L.DATE_LONG = "%Y/%m/%d %H:%M"

L.WIN = "勝利"
L.LOSS = "失敗"
L.EXTRA = "%d次擊殺和%d次死亡沒有詳細記錄（匯入的或較早的戰鬥）"
L.EMPTY = "尚未記錄任何野外PvP戰鬥。"
L.SEARCH = "搜尋"
L.SUMMARY = "玩家：%s   擊殺：%s   死亡：%s   K/D：%s"

L.IMPORT_BUTTON = "從Spy匯入"
L.IMPORT_TOOLTIP = "複製Spy為此角色記錄的擊殺和死亡。已在PvP Tally中的戰鬥不會重複計算。"
L.IMPORT_DONE = "已從Spy匯入：%d名玩家，%d場有詳細記錄的戰鬥。"
L.IMPORT_NOTHING = "Spy沒有可匯入的新資料。"
L.SPY_NOT_FOUND = "找不到此角色的Spy資料（Spy是否已安裝並啟用？）。"
L.EXPAND_ALL = "全部展開"
L.COLLAPSE_ALL = "全部摺疊"

L.NOTIFY_KILL = "你擊殺了%s。%s"
L.NOTIFY_GROUP_KILL = "你的隊伍擊殺了%s。%s"
L.NOTIFY_DEATH = "%s擊殺了你。%s"
L.SCORE = "（擊殺 %d / 死亡 %d）"

L.TT_FIRST = "首次交戰"
L.TT_LAST = "最近交戰"
L.TT_HINT = "點擊：查看戰鬥。右鍵點擊：刪除。"
L.TT_COORDS = "座標：%.1f, %.1f"

L.HOW_kill = "你的致命一擊"
L.HOW_group = "隊伍的致命一擊；你參與了戰鬥"
L.HOW_recap = "從死亡摘要中讀取的擊殺者"
L.HOW_targeting = "推測的擊殺者：唯一以你為目標的敵人"
L.HOW_spy = "從Spy匯入"
L.HOW_test = "為測試手動加入（/tally skull）"

L.DELETE_CONFIRM = "要從PvP Tally中刪除%s及其所有戰鬥嗎？"
L.RESET_CONFIRM = "要刪除PvP Tally為此角色記錄的所有戰鬥嗎？"
L.RESET_DONE = "此角色的所有資料已刪除。"

L.NOTE_ADD_HINT = "點擊為該玩家寫一條備註。"
L.NOTE_EDIT_HINT = "點擊：編輯備註。Shift + 右鍵點擊：刪除。"
L.TOOLTIP_NOTE = "PvP Tally備註："
L.NOTE_SAVE = "儲存"
L.NOTE_PLACEHOLDER = "寫下你想記住的關於這名玩家的事：怎麼打、在哪裡埋伏、和誰一起..."
L.NOTE_COUNT = "%d / %d"

L.SETTINGS_BUTTON = "選項"
L.SETTINGS_CHAT_HEADER = "聊天"
L.SETTINGS_NOTIFY_KILLS = "每次擊殺（你或你的隊伍）時顯示聊天訊息"
L.SETTINGS_NOTIFY_DEATHS = "每次死亡時顯示聊天訊息"
L.SETTINGS_SKULL_HEADER = "骷髏"
L.SETTINGS_NAMEPLATE_MARKS = "在你清單中每個玩家的名條上顯示骷髏"
L.SETTINGS_MARK_SIZE = "骷髏大小"
L.SETTINGS_MARK_SIZE_SMALL = "小"
L.SETTINGS_MARK_SIZE_MEDIUM = "中"
L.SETTINGS_MARK_SIZE_LARGE = "大"
L.SETTINGS_PORTRAIT_MARKS = "在目標和專注目標頭像上顯示骷髏"
L.SETTINGS_PORTRAIT_MARKS_NOTE = "以防其他插件替換了名條：覆蓋你清單中玩家的頭像。"
L.SETTINGS_NAMEPLATE_MARKS_NOTE = "僅顯示在遊戲顯示的名條上：請在遊戲設定中開啟敵方和友方名條。"
L.SETTINGS_IN_COMBAT = "戰鬥中無法開啟選項。"
L.SETTINGS_UNAVAILABLE = "此遊戲用戶端沒有插件選項面板。"

L.MINIMAP_LEFT = "左鍵點擊：開啟 / 關閉"
L.MINIMAP_RIGHT = "右鍵點擊：選項"
L.MINIMAP_DRAG = "拖曳：移動此按鈕"
L.MINIMAP_HIDDEN = "小地圖按鈕已隱藏。輸入 /tally minimap 可重新顯示。"

L.HELP = "指令：/tally（開啟），/tally settings（選項），/tally import（從Spy匯入），/tally minimap，/tally notify，/tally reset，/tally debug，/tally test，/tally test clear，/tally skull"
L.TEST_ADDED = "已新增%d名測試玩家（Test Reg以及每個種族的男性和女性）。使用 /tally test clear 刪除。"
L.TEST_MALE = "男"
L.TEST_FEMALE = "女"
L.TEST_REMOVED = "測試玩家已刪除。"
L.SKULL_ADDED = "已將%s加入為測試玩家：其名條現在會顯示骷髏。用/tally test clear刪除。"
L.SKULL_EXISTS = "%s已在你的清單中。"
L.SKULL_USAGE = "用法：/tally skull 名 姓（與遊戲中寫法一致），或選取一名玩家後輸入/tally skull。"
L.NOTIFY_ON = "擊殺和死亡的聊天訊息：開啟。"
L.NOTIFY_OFF = "擊殺和死亡的聊天訊息：關閉。"
