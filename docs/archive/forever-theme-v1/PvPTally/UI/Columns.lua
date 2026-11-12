-- PvP Tally: the table columns and their widths. Pure layout math, no widgets.
--
-- Each theme has its own set of player columns (Themes: theme.columns). At the smallest
-- window the columns take their base widths, which add up to LIST_WIDTH; when the
-- window is wider, the extra width goes to the columns with a `grow` share.

local _, ns = ...
local L = ns.L

local Columns = {}
ns.Columns = Columns

Columns.LIST_WIDTH = 660   -- the list at the smallest window
Columns.DETAIL_INDENT = 24 -- fight rows start this far right of player rows

-- Player rows; they line up with the column headers. sortable = false: no sorting.
Columns.SETS = {
	classic = {
		{ key = "name",   label = L.COL_PLAYER, base = 220, grow = 0.5, justify = "LEFT" },
		{ key = "race",   label = L.COL_RACE,   base = 52,  justify = "CENTER" },
		{ key = "level",  label = L.COL_LEVEL,  base = 40,  justify = "CENTER" },
		{ key = "guild",  label = L.COL_GUILD,  base = 132, grow = 0.5, justify = "LEFT" },
		{ key = "kills",  label = L.COL_KILLS,  base = 56,  justify = "CENTER" },
		{ key = "deaths", label = L.COL_DEATHS, base = 56,  justify = "CENTER" },
		{ key = "first",  label = L.COL_FIRST,  base = 104, justify = "CENTER" },
	},
	-- Kills and deaths as one bar; the +/- on the right, like the Skills window.
	forever = {
		{ key = "name",   label = L.COL_PLAYER, base = 196, grow = 0.5, justify = "LEFT" },
		{ key = "race",   label = L.COL_RACE,   base = 52,  justify = "CENTER" },
		{ key = "level",  label = L.COL_LEVEL,  base = 40,  justify = "CENTER" },
		{ key = "guild",  label = L.COL_GUILD,  base = 128, grow = 0.5, justify = "LEFT" },
		{ key = "score",  label = L.COL_SCORE,  base = 112, justify = "CENTER" },
		{ key = "first",  label = L.COL_FIRST,  base = 104, justify = "CENTER" },
		{ key = "toggle", label = "",           base = 28,  justify = "CENTER", sortable = false },
	},
}
Columns.DEFAULT_SET = "classic"

-- Fight rows (inside an expanded player), the same in every theme.
Columns.DETAIL = {
	{ key = "result", label = L.D_RESULT, base = 96,  justify = "LEFT" },
	{ key = "date",   label = L.D_DATE,   base = 120, justify = "LEFT" },
	{ key = "zone",   label = L.D_ZONE,   base = 280, grow = 1, justify = "LEFT" },
	{ key = "opp",    label = L.D_OPP,    base = 70,  justify = "CENTER" },
	{ key = "mine",   label = L.D_MINE,   base = 70,  justify = "CENTER" },
}

-- Every player column key of every set, for rows that must be ready for any theme.
function Columns.AllPlayerColumns()
	local seen, all = {}, {}
	for _, set in pairs(Columns.SETS) do
		for _, column in ipairs(set) do
			if not seen[column.key] then
				seen[column.key] = true
				all[#all + 1] = column
			end
		end
	end
	table.sort(all, function(a, b) return a.key < b.key end)
	return all
end

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
		placed[index] = {
			key = column.key, label = column.label, justify = column.justify,
			sortable = column.sortable ~= false, width = column.base + share,
		}
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

-- The columns of a set (default: classic) for a list this wide (never narrower than
-- LIST_WIDTH): a new table { width, set, player = { columns..., [key] = column },
-- detail = { ... } } where each column has key, label, justify, sortable, width and x.
function Columns.Layout(listWidth, set)
	listWidth = math.max(Columns.LIST_WIDTH, math.floor(listWidth or 0))
	if not Columns.SETS[set] then
		set = Columns.DEFAULT_SET
	end
	return {
		width = listWidth,
		set = set,
		player = Place(Columns.SETS[set], 0, listWidth),
		detail = Place(Columns.DETAIL, Columns.DETAIL_INDENT, listWidth),
	}
end
