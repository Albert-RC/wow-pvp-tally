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
