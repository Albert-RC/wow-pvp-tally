-- PvP Tally: English texts, the base every other locale translates.
--
-- This file loads first and creates ns.L. Each other file in Locales\ only runs on its
-- own client language and overwrites the keys it translates; a key it leaves out shows
-- in English, and a key nobody defines shows as its own name.
--
-- Format strings (%s, %d, %.1f) must keep the order of the English text: Lua's format
-- has no positional arguments. tests/spec/locales_spec.lua checks it.

local _, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

L.TITLE = "PvP Tally"

L.COL_PLAYER = "Player"
L.COL_RACE = "Race"
L.COL_LEVEL = "Lvl"
L.COL_GUILD = "Guild"
L.COL_KILLS = "Kills"
L.COL_DEATHS = "Deaths"
L.COL_FIRST = "First fight"

L.D_RESULT = "Result"
L.D_DATE = "Date"
L.D_ZONE = "Zone"
L.D_OPP = "Their lvl"
L.D_MINE = "My lvl"

-- os.date formats for fight times: short in the list, long in tooltips and details.
L.DATE_SHORT = "%m/%d/%y %H:%M"
L.DATE_LONG = "%m/%d/%Y %H:%M"

L.WIN = "Victory"
L.LOSS = "Defeat"
L.UNKNOWN_LEVEL = "??"
L.EXTRA = "%d kills and %d deaths without details (imported or older fights)"
L.EMPTY = "No world PvP fights recorded yet."
L.SEARCH = "Search"
L.SUMMARY = "Players: %s   Kills: %s   Deaths: %s   K/D: %s"

L.IMPORT_BUTTON = "Import from Spy"
L.IMPORT_TOOLTIP = "Copies the kills and deaths Spy recorded for this character. Fights already in PvP Tally are not counted twice."
L.IMPORT_DONE = "Imported from Spy: %d players, %d fights with details."
L.IMPORT_NOTHING = "Spy had nothing new to import."
L.SPY_NOT_FOUND = "Spy data not found for this character (is Spy installed and enabled?)."
L.EXPAND_ALL = "Expand all"
L.COLLAPSE_ALL = "Collapse all"

L.NOTIFY_KILL = "You killed %s. %s"
L.NOTIFY_GROUP_KILL = "Your group killed %s. %s"
L.NOTIFY_DEATH = "%s killed you. %s"
L.SCORE = "(Kills %d / Deaths %d)"

L.TT_FIRST = "First fight"
L.TT_LAST = "Last fight"
L.TT_HINT = "Click: show fights. Right-click: delete."
L.TT_COORDS = "Coords: %.1f, %.1f"

L.HOW_kill = "Your killing blow"
L.HOW_group = "Killing blow by your group; you took part in the fight"
L.HOW_recap = "Killer read from the death recap"
L.HOW_targeting = "Killer guessed: the only enemy who had you targeted"
L.HOW_spy = "Imported from Spy"

L.DELETE_CONFIRM = "Delete %s and all their fights from PvP Tally?"
L.RESET_CONFIRM = "Delete ALL fights recorded by PvP Tally for this character?"
L.RESET_DONE = "All data for this character was deleted."

L.SETTINGS_BUTTON = "Options"
L.SETTINGS_SPY_HEADER = "Spy"
L.SETTINGS_CHAT_HEADER = "Chat"
L.SETTINGS_NOTIFY_KILLS = "Show a chat message for every kill (yours or your group's)"
L.SETTINGS_NOTIFY_DEATHS = "Show a chat message for every death"
L.SETTINGS_IN_COMBAT = "The options cannot be opened in combat."
L.SETTINGS_UNAVAILABLE = "This game client has no options panel for addons."

L.MINIMAP_LEFT = "Left-click: open / close"
L.MINIMAP_RIGHT = "Right-click: options"
L.MINIMAP_DRAG = "Drag: move this button"
L.MINIMAP_HIDDEN = "Minimap button hidden. Type /tally minimap to show it again."

L.HELP = "Commands: /tally (open), /tally settings (options), /tally import (import from Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "%d test players added (Test Reg and every race, male and female; Skyborne on both sides). Remove them with /tally test clear."
L.TEST_MALE = "male"
L.TEST_FEMALE = "female"
L.TEST_REMOVED = "Test players removed."
L.NOTIFY_ON = "Chat messages for kills and deaths: on."
L.NOTIFY_OFF = "Chat messages for kills and deaths: off."

-- British English: same texts, day before month.
if GetLocale() == "enGB" then
	L.DATE_SHORT = "%d/%m/%y %H:%M"
	L.DATE_LONG = "%d/%m/%Y %H:%M"
end
