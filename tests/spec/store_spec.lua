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
			T.eq(data.version, 4)
			T.isNil(data.spyImported)
			T.eq(data.imports.spy, 1234)
		end)

		it("upgrades schema 2: players keep everything and may now have a note", function()
			local kane = { name = "Kane", class = "WARLOCK", encounters = { { t = 5, r = "K" } }, extraKills = 1, extraDeaths = 0 }
			local data = Store.Migrate({ version = 2, imports = { spy = 9 }, players = { Kane = kane } })
			T.eq(data.version, 4)
			T.truthy(data.players.Kane == kane)
			T.eq(kane.class, "WARLOCK")
			T.eq(#kane.encounters, 1)
			T.isNil(kane.note)
			T.eq(data.imports.spy, 9)
		end)

		it("cleans saved notes: text kept, anything else dropped", function()
			local data = Store.Migrate({ version = 3, players = {
				good = { encounters = {}, note = "  Ganks at the dock  " },
				lines = { encounters = {}, note = "Rogue\nalways\r\nstealthed\tat night" },
				empty = { encounters = {}, note = "   " },
				number = { encounters = {}, note = 42 },
				table = { encounters = {}, note = {} },
			} })
			T.eq(data.players.good.note, "Ganks at the dock")
			T.eq(data.players.lines.note, "Rogue\nalways\nstealthed at night")
			T.isNil(data.players.empty.note)
			T.isNil(data.players.number.note)
			T.isNil(data.players.table.note)
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

	describe("notes", function()
		it("writes, changes and removes the note of a player in the list", function()
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			T.truthy(store:SetNote("Kane", "  Camps the flight master  "))
			T.eq(store:Get("Kane").note, "Camps the flight master")
			T.eq(fired, { "DATA_CHANGED" })

			T.truthy(store:SetNote("Kane", "Rogue"))
			T.eq(store:Get("Kane").note, "Rogue")

			T.truthy(store:SetNote("Kane", "   "), "an empty text removes it")
			T.isNil(store:Get("Kane").note)
			T.truthy(store:SetNote("Kane", "x"))
			T.truthy(store:SetNote("Kane", nil))
			T.isNil(store:Get("Kane").note)
		end)

		it("says nothing changed when the note is the same", function()
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			store:SetNote("Kane", "Rogue")
			fired = {}
			T.falsy(store:SetNote("Kane", " Rogue "))
			T.falsy(store:SetNote("Ally", ""))
			T.eq(fired, {})
		end)

		it("stays quiet when silent", function()
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			T.truthy(store:SetNote("Kane", "Rogue", { silent = true }))
			T.eq(store:Get("Kane").note, "Rogue")
			T.eq(fired, {})
		end)

		it("ignores players that are not in the list", function()
			T.falsy(store:SetNote("Nobody", "hello"))
			T.isNil(store:Get("Nobody"))
		end)

		it("keeps the line breaks, one blank line in a row at most", function()
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			store:SetNote("Kane", "\n\nfirst  \r\nsecond\rthird\n\n\n\nfourth\tfifth\n\n")
			T.eq(store:Get("Kane").note, "first\nsecond\nthird\n\nfourth fifth")
		end)

		it("takes long notes, up to the limit", function()
			T.truthy(Store.NOTE_MAX_LENGTH >= 1000)
			local long = string.rep("line\n", 150)
			T.eq(#Store.CleanNote(long), #long - 1)
		end)

		it("cuts long notes by letters, never in the middle of one", function()
			local long = string.rep("ñ", Store.NOTE_MAX_LENGTH + 20) -- two bytes each
			local note = Store.CleanNote(long)
			T.eq(note, string.rep("ñ", Store.NOTE_MAX_LENGTH))
			T.eq(Store.CleanNote(string.rep("a", Store.NOTE_MAX_LENGTH)), string.rep("a", Store.NOTE_MAX_LENGTH))
			T.eq(Store.CleanNote("a" .. string.rep(" ", Store.NOTE_MAX_LENGTH) .. "b"), "a", "no trailing space after the cut")
		end)

		it("goes with the player", function()
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			store:SetNote("Kane", "Rogue")
			store:Delete("Kane")
			store:AddEncounter("Kane", kill(2), nil, { silent = true })
			T.isNil(store:Get("Kane").note)
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

	-- The record of the account (v1.6) ---------------------------------------------------------

	describe("schema 4", function()
		-- What a character saved up to v1.5 (schema 3).
		local function schema3()
			return { version = 3, imports = { spy = 77 }, players = {
				["Kane-Mochivich"] = { name = "Kane-Mochivich", encounters = { { t = 5, r = "K" }, { t = 9, r = "D" } },
					extraKills = 2, extraDeaths = 1, note = "Ganks" },
				["Ana-Uno"] = { name = "Ana-Uno", encounters = {}, extraKills = 0, extraDeaths = 0 },
			} }
		end

		it("gives each fight of a character's old record his key, and his counts without details", function()
			local data = Store.Migrate(schema3(), "Yo-Mismo")
			T.eq(data.version, 4)
			local kane = data.players["Kane-Mochivich"]
			T.eq(kane.encounters[1].me, "Yo-Mismo")
			T.eq(kane.encounters[2].me, "Yo-Mismo")
			T.eq(kane.extraByCharacter, { ["Yo-Mismo"] = { kills = 2, deaths = 1 } })
			T.isNil(data.players["Ana-Uno"].extraByCharacter, "nothing to share out")
			T.eq(data.imports.spy, 77)
			T.eq(data.characters, {})
		end)

		it("upgrades without a character too: the fights just say nobody", function()
			local data = Store.Migrate(schema3())
			T.eq(data.version, 4)
			T.isNil(data.players["Kane-Mochivich"].encounters[1].me)
			T.isNil(data.players["Kane-Mochivich"].extraByCharacter)
		end)

		it("repairs malformed characters, shares and note origins", function()
			local data = Store.Migrate({ version = 4, characters = {
				["Yo-Mismo"] = { imports = "nope", merged = "yesterday" },
				[3] = {},
				broken = "nope",
			}, players = {
				a = { encounters = {}, extraByCharacter = { ["Yo-Mismo"] = { kills = "2" }, other = "x", none = { kills = 0 } } },
				b = { encounters = {}, extraByCharacter = "nope", noteFrom = "Yo-Mismo" },
				c = { encounters = {}, note = "kept", noteFrom = 5 },
			} })
			T.eq(data.characters, { ["Yo-Mismo"] = { imports = {} } })
			T.eq(data.players.a.extraByCharacter, { ["Yo-Mismo"] = { kills = 2, deaths = 0 } })
			T.isNil(data.players.b.extraByCharacter)
			T.isNil(data.players.b.noteFrom, "no note, no origin")
			T.eq(data.players.c.note, "kept")
			T.isNil(data.players.c.noteFrom)
		end)

		it("records new fights for the character playing now", function()
			store:SetCharacter("Yo-Mismo", { class = "MAGE", raceFile = "Gnome", level = 30 })
			store:AddEncounter("Kane", kill(1))
			store:AddEncounter("Kane", kill(2, { me = "Otro-Pj" }))
			T.eq(store:Get("Kane").encounters[1].me, "Yo-Mismo")
			T.eq(store:Get("Kane").encounters[2].me, "Otro-Pj", "a fight that says whose it is keeps it")
			T.eq(store:CurrentCharacter(), "Yo-Mismo")
			T.eq(store:Character("Yo-Mismo").class, "MAGE")
			T.eq(store:Character("Yo-Mismo").level, 30)
		end)

		it("keeps the oppGuild of each fight", function()
			store:AddEncounter("Kane", kill(1, { oppGuild = "Selecció Natural" }))
			T.eq(store:Get("Kane").encounters[1].oppGuild, "Selecció Natural")
		end)

		it("holds up to 500 fights per player; older ones stay counted, still of their character", function()
			T.eq(Store.MAX_ENCOUNTERS, 500)
			store:SetCharacter("Yo-Mismo")
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			store:AddEncounter("Kane", death(2), nil, { silent = true })
			for i = 3, Store.MAX_ENCOUNTERS + 2 do
				store:AddEncounter("Kane", kill(i, { me = "Otro-Pj" }), nil, { silent = true })
			end
			local kane = store:Get("Kane")
			T.eq(#kane.encounters, Store.MAX_ENCOUNTERS)
			T.eq({ Store.ExtraFor(kane, "Yo-Mismo") }, { 1, 1 })
			T.eq({ Store.Counts(kane) }, { Store.MAX_ENCOUNTERS + 1, 1 })
		end)

		it("matches a near fight of the same character only", function()
			store:AddEncounter("Kane", kill(1000, { me = "Yo-Mismo" }))
			local kane = store:Get("Kane")
			T.truthy(Store.HasEncounterNear(kane, Store.KILL, 1004, nil, "Yo-Mismo"))
			T.falsy(Store.HasEncounterNear(kane, Store.KILL, 1004, nil, "Otro-Pj"))
			T.truthy(Store.HasEncounterNear(kane, Store.KILL, 1004), "anyone's, when not said")
		end)

		it("tops up the totals of the character playing now, not anyone else's", function()
			store:SetCharacter("Yo-Mismo")
			store:AddEncounter("Kane", kill(1), nil, { silent = true })
			T.truthy(store:EnsureTotals("Kane", 3, 1))
			T.eq({ Store.ExtraFor(store:Get("Kane"), "Yo-Mismo") }, { 2, 1 })
			T.falsy(store:EnsureTotals("Kane", 3, 1), "already there")

			store:SetCharacter("Otro-Pj")
			T.truthy(store:EnsureTotals("Kane", 2, 0), "the other character's fights do not count for him")
			T.eq({ Store.ExtraFor(store:Get("Kane"), "Otro-Pj") }, { 2, 0 })
			T.eq({ Store.Counts(store:Get("Kane")) }, { 5, 1 })
		end)

		it("keeps the imports of each character apart", function()
			store:SetCharacter("Yo-Mismo")
			store:MarkImported("spy", 10)
			T.eq(store:ImportedAt("spy"), 10)
			store:SetCharacter("Otro-Pj")
			T.falsy(store:IsImported("spy"), "Spy keeps its data per character")
			store:SetCharacter("Yo-Mismo")
			T.truthy(store:IsImported("spy"))
		end)
	end)

	describe("merging the record of a character", function()
		local function charA()
			return { version = 3, imports = { spy = 50 }, players = {
				["Kane-Mochivich"] = { name = "Kane-Mochivich", guild = "Viejos", level = 30, class = "WARLOCK",
					first = 100, last = 200, extraKills = 1, extraDeaths = 0, note = "Ganks at the dock",
					encounters = { { t = 100, r = "K", zone = "Desolace" }, { t = 200, r = "D" } } },
				["Test-Dummy"] = { name = "Test-Dummy", test = true, encounters = { { t = 1, r = "K" } }, extraKills = 0, extraDeaths = 0 },
			} }
		end
		local function charB()
			return { version = 3, imports = {}, players = {
				["Kane-Mochivich"] = { name = "Kane-Mochivich", guild = "Nuevos", level = 40, race = "Humano",
					first = 300, last = 300, extraKills = 0, extraDeaths = 0, note = "Healer now",
					encounters = { { t = 300, r = "K", oppLevel = 40 } } },
				["Ana-Uno"] = { name = "Ana-Uno", first = 250, last = 250, extraKills = 0, extraDeaths = 2, encounters = {} },
			} }
		end

		it("adds all the fights of each character, oldest first, each with its character", function()
			T.eq(store:MergeCharacter(charA(), "Alfa-Uno", 1000), { players = 1, fights = 2 })
			T.eq(store:MergeCharacter(charB(), "Beta-Dos", 2000), { players = 2, fights = 1 })
			local kane = store:Get("Kane-Mochivich")
			local times, characters = {}, {}
			for i, encounter in ipairs(kane.encounters) do
				times[i], characters[i] = encounter.t, encounter.me
			end
			T.eq(times, { 100, 200, 300 })
			T.eq(characters, { "Alfa-Uno", "Alfa-Uno", "Beta-Dos" })
			T.eq(kane.encounters[1].zone, "Desolace")
			T.eq({ Store.Counts(kane) }, { 3, 1 })
			T.eq({ kane.first, kane.last }, { 100, 300 })
			T.eq({ Store.Counts(store:Get("Ana-Uno")) }, { 0, 2 })
			T.eq({ Store.ExtraFor(store:Get("Ana-Uno"), "Beta-Dos") }, { 0, 2 })
			T.eq({ Store.ExtraFor(kane, "Alfa-Uno") }, { 1, 0 })
		end)

		it("takes what is known of the enemy from the record that saw him last, in any order", function()
			store:MergeCharacter(charB(), "Beta-Dos", 1)
			store:MergeCharacter(charA(), "Alfa-Uno", 2)
			local kane = store:Get("Kane-Mochivich")
			T.eq(kane.guild, "Nuevos")
			T.eq(kane.level, 40)
			T.eq(kane.race, "Humano")
			T.eq(kane.class, "WARLOCK", "the older record fills what the newer did not know")
		end)

		it("keeps the note of one character as it is, and both when two wrote one, whole", function()
			store:MergeCharacter(charA(), "Alfa-Uno", 1)
			T.eq(store:Get("Kane-Mochivich").note, "Ganks at the dock")
			local b = charB()
			b.players["Kane-Mochivich"].note = string.rep("n", Store.NOTE_MAX_LENGTH)
			store:MergeCharacter(b, "Beta-Dos", 2)
			local note = store:Get("Kane-Mochivich").note
			T.eq(note, "[Alfa Uno]\nGanks at the dock\n\n[Beta Dos]\n" .. string.rep("n", Store.NOTE_MAX_LENGTH))
			T.truthy(ns.Util.Length(note) > Store.NOTE_MAX_LENGTH)
			T.isNil(store:Get("Kane-Mochivich").noteFrom)

			-- Loading it again keeps it whole; editing may shorten it but not make it longer.
			local again = Store.New(store.data)
			T.eq(again:Get("Kane-Mochivich").note, note)
			T.falsy(again:SetNote("Kane-Mochivich", note .. "more"), "cannot grow")
			T.truthy(again:SetNote("Kane-Mochivich", note:sub(1, 1020)))
			T.eq(ns.Util.Length(again:Get("Kane-Mochivich").note), 1020)
		end)

		it("forgets where a note came from once the user edits it", function()
			store:MergeCharacter(charA(), "Alfa-Uno", 1)
			store:SetNote("Kane-Mochivich", "My own words")
			store:MergeCharacter(charB(), "Beta-Dos", 2)
			T.eq(store:Get("Kane-Mochivich").note, "My own words\n\n[Beta Dos]\nHealer now")
		end)

		it("leaves test data out and brings the character's imports along", function()
			store:MergeCharacter(charA(), "Alfa-Uno", 1)
			T.isNil(store:Get("Test-Dummy"))
			store:SetCharacter("Alfa-Uno")
			T.eq(store:ImportedAt("spy"), 50)
		end)

		it("leaves the old record as a backup, with the key of its character", function()
			local old = charA()
			store:MergeCharacter(old, "Alfa-Uno", 1)
			T.eq(old.version, 4)
			T.eq(#old.players["Kane-Mochivich"].encounters, 2)
			T.eq(old.players["Kane-Mochivich"].encounters[1].me, "Alfa-Uno")
			T.notNil(old.players["Test-Dummy"])
			store:Get("Kane-Mochivich").encounters[1].zone = "Changed"
			T.eq(old.players["Kane-Mochivich"].encounters[1].zone, "Desolace", "the account has copies")
		end)

		it("merges a character once: a second login adds nothing", function()
			local old = charA()
			store:MergeCharacter(old, "Alfa-Uno", 1000)
			T.eq(store:Character("Alfa-Uno").merged, 1000)
			T.isNil(store:MergeCharacter(old, "Alfa-Uno", 2000))
			T.eq({ Store.Counts(store:Get("Kane-Mochivich")) }, { 2, 1 })
		end)

		it("tells listeners once, and only when something came in", function()
			store:MergeCharacter(charA(), "Alfa-Uno", 1)
			T.eq(fired, { "DATA_CHANGED" })
			store:MergeCharacter({}, "Nuevo-Pj", 2)
			T.eq(fired, { "DATA_CHANGED" }, "a new character brings nothing")
			T.notNil(store:Character("Nuevo-Pj").merged)
		end)

		it("does not bring back what was deleted or reset", function()
			local old = charA()
			store:MergeCharacter(old, "Alfa-Uno", 1)
			store:Delete("Kane-Mochivich")
			T.isNil(store:MergeCharacter(old, "Alfa-Uno", 2))
			T.isNil(store:Get("Kane-Mochivich"))

			store:MergeCharacter(charB(), "Beta-Dos", 3)
			store:Reset()
			T.notNil(store:Character("Beta-Dos").merged, "reset keeps the characters")
			T.isNil(store:MergeCharacter(charB(), "Beta-Dos", 4))
			T.isNil(store:Get("Ana-Uno"))
		end)

		it("rebuilds the account record from the backups when it was lost", function()
			local old = charA()
			store:MergeCharacter(old, "Alfa-Uno", 1)
			local fresh = Store.New({})
			T.eq(fresh:MergeCharacter(old, "Alfa-Uno", 2), { players = 1, fights = 2 })
			T.eq({ Store.Counts(fresh:Get("Kane-Mochivich")) }, { 2, 1 })
		end)

		it("never counts one fight twice", function()
			local a = charA()
			a.players["Kane-Mochivich"].encounters[3] = { t = 100, r = "K" } -- the same fight, saved twice
			store:MergeCharacter(a, "Alfa-Uno", 1)
			T.eq(#store:Get("Kane-Mochivich").encounters, 2)
		end)

		it("puts up with broken records", function()
			T.eq(store:MergeCharacter(nil, "Alfa-Uno", 1), { players = 0, fights = 0 })
			T.eq(store:MergeCharacter({ version = 3, players = { x = { encounters = { "nope", { t = "x", r = "K" }, { t = 4, r = "?" } } } } },
				"Beta-Dos", 1), { players = 1, fights = 0 })
			T.raises(function() store:MergeCharacter({}, nil, 1) end)
		end)
	end)
end)
