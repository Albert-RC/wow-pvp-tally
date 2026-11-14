local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("NoteEditor", function()
	local NoteEditor
	before_each(function()
		NoteEditor = Addon.LoadWith({ "UI/NoteEditor.lua" }).NoteEditor
	end)

	describe("keeping the cursor in sight", function()
		it("leaves the scroll alone while the cursor is in view", function()
			T.eq(NoteEditor.ScrollFor(0, 200, 50, 14), 0)
			T.eq(NoteEditor.ScrollFor(100, 200, 150, 14), 100)
		end)

		it("scrolls down just enough when the cursor goes below the box", function()
			T.eq(NoteEditor.ScrollFor(0, 200, 190, 14), 4)
			T.eq(NoteEditor.ScrollFor(20, 200, 300, 14), 114)
		end)

		it("scrolls up to the cursor when it goes above the box", function()
			T.eq(NoteEditor.ScrollFor(120, 200, 30, 14), 30)
			T.eq(NoteEditor.ScrollFor(120, 200, 0, 14), 0)
		end)
	end)

	it("needs Init before opening", function()
		T.raises(function() NoteEditor.Open("Kane-Mochivich") end, "Init")
	end)

	it("opens nothing for a player that is not in the list", function()
		local ns = Addon.LoadWith({ "UI/NoteEditor.lua" })
		ns.NoteEditor.Init({ store = ns.Store.New({}) })
		T.falsy(ns.NoteEditor.Open("Nobody-Here"))
		T.isNil(ns.NoteEditor.Frame())
		T.isNil(ns.NoteEditor.OpenKey())
	end)
end)
