local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

local function total(columns, start)
	local sum = start or 0
	for _, column in ipairs(columns) do
		sum = sum + column.width
	end
	return sum
end

describe("Columns", function()
	local Columns
	before_each(function()
		Columns = Addon.LoadWith({ "UI/Columns.lua" }).Columns
	end)

	it("fills exactly the list width at the minimum size", function()
		local layout = Columns.Layout(Columns.LIST_WIDTH)
		T.eq(total(layout.player), Columns.LIST_WIDTH)
		T.eq(total(layout.detail, Columns.DETAIL_INDENT), Columns.LIST_WIDTH)
	end)

	it("never goes below the minimum width", function()
		local layout = Columns.Layout(100)
		T.eq(layout.width, Columns.LIST_WIDTH)
		T.eq(total(layout.player), Columns.LIST_WIDTH)
	end)

	it("gives extra width to the growing columns only", function()
		local layout = Columns.Layout(Columns.LIST_WIDTH + 301)
		T.eq(total(layout.player), Columns.LIST_WIDTH + 301)
		T.eq(layout.player.name.width + layout.player.guild.width, 220 + 132 + 301)
		T.eq(layout.player.kills.width, 56)
		T.eq(layout.detail.zone.width, 308 + 301)
		T.eq(layout.player.first.width, Columns.DATE_WIDTH, "the date column does not grow")
	end)

	it("leaves room for a whole date in the first fight column (it was cut at 104)", function()
		T.truthy(Columns.DATE_WIDTH >= 132)
		T.eq(Columns.Layout(Columns.LIST_WIDTH).player.first.width, Columns.DATE_WIDTH)
	end)

	it("adds the detail columns up to the list width too", function()
		local base = Columns.DETAIL_INDENT
		for _, column in ipairs(Columns.DETAIL) do base = base + column.base end
		T.eq(base, Columns.LIST_WIDTH)
	end)

	it("places columns one after another", function()
		local layout = Columns.Layout(900)
		local x = 0
		for _, column in ipairs(layout.player) do
			T.eq(column.x, x, column.key)
			x = x + column.width
		end
		T.eq(layout.detail[1].x, Columns.DETAIL_INDENT)
	end)

	it("ends with a note column the width of its button, that does not grow", function()
		local narrow = Columns.Layout(Columns.LIST_WIDTH)
		local wide = Columns.Layout(Columns.LIST_WIDTH + 301)
		T.eq(narrow.player[#narrow.player].key, "note")
		T.eq(narrow.player.note.width, 44)
		T.eq(wide.player.note.width, 44)
		T.eq(narrow.player.note.label, "Note")
	end)

	it("makes a new layout each time (rows compare layouts by identity)", function()
		T.falsy(Columns.Layout(700) == Columns.Layout(700))
	end)
end)
