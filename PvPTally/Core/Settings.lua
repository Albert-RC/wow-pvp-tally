-- PvP Tally: account-wide settings (PvPTallyDB): chat notifications, nameplate and
-- portrait skulls, minimap button, window position and size.

local _, ns = ...

local Settings = {}
ns.Settings = Settings

Settings.DEFAULT_MINIMAP_ANGLE = 3.8 -- lower left of the minimap

-- The sizes in pixels the nameplate skull can have (small, medium, large).
Settings.MARK_SIZES = { 22, 28, 36 }
Settings.MARK_SIZE_DEFAULT = 28

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
	if type(saved.nameplateMarks) ~= "boolean" then
		saved.nameplateMarks = true
	end
	if type(saved.portraitMarks) ~= "boolean" then
		saved.portraitMarks = true
	end
	saved.nameplateMarkSize = Settings.NearestMarkSize(saved.nameplateMarkSize)
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

-- Whether players in the list get a skull on their nameplate.
function Settings.IsMarkingNameplates(saved)
	return saved.nameplateMarks == true
end

function Settings.SetNameplateMarks(saved, enabled)
	saved.nameplateMarks = enabled == true
end

-- Whether players in the list get a skull over the portrait of the target and focus frames.
function Settings.IsMarkingPortraits(saved)
	return saved.portraitMarks == true
end

function Settings.SetPortraitMarks(saved, enabled)
	saved.portraitMarks = enabled == true
end

-- The skull size closest to size (a size saved while trying sizes out becomes the
-- nearest one offered); the default for anything that is not a number.
function Settings.NearestMarkSize(size)
	if not ns.Util.IsFiniteNumber(size) then
		return Settings.MARK_SIZE_DEFAULT
	end
	local best = Settings.MARK_SIZES[1]
	for _, offered in ipairs(Settings.MARK_SIZES) do
		if math.abs(offered - size) < math.abs(best - size) then
			best = offered
		end
	end
	return best
end

function Settings.MarkSize(saved)
	return saved.nameplateMarkSize
end

-- Sets the skull size (one of MARK_SIZES; anything else becomes the nearest). Returns
-- the size kept.
function Settings.SetMarkSize(saved, size)
	saved.nameplateMarkSize = Settings.NearestMarkSize(size)
	return saved.nameplateMarkSize
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
