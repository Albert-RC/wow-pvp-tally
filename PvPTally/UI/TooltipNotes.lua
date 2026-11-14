-- PvP Tally: the note of a player in the list, on the game's own tooltip of that player
-- (the mouse over them in the world, or over their portrait).
--
-- Only a line is added at the end of Blizzard's tooltip; nothing of it is changed. Players
-- without a note, or not in the list, get nothing.

local _, ns = ...
local L, Util, ListModel = ns.L, ns.Util, ns.ListModel

local TooltipNotes = {}
TooltipNotes.__index = TooltipNotes
ns.TooltipNotes = TooltipNotes

local GOLD = { 1, 0.82, 0 }

-- Pure: the line for a player record of the store, or nil for none.
function TooltipNotes.LineFor(player)
	if not ListModel.HasNote(player) then
		return nil
	end
	return L.TOOLTIP_NOTE:format(Util.ColorText(player.note, 1, 1, 1))
end

-- options:
--   playerKey(unit)   the store key of the player behind a unit token, or nil
--   lookup(key)       the player record of the store, or nil when not in the list
function TooltipNotes.New(options)
	assert(type(options) == "table", "options expected")
	for _, name in ipairs({ "playerKey", "lookup" }) do
		assert(type(options[name]) == "function", name .. " function expected")
	end
	return setmetatable({ playerKey = options.playerKey, lookup = options.lookup }, TooltipNotes)
end

-- Adds the note line to a tooltip that the game just filled for a unit.
function TooltipNotes:Decorate(tooltip, unit)
	if type(tooltip) ~= "table" or not unit then
		return false
	end
	local key = self.playerKey(unit)
	local line = TooltipNotes.LineFor(key and self.lookup(key))
	if not line then
		return false
	end
	tooltip:AddLine(line, GOLD[1], GOLD[2], GOLD[3], true)
	tooltip:Show() -- fits the tooltip to the new line
	return true
end
