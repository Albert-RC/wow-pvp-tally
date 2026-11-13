-- PvP Tally: account-wide settings (PvPTallyDB): chat notifications, minimap button,
-- window position and size.

local _, ns = ...

local Settings = {}
ns.Settings = Settings

Settings.DEFAULT_MINIMAP_ANGLE = 3.8 -- lower left of the minimap

-- Chat notifications, one switch per kind of fight: "kills" and "deaths".
Settings.NOTIFY_KEYS = { kills = "notifyKills", deaths = "notifyDeaths" }

-- Options that existed once and were withdrawn; dropped from saved data.
-- theme: the Classic / Forever style picker (on hold, see docs/forever-theme.md).
-- notify: one switch for kills and deaths, split into notifyKills / notifyDeaths.
local DISCARDED = { "theme", "notify" }

-- Fills in what is missing or broken in the saved table and returns it (same table, so
-- the game keeps saving it).
function Settings.Init(saved)
	if type(saved) ~= "table" then
		saved = {}
	end
	-- The old single switch becomes the default of both new ones.
	local legacyNotify = saved.notify ~= false
	for _, key in ipairs(DISCARDED) do
		saved[key] = nil
	end
	for _, key in pairs(Settings.NOTIFY_KEYS) do
		if type(saved[key]) ~= "boolean" then
			saved[key] = legacyNotify
		end
	end
	if type(saved.minimap) ~= "table" then
		saved.minimap = {}
	end
	if not ns.Util.IsFiniteNumber(saved.minimap.angle) then
		saved.minimap.angle = Settings.DEFAULT_MINIMAP_ANGLE
	end
	saved.minimap.hide = saved.minimap.hide == true
	if saved.position ~= nil and type(saved.position) ~= "table" then
		saved.position = nil
	end
	if saved.size ~= nil and type(saved.size) ~= "table" then
		saved.size = nil
	end
	return saved
end

-- Whether chat notifications are on for a kind of fight ("kills" or "deaths").
function Settings.IsNotifying(saved, kind)
	local key = Settings.NOTIFY_KEYS[kind]
	return key ~= nil and saved[key] == true
end

-- Switches the chat notifications of one kind on or off.
function Settings.SetNotify(saved, kind, enabled)
	local key = Settings.NOTIFY_KEYS[kind]
	assert(key, "notification kind expected: kills or deaths")
	saved[key] = enabled == true
end

-- /tally notify: everything off when anything is on, everything on otherwise. Returns
-- whether the notifications are now on.
function Settings.ToggleAllNotify(saved)
	local enable = not (saved.notifyKills or saved.notifyDeaths)
	for kind in pairs(Settings.NOTIFY_KEYS) do
		Settings.SetNotify(saved, kind, enable)
	end
	return enable
end
