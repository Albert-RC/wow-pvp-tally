local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

local LABELS = { male = "hombre", female = "mujer", Alliance = "Alianza", Horde = "Horda" }
local NAMES = { [1] = "Humano", [7] = "Gnomo", [95] = "Cielonato", [96] = "Cielonato" }

describe("TestData", function()
	local ns, Store, TestData, store
	before_each(function()
		ns = Addon.LoadWith({ "Features/TestData.lua" })
		Store, TestData = ns.Store, ns.TestData
		store = Store.New({})
	end)

	local function add()
		return TestData.Add(store, LABELS, function(id) return NAMES[id] end, 1800000000)
	end

	it("adds Test Reg and every race as a man and a woman", function()
		local count = add()
		T.eq(count, 1 + #ns.Races.LIST * 2)
		local main = store:Get(TestData.MAIN_KEY)
		T.eq(#main.encounters, 6)
		T.eq({ Store.Counts(main) }, { 6, 3 })
		T.notNil(store:Get("Test-Humano hombre"))
		T.notNil(store:Get("Test-Humano mujer"))
		T.eq(store:Get("Test-Humano mujer").sex, ns.Races.FEMALE)
	end)

	it("adds Skyborne on both sides, told apart by faction", function()
		add()
		T.eq(store:Get("Test-Cielonato hombre (Alianza)").faction, "Alliance")
		T.eq(store:Get("Test-Cielonato mujer (Horda)").faction, "Horde")
	end)

	it("uses the race token when the game has no name for it", function()
		add()
		T.notNil(store:Get("Test-Troll hombre"))
	end)

	it("replaces the test players instead of adding more", function()
		add()
		local count = 0
		for _ in store:Players() do count = count + 1 end
		add()
		local again = 0
		for _ in store:Players() do again = again + 1 end
		T.eq(again, count)
	end)

	it("clears only test players", function()
		store:AddEncounter("Real-Enemy", { t = 1, r = Store.KILL }, nil, { silent = true })
		add()
		TestData.Clear(store)
		local keys = {}
		for key in store:Players() do keys[#keys + 1] = key end
		T.eq(keys, { "Real-Enemy" })
	end)

	describe("/tally skull", function()
		it("turns what was typed into a player key", function()
			T.eq(TestData.KeyFromName("Kane Mochivich"), "Kane-Mochivich")
			T.eq(TestData.KeyFromName("  Kane   Mochivich "), "Kane-Mochivich")
			T.eq(TestData.KeyFromName("Cabo-Trancas"), "Cabo-Trancas")
			T.eq(TestData.KeyFromName("Solo"), "Solo")
			T.isNil(TestData.KeyFromName("   "))
			T.isNil(TestData.KeyFromName(nil))
		end)

		it("adds a test player with one kill here and now", function()
			local context = { t = 1800000000, zone = "Los Baldíos", subZone = "El Cruce", mapID = 1413, x = 0.5, y = 0.3, myLevel = 30 }
			T.truthy(TestData.AddPlayer(store, "Kane-Mochivich", { class = "WARLOCK", level = 25 }, context))
			local player = store:Get("Kane-Mochivich")
			T.truthy(player.test)
			T.eq(player.class, "WARLOCK")
			T.eq(player.encounters, { {
				t = 1800000000, r = Store.KILL, how = "test", zone = "Los Baldíos", subZone = "El Cruce",
				mapID = 1413, x = 0.5, y = 0.3, oppLevel = 25, myLevel = 30,
			} })
		end)

		it("works with only a name", function()
			T.truthy(TestData.AddPlayer(store, "Kane-Mochivich", nil, { t = 5 }))
			T.eq(#store:Get("Kane-Mochivich").encounters, 1)
		end)

		it("never touches a player already in the list", function()
			store:AddEncounter("Kane-Mochivich", { t = 1, r = Store.DEATH }, nil, { silent = true })
			T.falsy(TestData.AddPlayer(store, "Kane-Mochivich", nil, { t = 5 }))
			local player = store:Get("Kane-Mochivich")
			T.isNil(player.test)
			T.eq(#player.encounters, 1)
		end)

		it("is removed with the other test players", function()
			TestData.AddPlayer(store, "Kane-Mochivich", nil, { t = 5 })
			TestData.Clear(store)
			T.isNil(store:Get("Kane-Mochivich"))
		end)

		it("tells the window and the nameplates", function()
			local bus = ns.Events.New()
			local changes = 0
			bus:On(ns.Events.DATA_CHANGED, function() changes = changes + 1 end)
			TestData.AddPlayer(Store.New({}, bus), "Kane-Mochivich", nil, { t = 5 })
			T.eq(changes, 1)
		end)
	end)

	it("makes every fight valid and dated before now", function()
		add()
		for _, player in store:Players() do
			for _, encounter in ipairs(player.encounters) do
				T.truthy(encounter.t < 1800000000)
				T.truthy(encounter.r == Store.KILL or encounter.r == Store.DEATH)
			end
		end
	end)
end)
