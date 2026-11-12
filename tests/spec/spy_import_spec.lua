local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

-- Shaped like the SpyPerCharDB found on the user's character.
local function SpyData()
	return {
		PlayerData = {
			["Cabo-Trancas"] = { class = "PRIEST", race = "Gnoma", guild = "Legion de Ventormenta", faction = "Alliance",
				level = 23, isGuess = false, isEnemy = true, zone = "Los Baldíos", time = 1794424974, wins = 1 },
			["Kane-Mochivich"] = { class = "WARLOCK", race = "Humano", level = 23, isGuess = false, isEnemy = true, time = 1794424951 },
			["Old-Foe"] = { class = "ROGUE", isEnemy = true, time = 1700000000, wins = 2, loses = 3 },
			["Friend-Ly"] = { class = "MAGE", isEnemy = false, wins = 5 },
		},
		Encounters = {
			{ t = 1794424972, n = "Cabo-Trancas", r = "W", k = "kill", c = "PRIEST", l = 23, g = "Legion de Ventormenta", m = 1413, x = 0.4627, y = 0.7388 },
			{ t = 1794425000, n = "Kane-Mochivich", r = "W", k = "group" },
			{ t = 1794425100, n = "Kane-Mochivich", r = "P", k = "probable" },
			{ t = 1794425200, n = "Kane-Mochivich", r = "L", k = "recap", l = 24 },
			{ t = "broken", n = "Kane-Mochivich", r = "L" },
			"not even a table",
		},
	}
end

local function mapName(mapID)
	return mapID == 1413 and "Los Baldíos" or nil
end

describe("SpyImport", function()
	local ns, env, Store, SpyImport, store, changes
	before_each(function()
		ns, env = Addon.LoadWith({ "Features/SpyImport.lua" })
		Store, SpyImport = ns.Store, ns.SpyImport
		local bus = ns.Events.New()
		changes = 0
		bus:On(ns.Events.DATA_CHANGED, function() changes = changes + 1 end)
		store = Store.New({}, bus)
	end)

	it("imports own kills and losses with their details", function()
		local result = SpyImport.Run(store, SpyData(), mapName, 5)
		local cabo = store:Get("Cabo-Trancas")
		T.eq(#cabo.encounters, 1)
		T.eq(cabo.encounters[1], { t = 1794424972, r = Store.KILL, zone = "Los Baldíos", mapID = 1413, x = 0.4627, y = 0.7388, oppLevel = 23, how = "spy" })
		T.eq(cabo.race, "Gnoma")
		T.eq(cabo.guild, "Legion de Ventormenta")
		T.eq(cabo.first, 1794424972)

		local kane = store:Get("Kane-Mochivich")
		T.eq(#kane.encounters, 1, "group kills, probable wins and broken entries are skipped")
		T.eq(kane.encounters[1].r, Store.DEATH)
		T.eq(result.fights, 2)
	end)

	it("adds counts Spy has without details", function()
		SpyImport.Run(store, SpyData(), mapName, 5)
		local foe = store:Get("Old-Foe")
		T.eq({ Store.Counts(foe) }, { 2, 3 })
		T.eq(#foe.encounters, 0)
		T.eq(foe.last, 1700000000)
		T.eq({ Store.Counts(store:Get("Cabo-Trancas")) }, { 1, 0 }, "the detailed kill is not counted twice")
	end)

	it("leaves out players Spy marked as friendly", function()
		SpyImport.Run(store, SpyData(), mapName, 5)
		T.isNil(store:Get("Friend-Ly"))
	end)

	it("reports what it did and marks the import", function()
		local result = SpyImport.Run(store, SpyData(), mapName, 5)
		T.eq(result, { found = true, players = 3, fights = 2 })
		T.truthy(store:IsImported(SpyImport.SOURCE))
		T.eq(changes, 1, "one change event for the whole import")
	end)

	it("is safe to run again", function()
		SpyImport.Run(store, SpyData(), mapName, 5)
		local again = SpyImport.Run(store, SpyData(), mapName, 6)
		T.eq(again, { found = true, players = 0, fights = 0 })
		T.eq(#store:Get("Cabo-Trancas").encounters, 1)
		T.eq({ Store.Counts(store:Get("Old-Foe")) }, { 2, 3 })
	end)

	it("skips a fight PvP Tally already recorded itself", function()
		store:AddEncounter("Cabo-Trancas", { t = 1794424974, r = Store.KILL, how = "kill" }, nil, { silent = true })
		SpyImport.Run(store, SpyData(), mapName, 5)
		T.eq(#store:Get("Cabo-Trancas").encounters, 1)
		T.eq(store:Get("Cabo-Trancas").encounters[1].how, "kill")
	end)

	it("finds nothing without Spy data", function()
		T.eq(SpyImport.Run(store, nil, mapName, 5), { found = false, players = 0, fights = 0 })
		T.eq(SpyImport.Run(store, { PlayerData = "x" }, mapName, 5).found, false)
		T.falsy(store:IsImported(SpyImport.SOURCE))
	end)

	it("handles Spy data from versions without Encounters", function()
		local data = SpyData()
		data.Encounters = nil
		local result = SpyImport.Run(store, data, mapName, 5)
		T.eq(result.fights, 0)
		T.eq({ Store.Counts(store:Get("Cabo-Trancas")) }, { 1, 0 })
	end)

	describe("reading Spy's saved variables", function()
		it("is unavailable when Spy is not loaded", function()
			T.isNil(SpyImport.ReadSavedData())
			T.falsy(SpyImport.IsAvailable())
		end)

		it("reads SpyPerCharDB when the game loaded it", function()
			env.SpyPerCharDB = SpyData()
			T.truthy(SpyImport.IsAvailable())
		end)

		it("ignores a SpyPerCharDB of an unexpected shape", function()
			env.SpyPerCharDB = { version = "1.1" }
			T.falsy(SpyImport.IsAvailable())
		end)
	end)
end)
