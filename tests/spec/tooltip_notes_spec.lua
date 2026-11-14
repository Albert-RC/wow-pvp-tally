local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each
local Wow = require("wow")

describe("TooltipNotes", function()
	local ns, env, Notes, notes
	local players, keys
	before_each(function()
		ns, env = Addon.LoadWith({ "UI/ListModel.lua", "UI/TooltipNotes.lua" })
		Notes = ns.TooltipNotes
		players = { -- the list
			["Kane-Mochivich"] = { name = "Kane", note = "Camps the flight master" },
			["Ally-Nobody"] = { name = "Ally" },
		}
		keys = { mouseover = "Kane-Mochivich", target = "Ally-Nobody", focus = "Stranger-Out" }
		notes = Notes.New({
			playerKey = function(unit) return keys[unit] end,
			lookup = function(key) return players[key] end,
		})
	end)

	local function tooltip()
		local frame = Wow.NewFrame("GameTooltip", env)
		frame:SetOwner(env.UIParent)
		return frame
	end

	it("writes a gold title and the note in white, line by line", function()
		local lines = Notes.LinesFor({ note = "Rogue\nAlways in stealth" })
		T.eq(lines, {
			{ text = "PvP Tally note:", color = { 1, 0.82, 0 } },
			{ text = "Rogue", color = { 1, 1, 1 } },
			{ text = "Always in stealth", color = { 1, 1, 1 } },
		})
	end)

	it("shows only the beginning of a long note", function()
		local long = "1\n2\n3\n4\n5\n6"
		local lines = Notes.LinesFor({ note = long })
		T.eq(#lines, 1 + ns.ListModel.NOTE_PREVIEW_UNIT.lines)
		T.eq(lines[#lines].text, "4...")
	end)

	it("has no lines for players without a note or out of the list", function()
		T.isNil(Notes.LinesFor({}))
		T.isNil(Notes.LinesFor({ note = "" }))
		T.isNil(Notes.LinesFor(nil))
	end)

	it("adds the line at the end of the tooltip of a player with a note", function()
		local frame = tooltip()
		frame:AddLine("Kane Mochivich")
		T.truthy(notes:Decorate(frame, "mouseover"))
		T.eq(frame.__lines, { "Kane Mochivich", "PvP Tally note:", "Camps the flight master" }, "Blizzard's lines are left alone")
	end)

	it("adds nothing for anyone else", function()
		for _, unit in ipairs({ "target", "focus", "party1" }) do
			local frame = tooltip()
			T.falsy(notes:Decorate(frame, unit), unit)
			T.eq(frame.__lines, {}, unit)
		end
		T.falsy(notes:Decorate(tooltip(), nil), "no unit")
		T.falsy(notes:Decorate(nil, "mouseover"), "no tooltip")
	end)

	it("follows the list: a note written later shows next time", function()
		players["Ally-Nobody"].note = "Healer"
		local frame = tooltip()
		T.truthy(notes:Decorate(frame, "target"))
		T.eq(frame.__lines[2], "Healer")
	end)

	it("needs its collaborators", function()
		T.raises(function() Notes.New() end, "options")
		T.raises(function() Notes.New({ playerKey = function() end }) end, "lookup")
	end)
end)
