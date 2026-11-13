-- PvP Tally: the options panel, in the game's own Options > AddOns window (Blizzard's
-- Settings API, as other Forever addons use it).
--
-- Sections:
--   Chat        a checkbox per kind of chat message: kills (yours or your group's), deaths
--   Skull       a checkbox for the skull on the nameplates of players in the list, its
--               size (small, medium, large), and a checkbox for the skull over the
--               portrait of the target and focus (for when nameplate addons hide it)
--   Spy         import what Spy recorded (only enabled when Spy's saved data is loaded)
--
-- The panel only shows controls; the actions are the app's (Init.lua).

local _, ns = ...
local L = ns.L

local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

-- The names of the skull sizes, in the order of Settings.MARK_SIZES.
local MARK_SIZE_LABELS = { "SETTINGS_MARK_SIZE_SMALL", "SETTINGS_MARK_SIZE_MEDIUM", "SETTINGS_MARK_SIZE_LARGE" }

local DESCRIPTION_WIDTH = 560
local CHECK_INDENT = 4 -- a checkbox's box has a margin: shift it left to line up its art

local category
local canvas
local app -- see SettingsPanel.Register

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
	canvas.NameplateCheck:SetChecked(app.IsMarkingNameplates())
	canvas.PortraitCheck:SetChecked(app.IsMarkingPortraits())
	canvas.MarkSizeDropdown:GenerateMenu() -- shows the size chosen now
	local available = app.IsSpyAvailable()
	canvas.ImportButton:SetEnabled(available)
	canvas.SpyMissing:SetShown(not available)
end

-- A checkbox with its label, below anchor (x, y from the anchor's bottom left).
local function CreateCheck(anchor, x, y, text, onClick)
	local check = CreateFrame("CheckButton", nil, canvas, "UICheckButtonTemplate")
	check:SetSize(26, 26)
	check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
	local label = check.Text or check.text
	if label then
		label:SetFontObject("GameFontHighlight")
		label:SetText(text)
	end
	check:SetScript("OnClick", onClick)
	return check
end

local function CreateChatSection(anchor)
	canvas.ChatHeader = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	canvas.ChatHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -24)
	canvas.ChatHeader:SetText(L.SETTINGS_CHAT_HEADER)

	canvas.NotifyChecks = {}
	local previous = canvas.ChatHeader
	for index, entry in ipairs(NOTIFY_CHECKS) do
		local check = CreateCheck(previous, index == 1 and -CHECK_INDENT or 0, index == 1 and -6 or 0, L[entry.label], function(self)
			app.SetNotify(self.kind, self:GetChecked() and true or false)
		end)
		check.kind = entry.kind
		canvas.NotifyChecks[index] = check
		previous = check
	end
	return previous
end

-- anchorX: how far right of the anchor the section starts (checkboxes sit 4 px left of
-- the section titles).
local function CreateNameplateSection(anchor, anchorX)
	canvas.NameplateHeader = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	canvas.NameplateHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchorX or 0, -24)
	canvas.NameplateHeader:SetText(L.SETTINGS_SKULL_HEADER)

	canvas.NameplateCheck = CreateCheck(canvas.NameplateHeader, -CHECK_INDENT, -6, L.SETTINGS_NAMEPLATE_MARKS, function(self)
		app.SetNameplateMarks(self:GetChecked() and true or false)
	end)

	canvas.NameplateNote = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	canvas.NameplateNote:SetPoint("TOPLEFT", canvas.NameplateCheck, "BOTTOMLEFT", CHECK_INDENT, -2)
	canvas.NameplateNote:SetWidth(DESCRIPTION_WIDTH)
	canvas.NameplateNote:SetJustifyH("LEFT")
	canvas.NameplateNote:SetText(L.SETTINGS_NAMEPLATE_MARKS_NOTE)

	canvas.MarkSizeLabel = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	canvas.MarkSizeLabel:SetPoint("TOPLEFT", canvas.NameplateNote, "BOTTOMLEFT", 0, -14)
	canvas.MarkSizeLabel:SetText(L.SETTINGS_MARK_SIZE)

	-- Blizzard's dropdown (Menu API), as Syndicator and Baganator use it on Forever.
	local dropdown = CreateFrame("DropdownButton", nil, canvas, "WowStyle1DropdownTemplate")
	dropdown:SetWidth(140)
	dropdown:SetPoint("LEFT", canvas.MarkSizeLabel, "RIGHT", 12, 0)
	dropdown:SetupMenu(function(_, rootDescription)
		for index, size in ipairs(ns.Settings.MARK_SIZES) do
			rootDescription:CreateRadio(L[MARK_SIZE_LABELS[index]],
				function() return app.GetMarkSize() == size end,
				function() app.SetMarkSize(size) end)
		end
	end)
	canvas.MarkSizeDropdown = dropdown

	-- The checkbox lines up with the one above: label and dropdown sit CHECK_INDENT right of it.
	canvas.PortraitCheck = CreateCheck(canvas.MarkSizeLabel, -CHECK_INDENT, -14, L.SETTINGS_PORTRAIT_MARKS, function(self)
		app.SetPortraitMarks(self:GetChecked() and true or false)
	end)

	-- Checkbox labels do not wrap: the why goes in a note that does.
	canvas.PortraitNote = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	canvas.PortraitNote:SetPoint("TOPLEFT", canvas.PortraitCheck, "BOTTOMLEFT", CHECK_INDENT, -2)
	canvas.PortraitNote:SetWidth(DESCRIPTION_WIDTH)
	canvas.PortraitNote:SetJustifyH("LEFT")
	canvas.PortraitNote:SetText(L.SETTINGS_PORTRAIT_MARKS_NOTE)
	return canvas.PortraitNote
end

-- anchorX: as in CreateNameplateSection.
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
	local nameplateBottom = CreateNameplateSection(chatBottom, CHECK_INDENT)
	CreateSpySection(nameplateBottom)

	canvas:SetScript("OnShow", SettingsPanel.Refresh)
	return canvas
end

-- Adds the panel to Options > AddOns. Returns whether it could.
-- context: { IsNotifying(kind), SetNotify(kind, enabled), IsMarkingNameplates(),
--   SetNameplateMarks(enabled), GetMarkSize(), SetMarkSize(size), IsMarkingPortraits(),
--   SetPortraitMarks(enabled), IsSpyAvailable(), ImportFromSpy(silent) }
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
