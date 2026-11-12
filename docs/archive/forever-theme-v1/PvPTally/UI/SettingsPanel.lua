-- PvP Tally: the options panel, in the game's own Options > AddOns window (Blizzard's
-- Settings API, as other Forever addons use it).
--
-- Each option has its default and validation in Core/Settings.lua; the panel only shows
-- the controls and calls app.SetSetting, which announces the change on the bus.

local _, ns = ...
local L = ns.L

local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local category
local app -- { settings, SetSetting(key, value) }

-- Whether this client has the Settings API for addon panels.
function SettingsPanel.IsSupported()
	return type(Settings) == "table"
		and type(Settings.RegisterCanvasLayoutCategory) == "function"
		and type(Settings.RegisterAddOnCategory) == "function"
		and type(Settings.OpenToCategory) == "function"
end

-- The label of a style in the dropdown.
function SettingsPanel.ThemeLabel(theme)
	return rawget(L, "THEME_" .. theme:upper()) or theme
end

-- Fills the style dropdown: one radio entry per style, the current one selected.
function SettingsPanel.BuildThemeMenu(_, rootDescription)
	for _, theme in ipairs(ns.Settings.THEMES) do
		rootDescription:CreateRadio(SettingsPanel.ThemeLabel(theme),
			function(value) return app.settings.theme == value end,
			function(value) app.SetSetting("theme", value) end,
			theme)
	end
end

local function CreateCanvas()
	local canvas = CreateFrame("Frame")
	-- The Settings window calls these on its buttons; changes apply at once.
	canvas.OnCommit = function() end
	canvas.OnDefault = function() end
	canvas.OnRefresh = function() end

	canvas.Title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	canvas.Title:SetPoint("TOPLEFT", 16, -16)
	canvas.Title:SetText(L.TITLE)

	canvas.ThemeLabel = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	canvas.ThemeLabel:SetPoint("TOPLEFT", canvas.Title, "BOTTOMLEFT", 0, -24)
	canvas.ThemeLabel:SetText(L.THEME_LABEL)

	canvas.ThemeDropdown = CreateFrame("DropdownButton", nil, canvas, "WowStyle1DropdownTemplate")
	canvas.ThemeDropdown:SetWidth(200)
	canvas.ThemeDropdown:SetPoint("LEFT", canvas.ThemeLabel, "RIGHT", 16, 0)
	canvas.ThemeDropdown:SetupMenu(SettingsPanel.BuildThemeMenu)

	canvas.ThemeHint = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	canvas.ThemeHint:SetPoint("TOPLEFT", canvas.ThemeLabel, "BOTTOMLEFT", 0, -14)
	canvas.ThemeHint:SetJustifyH("LEFT")
	canvas.ThemeHint:SetText(L.THEME_HINT)
	return canvas
end

-- Adds the panel to Options > AddOns. Returns whether it could.
-- context: { settings, SetSetting(key, value) }
function SettingsPanel.Register(context)
	if category then
		return true
	end
	if not SettingsPanel.IsSupported() then
		return false
	end
	app = context
	category = Settings.RegisterCanvasLayoutCategory(CreateCanvas(), L.TITLE)
	Settings.RegisterAddOnCategory(category)
	return true
end

-- Opens the Options window on this panel. Returns whether it could. The caller checks
-- combat first: the Options window cannot open in combat.
function SettingsPanel.Open()
	if not category then
		return false
	end
	Settings.OpenToCategory(category:GetID())
	return true
end
