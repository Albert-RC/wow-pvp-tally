local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each
local FakeGame = require("fake_game")

local KANE = { guid = "Player-1-AAA", class = "WARLOCK", race = "Humano", raceFile = "Human", sex = 2, level = 25, guild = "Selecció Natural", faction = "Alliance" }
local OTTO = { guid = "Player-1-BBB", class = "PRIEST", level = 21 }

describe("Tracker", function()
	local ns, Store, game, store, tracker, added
	before_each(function()
		ns = Addon.LoadWith({ "Game/Tracker.lua" })
		Store = ns.Store
		local bus = ns.Events.New()
		added = {}
		bus:On(ns.Events.ENCOUNTER_ADDED, function(key, encounter) added[#added + 1] = { key = key, encounter = encounter } end)
		store = Store.New({}, bus)
		game = FakeGame.New()
		tracker = ns.Tracker.New(game, store)
	end)

	describe("seeing enemies", function()
		it("caches an enemy by GUID", function()
			game.SetUnit("target", "Kane-Mochivich", KANE)
			tracker:HandleEvent("PLAYER_TARGET_CHANGED")
			T.eq(tracker.cache[KANE.guid].key, "Kane-Mochivich")
			T.eq(tracker.guidByKey["Kane-Mochivich"], KANE.guid)
		end)

		it("keeps the last known level when the unit shows a skull", function()
			game.SetUnit("target", "Kane-Mochivich", KANE)
			tracker:Scan("target")
			game.SetUnit("target", "Kane-Mochivich", { guid = KANE.guid })
			local _, info = tracker:Scan("target")
			T.eq(info.level, 25)
		end)

		it("notes who has us targeted", function()
			game.SetUnit("nameplate3", "Kane-Mochivich", KANE, true)
			tracker:HandleEvent("NAME_PLATE_UNIT_ADDED", "nameplate3")
			T.eq(tracker.targetingMe["Kane-Mochivich"], game.now)
		end)

		it("rescans visible nameplates and forgets removed ones", function()
			tracker:HandleEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
			tracker:HandleEvent("NAME_PLATE_UNIT_REMOVED", "nameplate1")
			T.isNil(tracker.nameplates.nameplate1)
		end)

		it("updates a known enemy's record", function()
			store:AddEncounter("Kane-Mochivich", { t = 1, r = Store.KILL }, { guild = "Old" }, { silent = true })
			game.SetUnit("target", "Kane-Mochivich", KANE)
			tracker:ScanVisible()
			T.eq(store:Get("Kane-Mochivich").guild, "Selecció Natural")
		end)

		it("does nothing outside the open world", function()
			game.world = false
			game.SetUnit("nameplate1", "Kane-Mochivich", KANE, true)
			tracker:HandleEvent("NAME_PLATE_UNIT_ADDED", "nameplate1")
			T.isNil(tracker.targetingMe["Kane-Mochivich"])
		end)

		it("starts over when the cache is full", function()
			for i = 1, ns.Tracker.CACHE_LIMIT do
				tracker:Remember("Player-" .. i, { key = "P" .. i })
			end
			tracker:Remember("Player-new", { key = "New" })
			T.eq(tracker.cacheCount, 1)
			T.eq(tracker.guidByKey.New, "Player-new")
		end)
	end)

	describe("kills", function()
		before_each(function()
			game.SetUnit("target", "Kane-Mochivich", KANE)
			tracker:Scan("target")
		end)

		it("records our killing blow with its context", function()
			tracker:HandleEvent("PARTY_KILL", game.playerGUID, KANE.guid)
			local player = store:Get("Kane-Mochivich")
			T.eq(#player.encounters, 1)
			local encounter = player.encounters[1]
			T.eq(encounter.r, Store.KILL)
			T.eq(encounter.zone, "Los Baldíos")
			T.eq(encounter.subZone, "El Cruce")
			T.eq(encounter.oppLevel, 25)
			T.eq(encounter.myLevel, 30)
			T.eq(encounter.how, "kill")
			T.eq(player.raceFile, "Human")
			T.eq(#added, 1)
		end)

		it("records our pet's killing blow", function()
			game.petGUID = "Pet-1-PET"
			tracker:OnPartyKill("Pet-1-PET", KANE.guid)
			T.eq(#store:Get("Kane-Mochivich").encounters, 1)
		end)

		it("ignores someone else's kill", function()
			tracker:OnPartyKill("Player-1-OTHER", KANE.guid)
			T.isNil(store:Get("Kane-Mochivich"))
			T.eq(tracker.lastKill.result, "not our kill")
		end)

		it("counts a double PARTY_KILL once", function()
			tracker:OnPartyKill(game.playerGUID, KANE.guid)
			tracker:OnPartyKill(game.playerGUID, KANE.guid)
			T.eq(#store:Get("Kane-Mochivich").encounters, 1)
			T.eq(tracker.lastKill.result, "duplicate")
		end)

		it("counts a new kill of the same player later on", function()
			tracker:OnPartyKill(game.playerGUID, KANE.guid)
			game.now = game.now + ns.Tracker.KILL_DEDUP + 1
			tracker:OnPartyKill(game.playerGUID, KANE.guid)
			T.eq(#store:Get("Kane-Mochivich").encounters, 2)
		end)

		it("ignores kills outside the open world", function()
			game.world = false
			tracker:OnPartyKill(game.playerGUID, KANE.guid)
			T.isNil(store:Get("Kane-Mochivich"))
		end)

		it("ignores creatures and hidden GUIDs", function()
			tracker:OnPartyKill(game.playerGUID, "Creature-0-123")
			tracker:OnPartyKill(nil, KANE.guid)
			T.isNil(store:Get("Kane-Mochivich"))
		end)

		it("names an unseen victim from his GUID, matching a known surname", function()
			store:AddEncounter("Otto-Hofmann", { t = 1, r = Store.KILL }, nil, { silent = true })
			game.byGUID[OTTO.guid] = { name = "Otto", realm = "", class = "PRIEST" }
			tracker:OnPartyKill(game.playerGUID, OTTO.guid)
			T.eq(#store:Get("Otto-Hofmann").encounters, 2)
		end)
	end)

	describe("KnownKey", function()
		before_each(function()
			store:AddEncounter("Otto-Hofmann", { t = 1, r = Store.KILL }, nil, { silent = true })
		end)

		it("matches the full key, a spaced name and a unique first name", function()
			T.eq(tracker:KnownKey("Otto", "Hofmann"), "Otto-Hofmann")
			T.eq(tracker:KnownKey("Otto Hofmann"), "Otto-Hofmann")
			T.eq(tracker:KnownKey("Otto"), "Otto-Hofmann")
		end)

		it("does not guess between two players with the same first name", function()
			store:AddEncounter("Otto-Klein", { t = 1, r = Store.KILL }, nil, { silent = true })
			T.isNil(tracker:KnownKey("Otto"))
		end)

		it("returns nil for a stranger", function()
			T.isNil(tracker:KnownKey("Nobody"))
			T.isNil(tracker:KnownKey(nil))
		end)
	end)

	describe("deaths", function()
		before_each(function()
			game.SetUnit("target", "Kane-Mochivich", KANE, true)
			tracker:ScanAndNote("target")
		end)

		it("takes the killer from the death recap", function()
			game.recap = { id = 1, timestamp = game.epoch, sourceGUID = KANE.guid, sourceName = "Kane Mochivich" }
			tracker:HandleEvent("PLAYER_DEAD")
			game.RunTimers()
			local encounter = store:Get("Kane-Mochivich").encounters[1]
			T.eq(encounter.r, Store.DEATH)
			T.eq(encounter.how, "recap")
			T.eq(encounter.oppLevel, 25)
		end)

		it("keeps where we died, even if the recap is read later", function()
			game.recap = { id = 1, sourceGUID = KANE.guid }
			tracker:OnPlayerDead()
			game.context.zone = "Somewhere after releasing"
			game.RunTimers()
			T.eq(store:Get("Kane-Mochivich").encounters[1].zone, "Los Baldíos")
		end)

		it("blames the only enemy targeting us when the recap says nothing", function()
			game.recapWhy = "unavailable"
			tracker:OnPlayerDead()
			game.RunTimers()
			T.eq(store:Get("Kane-Mochivich").encounters[1].how, "targeting")
		end)

		it("blames nobody when several enemies had us targeted", function()
			game.SetUnit("focus", "Otto-Hofmann", OTTO, true)
			tracker:ScanAndNote("focus")
			tracker:OnPlayerDead()
			game.RunTimers()
			T.isNil(store:Get("Kane-Mochivich"))
			T.contains(tracker.lastDeath.result, "several enemies")
		end)

		it("forgets targeting older than the window", function()
			game.now = game.now + ns.Tracker.TARGETING_WINDOW + 1
			tracker:OnPlayerDead()
			game.RunTimers()
			T.isNil(store:Get("Kane-Mochivich"))
		end)

		it("records nothing when a creature killed us", function()
			game.recap = { id = 1, sourceGUID = "Creature-0-1", sourceName = "Wolf" }
			tracker:OnPlayerDead()
			game.RunTimers()
			T.isNil(store:Get("Kane-Mochivich"))
			T.eq(tracker.lastDeath.result, "no player")
		end)

		it("waits while the recap still shows the previous death", function()
			game.recap = { id = 1, sourceGUID = KANE.guid }
			tracker:OnPlayerDead()
			game.RunTimers()
			-- Second death: the recap is not updated until the first retry.
			tracker:OnPlayerDead()
			local first = table.remove(game.timers, 1)
			first.callback()
			T.eq(#store:Get("Kane-Mochivich").encounters, 1, "stale recap: no record yet")
			game.recap = { id = 2, sourceGUID = KANE.guid }
			game.RunTimers()
			T.eq(#store:Get("Kane-Mochivich").encounters, 2)
		end)

		it("ignores a recap left over from before a reload", function()
			game.recap = { id = 9, timestamp = game.epoch - 3600, sourceGUID = "Creature-0-1" }
			game.SetUnit("target", "Kane-Mochivich", KANE, true)
			tracker:OnPlayerDead()
			game.RunTimers()
			T.eq(store:Get("Kane-Mochivich").encounters[1].how, "targeting")
		end)

		it("does nothing in instances", function()
			game.world = false
			tracker:OnPlayerDead()
			T.eq(#game.timers, 0)
		end)
	end)

	it("lists the events it handles", function()
		T.truthy(#ns.Tracker.EVENTS >= 9)
		for _, event in ipairs({ "PARTY_KILL", "PLAYER_DEAD", "NAME_PLATE_UNIT_ADDED" }) do
			local found = false
			for _, listed in ipairs(ns.Tracker.EVENTS) do found = found or listed == event end
			T.truthy(found, event)
		end
	end)

	it("ignores events it does not handle", function()
		tracker:HandleEvent("SOMETHING_ELSE", 1, 2)
	end)
end)
