-- PvP Tally: the note of a player in the list, on the game's own tooltip of that player
-- (the mouse over them in the world, or over their portrait).
--
-- Only lines are added at the end of Blizzard's tooltip; nothing of it is changed. Players
-- without a note, or not in the list, get nothing. A long note shows only its beginning
-- (ListModel.NOTE_PREVIEW_UNIT): the whole of it is in the list.

local _, ns = ...
local L, ListModel = ns.L, ns.ListModel

local TooltipNotes = {}
TooltipNotes.__index = TooltipNotes
ns.TooltipNotes = TooltipNotes

local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }

-- Pure: the lines for a player record of the store, { text, color } each, or nil for none.
function TooltipNotes.LinesFor(player)
	if not ListModel.HasNote(player) then
		return nil
	end
	local lines = { { text = L.TOOLTIP_NOTE, color = GOLD } }
	for _, line in ipairs(ListModel.NoteLines(player.note, ListModel.NOTE_PREVIEW_UNIT)) do
		lines[#lines + 1] = { text = line, color = WHITE }
	end
	return lines
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

-- Adds the note to a tooltip that the game just filled for a unit.
function TooltipNotes:Decorate(tooltip, unit)
	if type(tooltip) ~= "table" or not unit then
		return false
	end
	local key = self.playerKey(unit)
	local lines = TooltipNotes.LinesFor(key and self.lookup(key))
	if not lines then
		return false
	end
	for _, line in ipairs(lines) do
		tooltip:AddLine(line.text, line.color[1], line.color[2], line.color[3], true)
	end
	tooltip:Show() -- fits the tooltip to the new lines
	return true
end
