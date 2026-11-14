local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Commands", function()
	local ns, env, calls, app
	before_each(function()
		ns, env = Addon.LoadWith({ "Game/WowApi.lua", "Commands.lua" })
		calls = {}
		local function record(name) return function() calls[#calls + 1] = name end end
		app = {
			store = ns.Store.New({}),
			Toggle = record("Toggle"),
			ImportFromSpy = record("ImportFromSpy"),
			OpenSettings = record("OpenSettings"),
			ToggleMinimap = record("ToggleMinimap"),
			ToggleNotify = record("ToggleNotify"),
			AddTestData = record("AddTestData"),
			ClearTestData = record("ClearTestData"),
			AddSkullTest = function(name) calls[#calls + 1] = "AddSkullTest:" .. name end,
		}
		ns.Commands.Register(app)
	end)

	it("registers /tally and /pvptally", function()
		T.eq(env.SLASH_PVPTALLY1, "/tally")
		T.eq(env.SLASH_PVPTALLY2, "/pvptally")
		T.truthy(env.SlashCmdList.PVPTALLY == ns.Commands.Handle)
	end)

	it("runs each command, ignoring case and extra spaces", function()
		for _, command in ipairs({ "", "show", "IMPORT", " minimap ", "notify", "test", "test   clear" }) do
			T.truthy(ns.Commands.Handle(command), command)
		end
		T.eq(calls, { "Toggle", "Toggle", "ImportFromSpy", "ToggleMinimap", "ToggleNotify", "AddTestData", "ClearTestData" })
	end)

	it("opens the options with settings, options or config", function()
		for _, command in ipairs({ "settings", "Options", "config" }) do
			T.truthy(ns.Commands.Handle(command), command)
		end
		T.eq(calls, { "OpenSettings", "OpenSettings", "OpenSettings" })
	end)

	it("asks before resetting", function()
		ns.Commands.Handle("reset")
		T.eq(env.__popups[1][1], "PVPTALLY_RESET")
		env.StaticPopupDialogs.PVPTALLY_RESET.OnAccept()
		T.contains(env.__chat[1], "deleted")
	end)

	it("asks before deleting a player and deletes on yes", function()
		app.store:AddEncounter("Kane-Mochivich", { t = 1, r = ns.Store.KILL }, nil, { silent = true })
		ns.Commands.ConfirmDelete("Kane-Mochivich")
		local popup = env.__popups[1]
		T.eq(popup[1], "PVPTALLY_DELETE_PLAYER")
		T.contains(popup[2], "Kane Mochivich")
		env.StaticPopupDialogs.PVPTALLY_DELETE_PLAYER.OnAccept(nil, popup[4])
		T.isNil(app.store:Get("Kane-Mochivich"))
	end)

	describe("note popup", function()
		local dialog
		before_each(function()
			dialog = env.StaticPopupDialogs.PVPTALLY_EDIT_NOTE
			app.store:AddEncounter("Kane-Mochivich", { t = 1, r = ns.Store.KILL }, nil, { silent = true })
		end)

		it("is a Blizzard popup with an edit box as long as a note", function()
			T.truthy(dialog.hasEditBox)
			T.eq({ dialog.button1, dialog.button2 }, { "Accept", "Cancel" }, "Blizzard's own words")
			T.eq(dialog.maxLetters, ns.Store.NOTE_MAX_LENGTH)
			T.truthy(dialog.hideOnEscape)
		end)

		it("opens with the player's name and their note, ready to change", function()
			app.store:SetNote("Kane-Mochivich", "Rogue")
			ns.Commands.EditNote("Kane-Mochivich")
			local shown = env.__popups[1]
			T.eq(shown[1], "PVPTALLY_EDIT_NOTE")
			T.contains(shown[2], "Note about ")
			T.contains(shown[2], "Kane Mochivich")
			T.eq(shown[4], "Kane-Mochivich")
			T.eq(env.__popup.EditBox:GetText(), "Rogue")
		end)

		it("opens empty for a player without a note", function()
			ns.Commands.EditNote("Kane-Mochivich")
			T.eq(env.__popup.EditBox:GetText(), "")
		end)

		it("does not open for a player that is not in the list", function()
			ns.Commands.EditNote("Nobody-Here")
			T.eq(env.__popups, {})
		end)

		it("saves with the button", function()
			ns.Commands.EditNote("Kane-Mochivich")
			local popup = env.__popup
			popup.EditBox:SetText("  Camps the flight master ")
			dialog.OnAccept(popup, popup.data)
			T.eq(app.store:Get("Kane-Mochivich").note, "Camps the flight master")
		end)

		it("saves with Enter and closes", function()
			ns.Commands.EditNote("Kane-Mochivich")
			local popup = env.__popup
			popup.EditBox:SetText("Healer")
			dialog.EditBoxOnEnterPressed(popup.EditBox, popup.data)
			T.eq(app.store:Get("Kane-Mochivich").note, "Healer")
			T.isNil(env.__popup)
		end)

		it("deletes the note when saved empty", function()
			app.store:SetNote("Kane-Mochivich", "Rogue")
			ns.Commands.EditNote("Kane-Mochivich")
			local popup = env.__popup
			popup.EditBox:SetText("")
			dialog.OnAccept(popup, popup.data)
			T.isNil(app.store:Get("Kane-Mochivich").note)
		end)

		it("closes with Escape without saving", function()
			app.store:SetNote("Kane-Mochivich", "Rogue")
			ns.Commands.EditNote("Kane-Mochivich")
			env.__popup.EditBox:SetText("changed")
			dialog.EditBoxOnEscapePressed(env.__popup.EditBox, env.__popup.data)
			T.isNil(env.__popup)
			T.eq(app.store:Get("Kane-Mochivich").note, "Rogue")
		end)

		it("finds the edit box on older clients too (a field, no method)", function()
			ns.Commands.EditNote("Kane-Mochivich")
			local popup = env.__popup
			popup.GetEditBox = nil
			popup.editBox = popup.EditBox
			popup.editBox:SetText("Old client")
			dialog.OnAccept(popup, popup.data)
			T.eq(app.store:Get("Kane-Mochivich").note, "Old client")
		end)
	end)

	it("passes the name after skull as typed, keeping its case", function()
		T.truthy(ns.Commands.Handle("skull Kane Mochivich"))
		T.truthy(ns.Commands.Handle("  SKULL   Cabo-Trancas  "))
		T.truthy(ns.Commands.Handle("skull"))
		T.eq(calls, { "AddSkullTest:Kane Mochivich", "AddSkullTest:Cabo-Trancas", "AddSkullTest:" })
	end)

	it("prints the help for an unknown command", function()
		T.falsy(ns.Commands.Handle("dance"))
		T.contains(env.__chat[1], "/tally import")
		T.contains(env.__chat[1], "/tally skull")
	end)

	it("prints diagnostics", function()
		app.tracker = { cacheCount = 3, lastKill = { when = 0, result = "kill: X" } }
		ns.Commands.Handle("debug")
		T.contains(table.concat(env.__chat, "\n"), "enemies cached: 3")
		T.contains(table.concat(env.__chat, "\n"), "kill: X")
	end)

	it("opens the window from the addon compartment", function()
		env.PvPTally_OnAddonCompartmentClick()
		T.eq(calls, { "Toggle" })
	end)
end)
