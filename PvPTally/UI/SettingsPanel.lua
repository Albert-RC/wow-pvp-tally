-- PvP Tally: the options panel, in the game's own Options > AddOns window (Blizzard's
-- Settings API, as other Forever addons use it).
--
-- Sections:
--   Chat  a checkbox per kind of chat message: kills (yours or your group's), deaths
--   Spy   import what Spy recorded (only enabled when Spy's saved data is loaded)
--
-- The panel only shows controls; the actions are the app's (Init.lua).

local _, ns = ...
local L = ns.L

local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local DESCRIPTION_WIDTH = 560
local CHECK_INDENT = 4 -- a checkbox's box has a margin: shift it left to line up its art

local category
local canvas
local app -- { IsNotifying(kind), SetNotify(kind, enabled), IsSpyAvailable(), ImportFromSpy(silent) }

-- The chat checkboxes, in order: the notification kind each one switches.
local NOTIFY_CHECKS = {
	{ kind = "kills", label = "SETTINGS_NOTIFY_KILLS" },
	{ kind = "deaths", label = "SETTINGS_NOTIFY_DEATHS" },
}

-- Whether this client has the Settings API for addon panels.
function SettingsPanel.IsSupported()
	return type(Settings) == "table"
		and type(Settings.RegisterCanvasLayoutCategory) == "function"
		and type(Settings.RegisterAddOnCategory) == "function"
		and type(Settings.OpenToCategory) == "function"
end

-- Brings the controls up to date: settings changed by /tally notify, Spy enabled or
-- disabled since.
function SettingsPanel.Refresh()
	if not canvas then
		return
	end
	for _, check in ipairs(canvas.NotifyChecks) do
		check:SetChecked(app.IsNotifying(check.kind))
	end
	local available = app.IsSpyAvailable()
	canvas.ImportButton:SetEnabled(available)
	canvas.SpyMissing:SetShown(not available)
end

local function CreateChatSection(anchor)
	canvas.ChatHeader = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	canvas.ChatHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -24)
	canvas.ChatHeader:SetText(L.SETTINGS_CHAT_HEADER)

	canvas.NotifyChecks = {}
	local previous = canvas.ChatHeader
	for index, entry in ipairs(NOTIFY_CHECKS) do
		local check = CreateFrame("CheckButton", nil, canvas, "UICheckButtonTemplate")
		check:SetSize(26, 26)
		check:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", index == 1 and -CHECK_INDENT or 0, index == 1 and -6 or 0)
		check.kind = entry.kind
		local label = check.Text or check.text
		if label then
			label:SetFontObject("GameFontHighlight")
			label:SetText(L[entry.label])
		end
		check:SetScript("OnClick", function(self)
			app.SetNotify(self.kind, self:GetChecked() and true or false)
		end)
		canvas.NotifyChecks[index] = check
		previous = check
	end
	return previous
end

-- anchorX: how far right of the anchor the section starts (checkboxes sit 4 px left of
-- the section titles).
local function CreateSpySection(anchor, anchorX)
	canvas.SpyHeader = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	canvas.SpyHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchorX or 0, -24)
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

	local chatBottom = CreateChatSection(canvas.Title)
	CreateSpySection(chatBottom, CHECK_INDENT)

	canvas:SetScript("OnShow", SettingsPanel.Refresh)
	return canvas
end

-- Adds the panel to Options > AddOns. Returns whether it could.
-- context: { IsNotifying(kind), SetNotify(kind, enabled), IsSpyAvailable(), ImportFromSpy(silent) }
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
