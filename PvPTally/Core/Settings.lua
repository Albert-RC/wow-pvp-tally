-- PvP Tally: account-wide settings (PvPTallyDB): chat notifications, minimap button,
-- window position and size.

local _, ns = ...

local Settings = {}
ns.Settings = Settings

Settings.DEFAULT_MINIMAP_ANGLE = 3.8 -- lower left of the minimap

-- Options that existed once and were withdrawn; dropped from saved data.
-- theme: the Classic / Forever style picker (on hold, see docs/forever-theme.md).
local DISCARDED = { "theme" }

-- Fills in what is missing or broken in the saved table and returns it (same table, so
-- the game keeps saving it).
function Settings.Init(saved)
	if type(saved) ~= "table" then
		saved = {}
	end
	for _, key in ipairs(DISCARDED) do
		saved[key] = nil
	end
	if type(saved.notify) ~= "boolean" then
		saved.notify = true
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
