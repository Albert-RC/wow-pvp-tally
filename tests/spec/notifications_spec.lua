local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Notifications", function()
	local ns, env, bus, store, settings
	before_each(function()
		ns, env = Addon.LoadWith({ "Features/Notifications.lua" })
		bus = ns.Events.New()
		store = ns.Store.New({}, bus)
		settings = { notify = true }
		ns.Notifications.Attach(bus, settings)
	end)

	it("prints a kill with the running score", function()
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL }, { class = "PRIEST" })
		T.eq(#env.__chat, 1)
		T.contains(env.__chat[1], "You killed")
		T.contains(env.__chat[1], "Cabo Trancas")
		T.contains(env.__chat[1], "(Kills 1 / Deaths 0)")
	end)

	it("prints a group kill as the group's", function()
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL, how = "group" })
		T.contains(env.__chat[1], "Your group killed")
		T.contains(env.__chat[1], "(Kills 1 / Deaths 0)")
	end)

	it("prints a death", function()
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.DEATH })
		T.contains(env.__chat[1], "killed you")
		T.contains(env.__chat[1], "(Kills 0 / Deaths 1)")
	end)

	it("stays quiet when switched off", function()
		settings.notify = false
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL })
		T.eq(#env.__chat, 0)
	end)

	it("stays quiet for imports", function()
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL }, nil, { silent = true })
		T.eq(#env.__chat, 0)
	end)
end)
