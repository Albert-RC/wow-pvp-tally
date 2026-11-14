-- PvP Tally: the table columns and their widths. Pure layout math, no widgets.
--
-- At the smallest window the columns take their base widths, which add up to
-- LIST_WIDTH. When the window is wider, the extra width goes to the columns with a
-- `grow` share (the ones with long text).

local _, ns = ...
local L = ns.L

local Columns = {}
ns.Columns = Columns

Columns.LIST_WIDTH = 732   -- the list at the smallest window
Columns.DETAIL_INDENT = 24 -- fight rows start this far right of player rows
-- The "First fight" date ("11/11/26 20:22") in the row font. At 104 it was cut in game,
-- and the column does not grow with the window.
Columns.DATE_WIDTH = 132

-- Player rows; they line up with the column headers.
Columns.PLAYER = {
	{ key = "name",   label = L.COL_PLAYER, base = 220, grow = 0.5, justify = "LEFT" },
	{ key = "race",   label = L.COL_RACE,   base = 52,  justify = "CENTER" },
	{ key = "level",  label = L.COL_LEVEL,  base = 40,  justify = "CENTER" },
	{ key = "guild",  label = L.COL_GUILD,  base = 132, grow = 0.5, justify = "LEFT" },
	{ key = "kills",  label = L.COL_KILLS,  base = 56,  justify = "CENTER" },
	{ key = "deaths", label = L.COL_DEATHS, base = 56,  justify = "CENTER" },
	{ key = "first",  label = L.COL_FIRST,  base = Columns.DATE_WIDTH, justify = "CENTER" },
	{ key = "note",   label = L.COL_NOTE,   base = 44,  justify = "CENTER" }, -- an icon button
}

-- Fight rows, inside an expanded player.
Columns.DETAIL = {
	{ key = "result", label = L.D_RESULT, base = 116, justify = "LEFT" },
	{ key = "date",   label = L.D_DATE,   base = 144, justify = "LEFT" },
	{ key = "zone",   label = L.D_ZONE,   base = 308, grow = 1, justify = "LEFT" },
	{ key = "opp",    label = L.D_OPP,    base = 70,  justify = "CENTER" },
	{ key = "mine",   label = L.D_MINE,   base = 70,  justify = "CENTER" },
}

local function Place(definitions, start, listWidth)
	local used = start
	for _, column in ipairs(definitions) do
		used = used + column.base
	end
	local extra = math.max(0, listWidth - used)
	local placed, given, firstGrowing = {}, 0, nil
	for index, column in ipairs(definitions) do
		local share = column.grow and math.floor(extra * column.grow) or 0
		given = given + share
		placed[index] = { key = column.key, label = column.label, justify = column.justify, width = column.base + share }
		if column.grow and not firstGrowing then
			firstGrowing = placed[index]
		end
	end
	if firstGrowing then
		firstGrowing.width = firstGrowing.width + (extra - given) -- rounding leftovers
	end
	local x = start
	for _, column in ipairs(placed) do
		column.x = x
		placed[column.key] = column
		x = x + column.width
	end
	return placed
end

-- The columns for a list this wide (never narrower than LIST_WIDTH): a new table
-- { width, player = { columns..., [key] = column }, detail = { ... } } where each column
-- has key, label, justify, width and x.
function Columns.Layout(listWidth)
	listWidth = math.max(Columns.LIST_WIDTH, math.floor(listWidth or 0))
	return {
		width = listWidth,
		player = Place(Columns.PLAYER, 0, listWidth),
		detail = Place(Columns.DETAIL, Columns.DETAIL_INDENT, listWidth),
	}
end
