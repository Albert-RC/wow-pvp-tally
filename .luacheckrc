-- luacheck configuration. Run from the repository root:  luacheck .

std = "lua51"
max_line_length = false
codes = true

-- docs/archive holds shelved code for reference; the game never loads it.
exclude_files = { ".luacheckrc", "docs/archive/**" }

-- The addon -------------------------------------------------------------------------------

files["PvPTally"] = {
	-- Globals the addon owns.
	globals = {
		"PvPTallyDB",
		"PvPTallyCharDB",
		"SLASH_PVPTALLY1",
		"SLASH_PVPTALLY2",
		"PvPTally_OnAddonCompartmentClick",
		"StaticPopupDialogs",
		"SlashCmdList",
	},
	-- The WoW API it reads.
	read_globals = {
		-- Lua extensions of the WoW client
		"date", "time", "tinsert", "wipe",
		-- Secret values (modern client)
		"issecretvalue", "issecrettable",
		-- Frames and UI
		"CreateFrame", "UIParent", "Minimap", "GameTooltip", "UISpecialFrames", "DEFAULT_CHAT_FRAME",
		"StaticPopup_Show", "PlaySound", "SOUNDKIT", "GetCursorPosition", "Settings", "InCombatLockdown",
		"CreateDataProvider", "CreateScrollBoxListLinearView", "ScrollUtil",
		-- Constants and tables
		"RAID_CLASS_COLORS", "CLASS_ICON_TCOORDS", "LOCALIZED_CLASS_NAMES_MALE",
		"LEVEL", "YES", "NO", "UNKNOWNOBJECT", "FACTION_ALLIANCE", "FACTION_HORDE",
		-- Game state
		"GetLocale", "GetTime", "GetZoneText", "GetSubZoneText", "IsInInstance", "GetGuildInfo",
		"GetPlayerInfoByGUID", "GetNumGroupMembers", "IsInRaid", "UnitClass", "UnitExists", "UnitFactionGroup", "UnitGUID", "UnitIsEnemy",
		"UnitIsPlayer", "UnitIsUnit", "UnitLevel", "UnitName", "UnitRace", "UnitSex",
		"C_CreatureInfo", "C_DeathRecap", "C_Map", "C_Texture", "C_Timer",
	},
}

-- The tests ---------------------------------------------------------------------------------

files["tests"] = {
	std = "lua51",
	-- The fake WoW environment sets fields on its own tables freely.
	ignore = { "212" }, -- unused arguments in fakes
}
