local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Store", function()
	local ns, Store, bus, store, fired
	local function kill(t, extra)
		local encounter = { t = t, r = Store.KILL }
		for key, value in pairs(extra or {}) do encounter[key] = value end
		return encounter
	end
	local function death(t)
		return { t = t, r = Store.DEATH }
	end

	before_each(function()
		ns = Addon.LoadWith({})
		Store = ns.Store
		bus = ns.Events.New()
		fired = {}
		bus:On(ns.Events.DATA_CHANGED, function() fired[#fired + 1] = "DATA_CHANGED" end)
		bus:On(ns.Events.ENCOUNTER_ADDED, function(key) fired[#fired + 1] = "ENCOUNTER_ADDED " .. key end)
		store = Store.New({}, bus)
	end)

	describe("migration", function()
		it("starts an empty table at the current schema", function()
			local data = Store.Migrate({})
			T.eq(data.version, Store.SCHEMA_VERSION)
			T.eq(data.players, {})
			T.eq(data.imports, {})
		end)

		it("upgrades schema 1: the Spy flag moves under imports", function()
			local data = Store.Migrate({ version = 1, spyImported = 1234, players = {} })
			T.eq(data.version, 2)
			T.isNil(data.spyImported)
			T.eq(data.imports.spy, 1234)
		end)

		it("treats data without a version as schema 1", function()
			local data = Store.Migrate({ spyImported = 99, players = {} })
			T.eq(data.imports.spy, 99)
		end)

		it("drops malformed players and repairs missing fields", function()
			local data = Store.Migrate({ version = 2, players = {
				good = { encounters = {} },
				broken = "nope",
				[7] = {},
				partial = { extraKills = "3" },
			} })
			T.isNil(data.players.broken)
			T.isNil(data.players[7])
			T.eq(data.players.partial.encounters, {})
			T.eq(data.players.partial.extraKills, 3)
			T.eq(data.players.partial.extraDeaths, 0)
		end)

		it("works on the saved table in place", function()
			local saved = {}
			local opened = Store.New(saved)
			T.truthy(opened.data == saved)
		end)
	end)

	describe("AddEncounter", function()
		it("creates the player and records the fight", function()
			local encounter, player = store:AddEncounter("Kane-Mochivich", kill(100), { class = "WARLOCK", level = 25 })
			T.eq(player.name, "Kane-Mochivich")
			T.eq(player.class, "WARLOCK")
			T.eq(player.level, 25)
			T.truthy(player.encounters[1] == encounter)
			T.eq(player.first, 100)
			T.eq(player.last, 100)
		end)

		it("announces the fight and the change", function()
			store:AddEncounter("Kane", kill(100))
			T.eq(fired, { "ENCOUNTER_ADDED Kane", "DATA_CHANGED" })
		end)

		it("stays quiet when silent", function()
			store:AddEncounter("Kane", kill(100), nil, { silent = true })
			T.eq(fired, {})
		end)

		it("keeps fights ordered by time and tracks first and last", function()
			store:AddEncounter("Kane", kill(300))
			store:AddEncounter("Kane", death(100))
			store:AddEncounter("Kane", kill(200))
			local player = store:Get("Kane")
			T.eq({ player.encounters[1].t, player.encounters[2].t, player.encounters[3].t }, { 100, 200, 300 })
			T.eq(player.first, 100)
			T.eq(player.last, 300)
		end)

		it("folds the oldest fights into the counts past the limit", function()
			for i = 1, Store.MAX_ENCOUNTERS + 3 do
				store:AddEncounter("Kane", (i <= 2) and death(i) or kill(i), nil, { silent = true })
			end
			local player = store:Get("Kane")
			T.eq(#player.encounters, Store.MAX_ENCOUNTERS)
			T.eq(player.extraDeaths, 2)
			T.eq(player.extraKills, 1)
			T.eq({ Store.Counts(player) }, { Store.MAX_ENCOUNTERS + 1, 2 })
		end)

		it("rejects bad input", function()
			T.raises(function() store:AddEncounter("", kill(1)) end, "player key")
			T.raises(function() store:AddEncounter("Kane", { t = 1, r = "X" }) end, "KILL or DEATH")
			T.raises(function() store:AddEncounter("Kane", { r = Store.KILL }) end, "time")
		end)
	end)

	describe("player info", function()
		it("never erases known values with missing ones", function()
			local player = { encounters = {} }
			Store.UpdateInfo(player, { class = "MAGE", guild = "A", level = 20, sex = 3 })
			Store.UpdateInfo(player, { class = "", guild = nil, level = -1, sex = 0 })
			T.eq(player.class, "MAGE")
			T.eq(player.guild, "A")
			T.eq(player.level, 20)
			T.eq(player.sex, 3)
		end)

		it("ignores fields it does not know", function()
			local player = { encounters = {} }
			Store.UpdateInfo(player, { key = "x", guid = "Player-1", hacked = true })
			T.isNil(player.key)
			T.isNil(player.guid)
			T.isNil(player.hacked)
		end)
	end)

	describe("counts", function()
		it("adds the fights without details", function()
			store:AddEncounter("Kane", kill(1))
			store:AddEncounter("Kane", death(2))
			local player = store:Get("Kane")
			player.extraKills, player.extraDeaths = 2, 1
			T.eq({ Store.DetailedCounts(player) }, { 1, 1 })
			T.eq({ Store.Counts(player) }, { 3, 2 })
		end)

		it("EnsureTotals only ever raises the totals", function()
			store:AddEncounter("Kane", kill(1))
			T.truthy(store:EnsureTotals("Kane", 4, 2))
			T.eq({ Store.Counts(store:Get("Kane")) }, { 4, 2 })
			T.falsy(store:EnsureTotals("Kane", 2, 0), "lower totals change nothing")
			T.eq({ Store.Counts(store:Get("Kane")) }, { 4, 2 })
		end)

		it("finds the same fight a few seconds apart", function()
			store:AddEncounter("Kane", kill(1000))
			local player = store:Get("Kane")
			T.truthy(Store.HasEncounterNear(player, Store.KILL, 1004))
			T.falsy(Store.HasEncounterNear(player, Store.DEATH, 1004))
			T.falsy(Store.HasEncounterNear(player, Store.KILL, 1000 + Store.SAME_FIGHT_WINDOW + 1))
		end)
	end)

	describe("deleting", function()
		it("deletes one player", function()
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			T.truthy(store:Delete("Kane"))
			T.isNil(store:Get("Kane"))
			T.falsy(store:Delete("Kane"))
			T.eq(fired, { "DATA_CHANGED" })
		end)

		it("deletes the players a predicate picks", function()
			store:AddEncounter("A", kill(1), nil, { silent = true })
			store:AddEncounter("B", kill(1), nil, { silent = true })
			store:Get("B").test = true
			T.eq(store:DeleteWhere(function(_, player) return player.test end), 1)
			T.notNil(store:Get("A"))
			T.isNil(store:Get("B"))
		end)

		it("resets players and imports", function()
			store:AddEncounter("A", kill(1), nil, { silent = true })
			store:MarkImported("spy", 5)
			store:Reset()
			T.isNil(store:Get("A"))
			T.falsy(store:IsImported("spy"))
		end)
	end)

	it("remembers imports", function()
		T.falsy(store:IsImported("spy"))
		store:MarkImported("spy", 123)
		T.truthy(store:IsImported("spy"))
	end)
end)
