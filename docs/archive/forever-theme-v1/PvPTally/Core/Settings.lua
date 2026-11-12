-- PvP Tally: account-wide settings (PvPTallyDB): visual style, chat notifications,
-- minimap button, window position and size.
--
-- Options the user picks in Options > AddOns change through Settings.Set, which checks
-- the value and announces the change on the bus (SETTINGS_CHANGED), so the UI can follow.

local _, ns = ...

local Settings = {}
ns.Settings = Settings

Settings.DEFAULT_MINIMAP_ANGLE = 3.8 -- lower left of the minimap

-- Visual styles, in the order the options list them. "classic" is the original look;
-- each one is drawn as UI/Themes.lua describes.
Settings.THEMES = { "classic", "forever" }
Settings.DEFAULT_THEME = "classic"

local function IsTheme(value)
	for _, theme in ipairs(Settings.THEMES) do
		if value == theme then
			return true
		end
	end
	return false
end

-- The options Settings.Set accepts, with what a valid value is.
local VALIDATORS = {
	theme = IsTheme,
}

-- Fills in what is missing or broken in the saved table and returns it (same table, so
-- the game keeps saving it).
function Settings.Init(saved)
	if type(saved) ~= "table" then
		saved = {}
	end
	if type(saved.notify) ~= "boolean" then
		saved.notify = true
	end
	if not IsTheme(saved.theme) then
		saved.theme = Settings.DEFAULT_THEME
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

-- Changes an option. Returns whether it changed: an unknown option or an invalid value
-- is refused, and setting the current value again does nothing. bus is optional.
function Settings.Set(saved, key, value, bus)
	local valid = VALIDATORS[key]
	if not valid or not valid(value) or saved[key] == value then
		return false
	end
	saved[key] = value
	if bus then
		bus:Fire(ns.Events.SETTINGS_CHANGED, key, value)
	end
	return true
end
