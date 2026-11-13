local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Notifications", function()
	local ns, env, bus, store, settings
	before_each(function()
		ns, env = Addon.LoadWith({ "Features/Notifications.lua" })
		bus = ns.Events.New()
		store = ns.Store.New({}, bus)
		settings = { notifyKills = true, notifyDeaths = true }
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

	it("stays quiet when both kinds are switched off", function()
		settings.notifyKills, settings.notifyDeaths = false, false
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL })
		store:AddEncounter("Cabo-Trancas", { t = 2, r = ns.Store.DEATH })
		T.eq(#env.__chat, 0)
	end)

	it("leaves out kills, yours and your group's, when kill messages are off", function()
		settings.notifyKills = false
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL })
		store:AddEncounter("Cabo-Trancas", { t = 2, r = ns.Store.KILL, how = "group" })
		store:AddEncounter("Cabo-Trancas", { t = 3, r = ns.Store.DEATH })
		T.eq(#env.__chat, 1)
		T.contains(env.__chat[1], "killed you")
	end)

	it("leaves out deaths when death messages are off", function()
		settings.notifyDeaths = false
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.DEATH })
		store:AddEncounter("Cabo-Trancas", { t = 2, r = ns.Store.KILL })
		T.eq(#env.__chat, 1)
		T.contains(env.__chat[1], "You killed")
	end)

	it("stays quiet for imports", function()
		store:AddEncounter("Cabo-Trancas", { t = 1, r = ns.Store.KILL }, nil, { silent = true })
		T.eq(#env.__chat, 0)
	end)
end)
