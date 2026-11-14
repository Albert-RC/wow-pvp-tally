local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("ListModel", function()
	local ns, Store, ListModel, store
	local function fight(key, t, result, extra, info)
		local encounter = { t = t, r = result or Store.KILL }
		for k, v in pairs(extra or {}) do encounter[k] = v end
		store:AddEncounter(key, encounter, info, { silent = true })
	end
	local function keys(rows, kind)
		local list = {}
		for _, row in ipairs(rows) do
			if not kind or row.kind == kind then list[#list + 1] = row.key end
		end
		return list
	end

	before_each(function()
		ns = Addon.LoadWith({ "UI/ListModel.lua" })
		Store, ListModel = ns.Store, ns.ListModel
		store = Store.New({})
		fight("Ana-Uno", 300, Store.KILL, { zone = "Desolace" }, { race = "Humano", guild = "Zeta", level = 30 })
		fight("Bea-Dos", 100, Store.DEATH, { zone = "Los Baldíos", subZone = "El Cruce" }, { race = "Gnoma", guild = "Alfa", level = 20 })
		fight("Bea-Dos", 200, Store.KILL)
		fight("Cris-Tres", 200, Store.KILL, nil, { level = 40 })
		fight("Cris-Tres", 250, Store.KILL)
		store:GetOrCreate("Nobody-Fought") -- no fights: never listed
	end)

	it("lists one row per player with fights, newest first fight on top by default", function()
		local rows, totals, count = ListModel.Build(store)
		T.eq(keys(rows), { "Ana-Uno", "Cris-Tres", "Bea-Dos" })
		T.eq(count, 3)
		T.eq(totals, { players = 3, kills = 4, deaths = 1 })
		T.eq(rows[1].name, "Ana Uno")
		T.eq(rows[3].kills, 1)
		T.eq(rows[3].deaths, 1)
	end)

	describe("sorting", function()
		it("sorts by every column", function()
			local function order(sortKey, ascending)
				return keys((ListModel.Build(store, { sortKey = sortKey, ascending = ascending })))
			end
			T.eq(order("name", true), { "Ana-Uno", "Bea-Dos", "Cris-Tres" })
			T.eq(order("kills", false), { "Cris-Tres", "Ana-Uno", "Bea-Dos" })
			T.eq(order("deaths", false)[1], "Bea-Dos")
			T.eq(order("level", false), { "Cris-Tres", "Ana-Uno", "Bea-Dos" })
			T.eq(order("guild", true), { "Bea-Dos", "Ana-Uno", "Cris-Tres" }, "no guild sorts last")
			T.eq(order("race", true), { "Bea-Dos", "Ana-Uno", "Cris-Tres" })
			T.eq(order("first", true), { "Bea-Dos", "Cris-Tres", "Ana-Uno" })
		end)

		it("breaks ties by name", function()
			fight("Dani-Cuatro", 400)
			local rows = ListModel.Build(store, { sortKey = "deaths", ascending = true })
			T.eq(keys(rows), { "Ana-Uno", "Cris-Tres", "Dani-Cuatro", "Bea-Dos" })
		end)

		it("knows which columns start A to Z", function()
			T.truthy(ListModel.DefaultAscending("name"))
			T.truthy(ListModel.DefaultAscending("race"))
			T.falsy(ListModel.DefaultAscending("kills"))
			T.falsy(ListModel.DefaultAscending("first"))
			T.falsy(ListModel.DefaultAscending("note"))
		end)

		it("puts the players with a note first, then by name", function()
			store:SetNote("Cris-Tres", "Healer")
			local rows = ListModel.Build(store, { sortKey = "note", ascending = false })
			T.eq(keys(rows), { "Cris-Tres", "Ana-Uno", "Bea-Dos" })
			rows = ListModel.Build(store, { sortKey = "note", ascending = true })
			T.eq(keys(rows)[3], "Cris-Tres")
		end)
	end)

	describe("notes", function()
		local LIMIT = { lines = 3, characters = 20 }

		it("splits a note into its lines", function()
			T.eq(ListModel.NoteLines("Rogue\nHealer", LIMIT), { "Rogue", "Healer" })
			T.eq(ListModel.NoteLines("One line", LIMIT), { "One line" })
		end)

		it("keeps blank lines as a space, so the tooltip does not drop them", function()
			T.eq(ListModel.NoteLines("Rogue\n\nHealer", LIMIT), { "Rogue", " ", "Healer" })
		end)

		it("cuts after the last line shown, with ...", function()
			T.eq(ListModel.NoteLines("1\n2\n3\n4\n5", LIMIT), { "1", "2", "3..." })
		end)

		it("cuts after the last character shown, with ...", function()
			T.eq(ListModel.NoteLines("Camps the flight master all day", LIMIT), { "Camps the flight mas..." })
			T.eq(ListModel.NoteLines("ñññññññññññññññññññññññ", LIMIT), { "ññññññññññññññññññññ..." }, "letters, not bytes")
		end)

		it("gives nil for no note", function()
			T.isNil(ListModel.NoteLines(nil, LIMIT))
			T.isNil(ListModel.NoteLines("", LIMIT))
		end)

		it("shows less in the game's tooltip than in the list", function()
			T.truthy(ListModel.NOTE_PREVIEW_UNIT.lines < ListModel.NOTE_PREVIEW_LIST.lines)
			T.truthy(ListModel.NOTE_PREVIEW_UNIT.characters < ListModel.NOTE_PREVIEW_LIST.characters)
		end)

		it("tells which players have a note", function()
			T.truthy(ListModel.HasNote({ note = "Healer" }))
			T.falsy(ListModel.HasNote({ note = "" }))
			T.falsy(ListModel.HasNote({ note = 3 }))
			T.falsy(ListModel.HasNote({}))
			T.falsy(ListModel.HasNote(nil))
		end)
	end)

	describe("search", function()
		it("matches names, guilds and zones, ignoring case and spaces around", function()
			T.eq(keys((ListModel.Build(store, { filter = "  bea " }))), { "Bea-Dos" })
			T.eq(keys((ListModel.Build(store, { filter = "zeta" }))), { "Ana-Uno" })
			T.eq(keys((ListModel.Build(store, { filter = "cruce" }))), { "Bea-Dos" })
			T.eq(keys((ListModel.Build(store, { filter = "desolace" }))), { "Ana-Uno" })
		end)

		it("totals only what matches", function()
			local _, totals = ListModel.Build(store, { filter = "bea" })
			T.eq(totals, { players = 1, kills = 1, deaths = 1 })
		end)

		it("treats the search text literally", function()
			T.eq(#(ListModel.Build(store, { filter = "%a" })), 0)
		end)
	end)

	describe("expanding", function()
		it("adds a header and the fights, newest first, under an open player", function()
			local rows = ListModel.Build(store, { expanded = { ["Bea-Dos"] = true } })
			local kinds = {}
			for _, row in ipairs(rows) do kinds[#kinds + 1] = row.kind end
			T.eq(kinds, { "player", "player", "player", "header", "fight", "fight" })
			T.eq(rows[5].encounter.t, 200)
			T.eq(rows[6].encounter.t, 100)
		end)

		it("adds the fights without details at the end", function()
			store:Get("Ana-Uno").extraKills = 2
			local rows = ListModel.Build(store, { expanded = { ["Ana-Uno"] = true } })
			T.eq(rows[4], { kind = "extra", key = "Ana-Uno", kills = 2, deaths = 0 })
		end)

		it("numbers player rows for the stripes", function()
			local rows = ListModel.Build(store)
			T.eq({ rows[1].index, rows[2].index, rows[3].index }, { 1, 2, 3 })
		end)
	end)

	describe("formatting", function()
		it("shows the kill / death ratio", function()
			T.eq(ListModel.Ratio(0, 0), "-")
			T.eq(ListModel.Ratio(3, 0), "3")
			T.eq(ListModel.Ratio(4, 1), "4.00")
			T.eq(ListModel.Ratio(2, 3), "0.67")
		end)

		it("joins zone and sub-zone", function()
			T.eq(ListModel.ZoneText({ zone = "A", subZone = "B" }), "A - B")
			T.eq(ListModel.ZoneText({ zone = "A" }), "A")
			T.eq(ListModel.ZoneText({}), "-")
		end)

		it("shows unknown levels as ??", function()
			T.eq(ListModel.LevelText(25), "25")
			T.eq(ListModel.LevelText(nil), "??")
			T.eq(ListModel.LevelText(-1), "??")
		end)
	end)
end)
