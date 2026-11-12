-- PvP Tally: the options panel, in the game's own Options > AddOns window (Blizzard's
-- Settings API, as other Forever addons use it).
--
-- Sections:
--   Spy   import what Spy recorded (only enabled when Spy's saved data is loaded)
--
-- The panel only shows controls; the actions are the app's (Init.lua).

local _, ns = ...
local L = ns.L

local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local DESCRIPTION_WIDTH = 560

local category
local canvas
local app -- { IsSpyAvailable(), ImportFromSpy(silent) }

-- Whether this client has the Settings API for addon panels.
function SettingsPanel.IsSupported()
	return type(Settings) == "table"
		and type(Settings.RegisterCanvasLayoutCategory) == "function"
		and type(Settings.RegisterAddOnCategory) == "function"
		and type(Settings.OpenToCategory) == "function"
end

-- Brings the controls up to date (Spy may have been enabled or disabled since).
function SettingsPanel.Refresh()
	if not canvas then
		return
	end
	local available = app.IsSpyAvailable()
	canvas.ImportButton:SetEnabled(available)
	canvas.SpyMissing:SetShown(not available)
end

local function CreateSpySection(anchor)
	canvas.SpyHeader = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	canvas.SpyHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -24)
	canvas.SpyHeader:SetText(L.SETTINGS_SPY_HEADER)

	canvas.SpyDescription = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	canvas.SpyDescription:SetPoint("TOPLEFT", canvas.SpyHeader, "BOTTOMLEFT", 0, -8)
	canvas.SpyDescription:SetWidth(DESCRIPTION_WIDTH)
	canvas.SpyDescription:SetJustifyH("LEFT")
	canvas.SpyDescription:SetText(L.IMPORT_TOOLTIP)

	canvas.ImportButton = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
	canvas.ImportButton:SetSize(160, 22)
	canvas.ImportButton:SetPoint("TOPLEFT", canvas.SpyDescription, "BOTTOMLEFT", 0, -10)
	canvas.ImportButton:SetText(L.IMPORT_BUTTON)
	canvas.ImportButton:SetScript("OnClick", function()
		app.ImportFromSpy(false)
		SettingsPanel.Refresh()
	end)

	canvas.SpyMissing = canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	canvas.SpyMissing:SetPoint("LEFT", canvas.ImportButton, "RIGHT", 10, 0)
	canvas.SpyMissing:SetText(L.SPY_NOT_FOUND)
end

local function CreateCanvas()
	canvas = CreateFrame("Frame")
	-- The Settings window calls these on its buttons; there is nothing to save or reset.
	canvas.OnCommit = function() end
	canvas.OnDefault = function() end
	canvas.OnRefresh = SettingsPanel.Refresh

	canvas.Title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	canvas.Title:SetPoint("TOPLEFT", 16, -16)
	canvas.Title:SetText(L.TITLE)

	CreateSpySection(canvas.Title)

	canvas:SetScript("OnShow", SettingsPanel.Refresh)
	return canvas
end

-- Adds the panel to Options > AddOns. Returns whether it could.
-- context: { IsSpyAvailable(), ImportFromSpy(silent) }
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
	SettingsPanel.Refresh()
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
