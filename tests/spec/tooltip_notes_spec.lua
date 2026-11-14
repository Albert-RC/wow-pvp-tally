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

	it("writes the note of a player, the note in white", function()
		local line = Notes.LineFor({ note = "Rogue" })
		T.contains(line, "PvP Tally note: ")
		T.contains(line, "|cffffffffRogue|r")
	end)

	it("has no line for players without a note or out of the list", function()
		T.isNil(Notes.LineFor({}))
		T.isNil(Notes.LineFor({ note = "" }))
		T.isNil(Notes.LineFor(nil))
	end)

	it("adds the line at the end of the tooltip of a player with a note", function()
		local frame = tooltip()
		frame:AddLine("Kane Mochivich")
		T.truthy(notes:Decorate(frame, "mouseover"))
		T.eq(#frame.__lines, 2)
		T.eq(frame.__lines[1], "Kane Mochivich", "Blizzard's lines are left alone")
		T.contains(frame.__lines[2], "Camps the flight master")
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
		T.contains(frame.__lines[1], "Healer")
	end)

	it("needs its collaborators", function()
		T.raises(function() Notes.New() end, "options")
		T.raises(function() Notes.New({ playerKey = function() end }) end, "lookup")
	end)
end)
