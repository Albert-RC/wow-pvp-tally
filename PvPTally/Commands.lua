-- PvP Tally: slash commands and confirmation popups.

local _, ns = ...
local L, Util = ns.L, ns.Util

local Commands = {}
ns.Commands = Commands

local app -- see Init.lua

-- Popups ------------------------------------------------------------------------------------------

StaticPopupDialogs.PVPTALLY_DELETE_PLAYER = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, key) app.store:Delete(key) end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs.PVPTALLY_RESET = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		app.store:Reset()
		Util.Print(L.RESET_DONE)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	showAlert = true,
	preferredIndex = 3,
}

-- The edit box of a popup: a method on recent clients, a field on older ones.
local function PopupEditBox(popup)
	if type(popup) ~= "table" then
		return nil
	end
	if type(popup.GetEditBox) == "function" then
		return popup:GetEditBox()
	end
	return popup.editBox or popup.EditBox
end

-- data is the player key. Enter saves, Escape cancels; saving an empty text removes the note.
StaticPopupDialogs.PVPTALLY_EDIT_NOTE = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = ns.Store.NOTE_MAX_LENGTH,
	editBoxWidth = 320,
	OnAccept = function(popup, key)
		local editBox = PopupEditBox(popup)
		if editBox then
			app.store:SetNote(key, editBox:GetText())
		end
	end,
	EditBoxOnEnterPressed = function(editBox, key)
		app.store:SetNote(key, editBox:GetText())
		StaticPopup_Hide("PVPTALLY_EDIT_NOTE")
	end,
	EditBoxOnEscapePressed = function()
		StaticPopup_Hide("PVPTALLY_EDIT_NOTE")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function Commands.ConfirmDelete(key)
	local player = app.store:Get(key)
	StaticPopup_Show("PVPTALLY_DELETE_PLAYER", L.DELETE_CONFIRM:format(Util.ColoredName(key, player and player.class)), nil, key)
end

-- The popup empties its edit box when it shows, so the current note goes in afterwards.
function Commands.EditNote(key)
	local player = app.store:Get(key)
	if not player then
		return
	end
	local popup = StaticPopup_Show("PVPTALLY_EDIT_NOTE", L.NOTE_EDIT:format(Util.ColoredName(key, player.class)), nil, key)
	local editBox = PopupEditBox(popup)
	if editBox then
		editBox:SetText(player.note or "")
		editBox:HighlightText()
	end
end

function Commands.ConfirmReset()
	StaticPopup_Show("PVPTALLY_RESET", L.RESET_CONFIRM)
end

-- Commands ----------------------------------------------------------------------------------------

local function PrintDebug()
	local tracker = app.tracker
	Util.Print(("world PvP here: %s"):format(tostring(ns.WowApi.IsWorldPvP())))
	if tracker then
		Util.Print(("enemies cached: %d"):format(tracker.cacheCount))
		if tracker.lastKill then
			Util.Print(("last PARTY_KILL %ss ago: %s"):format(ns.WowApi.Time() - tracker.lastKill.when, tostring(tracker.lastKill.result)))
		end
		if tracker.lastDeath then
			Util.Print(("last death %ss ago: %s"):format(ns.WowApi.Time() - tracker.lastDeath.when, tostring(tracker.lastDeath.result)))
		end
	end
	if Util.lastError then
		Util.Print("last error: " .. Util.lastError)
	end
end

-- Command word -> action. Every action is a method of app (Init.lua) or of this module.
Commands.ACTIONS = {
	[""] = function() app.Toggle() end,
	show = function() app.Toggle() end,
	settings = function() app.OpenSettings() end,
	options = function() app.OpenSettings() end,
	config = function() app.OpenSettings() end,
	import = function() app.ImportFromSpy(false) end,
	minimap = function() app.ToggleMinimap() end,
	notify = function() app.ToggleNotify() end,
	reset = function() Commands.ConfirmReset() end,
	debug = PrintDebug,
	test = function() app.AddTestData() end,
	["test clear"] = function() app.ClearTestData() end,
}

-- Command word -> action that takes the rest of the line, as typed (names keep their case).
Commands.ACTIONS_WITH_ARGUMENT = {
	skull = function(argument) app.AddSkullTest(argument) end,
}

-- Runs a /tally command. Returns whether it was known (unknown ones print the help).
function Commands.Handle(message)
	local command = Util.Trim(message):lower():gsub("%s+", " ")
	local action = Commands.ACTIONS[command]
	if action then
		action()
		return true
	end
	local word, argument = Util.Trim(message):match("^(%S+)%s*(.-)$")
	local withArgument = word and Commands.ACTIONS_WITH_ARGUMENT[word:lower()]
	if withArgument then
		withArgument(argument)
		return true
	end
	Util.Print(L.HELP)
	return false
end

-- context: the app table (Init.lua).
function Commands.Register(context)
	app = context
	SLASH_PVPTALLY1 = "/tally"
	SLASH_PVPTALLY2 = "/pvptally"
	SlashCmdList.PVPTALLY = Commands.Handle
end

-- Addon compartment (the addons menu by the minimap), from the TOC.
function PvPTally_OnAddonCompartmentClick()
	if app then
		app.Toggle()
	end
end
