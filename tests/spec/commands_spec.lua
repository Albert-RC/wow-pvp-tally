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

	it("prints the help for an unknown command", function()
		T.falsy(ns.Commands.Handle("dance"))
		T.contains(env.__chat[1], "/tally import")
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
