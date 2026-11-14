-- PvP Tally: the box to write the note of a player. A panel beside the main window with
-- an edit box of several lines that scrolls, a letter count, and Save / Cancel.
--
-- Built the way ForeverCore builds its report window on Forever: PortraitFrameTemplate,
-- an InsetFrameTemplate holding a ScrollFrameTemplate, and a multi-line EditBox as the
-- scroll child. The panel is a child of the main window, not a frame with a name of its
-- own (that would be a new global): Escape in the edit box cancels the note, and Escape
-- anywhere else closes the main window, the panel with it.

local _, ns = ...
local L, Util, Store = ns.L, ns.Util, ns.Store

local NoteEditor = {}
ns.NoteEditor = NoteEditor

NoteEditor.WIDTH = 360
NoteEditor.HEIGHT = 320
local ICON = "Interface\\Icons\\INV_Misc_Note_01"
local SOUND_CLICK = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856

local frame
local app -- { store }
local key -- the player whose note is open

-- The vertical scroll that keeps the cursor in sight: offset is the current scroll,
-- viewHeight what the box shows, cursorTop and cursorHeight where the cursor is, measured
-- down from the top of the text. Pure.
function NoteEditor.ScrollFor(offset, viewHeight, cursorTop, cursorHeight)
	if cursorTop < offset then
		return cursorTop
	end
	local bottom = cursorTop + cursorHeight - viewHeight
	if bottom > offset then
		return bottom
	end
	return offset
end

-- Widgets ------------------------------------------------------------------------------------------

local function Refresh()
	local editBox = frame.EditBox
	local text = editBox:GetText() or ""
	frame.Placeholder:SetShown(text == "")
	frame.Count:SetText(L.NOTE_COUNT:format(editBox:GetNumLetters(), Store.NOTE_MAX_LENGTH))
end

local function Save()
	if key then
		app.store:SetNote(key, frame.EditBox:GetText())
	end
	PlaySound(SOUND_CLICK)
	frame:Hide()
end

local function Cancel()
	frame:Hide()
end

local function CreateEditBox(inset)
	local scroll = CreateFrame("ScrollFrame", nil, inset, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", -28, 8)

	local editBox = CreateFrame("EditBox", nil, scroll)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetWidth(NoteEditor.WIDTH - 66)
	editBox:SetMaxLetters(Store.NOTE_MAX_LENGTH)
	editBox:SetScript("OnTextChanged", Refresh)
	editBox:SetScript("OnEscapePressed", Cancel)
	editBox:SetScript("OnCursorChanged", function(_, _, y, _, cursorHeight)
		scroll:SetVerticalScroll(NoteEditor.ScrollFor(scroll:GetVerticalScroll(), scroll:GetHeight(), -y, cursorHeight))
	end)
	scroll:SetScrollChild(editBox)
	-- A click on the empty part of the box below the text starts writing too.
	scroll:EnableMouse(true)
	scroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)

	frame.Placeholder = editBox:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	frame.Placeholder:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, 0)
	frame.Placeholder:SetWidth(NoteEditor.WIDTH - 66)
	frame.Placeholder:SetJustifyH("LEFT")
	frame.Placeholder:SetText(L.NOTE_PLACEHOLDER)

	frame.Scroll, frame.EditBox = scroll, editBox
end

local function CreateButtons()
	frame.CancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.CancelButton:SetSize(96, 22)
	frame.CancelButton:SetPoint("BOTTOMRIGHT", -8, 6)
	frame.CancelButton:SetText(CANCEL)
	frame.CancelButton:SetScript("OnClick", Cancel)

	frame.SaveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.SaveButton:SetSize(96, 22)
	frame.SaveButton:SetPoint("RIGHT", frame.CancelButton, "LEFT", -4, 0)
	frame.SaveButton:SetText(L.NOTE_SAVE)
	frame.SaveButton:SetScript("OnClick", Save)

	frame.Count = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	frame.Count:SetPoint("BOTTOMLEFT", 16, 12)
end

local function Create(parent)
	frame = CreateFrame("Frame", nil, parent, "PortraitFrameTemplate")
	frame:SetSize(NoteEditor.WIDTH, NoteEditor.HEIGHT)
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:Hide()
	if frame.SetTitle then
		frame:SetTitle(L.COL_NOTE)
	elseif frame.TitleText then
		frame.TitleText:SetText(L.COL_NOTE)
	end
	if frame.SetPortraitToAsset then
		frame:SetPortraitToAsset(ICON)
	end

	frame.PlayerName = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.PlayerName:SetPoint("TOPLEFT", 66, -36)
	frame.PlayerName:SetPoint("RIGHT", -16, 0)
	frame.PlayerName:SetJustifyH("LEFT")
	frame.PlayerName:SetWordWrap(false)

	local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
	inset:SetPoint("TOPLEFT", 10, -62)
	inset:SetPoint("BOTTOMRIGHT", -10, 34)
	CreateEditBox(inset)
	CreateButtons()

	frame:SetScript("OnHide", function()
		frame.EditBox:ClearFocus()
		key = nil
	end)
end

-- Public ---------------------------------------------------------------------------------------------

-- context: { store }
function NoteEditor.Init(context)
	app = context
end

-- Opens the note of a player in the list, beside `parent` (the main window). Opening
-- another player's note drops what was written and not saved. Returns whether it opened.
function NoteEditor.Open(playerKey, parent)
	assert(app, "NoteEditor.Init must run first")
	local player = app.store:Get(playerKey)
	if not player then
		return false
	end
	if not frame then
		Create(parent or UIParent)
	end
	frame:ClearAllPoints()
	if parent then
		frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)
	else
		frame:SetPoint("CENTER")
	end
	key = playerKey
	frame.PlayerName:SetText(Util.ColoredName(playerKey, player.class))
	frame.EditBox:SetText(player.note or "")
	Refresh()
	frame:Show()
	frame.EditBox:SetFocus()
	return true
end

-- Closes the panel if it shows the note of `playerKey` (any note when nil), unsaved.
function NoteEditor.Close(playerKey)
	if frame and frame:IsShown() and (playerKey == nil or playerKey == key) then
		frame:Hide()
	end
end

-- The player whose note is open, or nil.
function NoteEditor.OpenKey()
	return frame and frame:IsShown() and key or nil
end

-- The panel, once made (for the tests).
function NoteEditor.Frame()
	return frame
end
