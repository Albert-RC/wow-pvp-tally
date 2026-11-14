-- PvP Tally: made-up players to try the window out (/tally test).
--
--   * "Test Reg": a Gnome rogue with six fights in several zones, a few counts
--     without details and a note;
--   * every playable race as a man and as a woman, to check every race icon (Skyborne on
--     both sides, since that race can be Alliance or Horde).
--
-- And /tally skull: a real player of your choice with one made-up kill, so their
-- nameplate shows the skull without having to fight them.
--
-- Every test player is flagged `test`, so Clear removes them all and nothing else, and
-- Add replaces them instead of piling up.

local _, ns = ...
local Util, Store, Races = ns.Util, ns.Store, ns.Races

local TestData = {}
ns.TestData = TestData

TestData.MAIN_KEY = "Test-Reg"
TestData.GUILD = "Hermandad de Prueba"
TestData.NOTE = "Hides in the bushes by the Crossroads. Always opens from stealth."

local DAY, HOUR = 86400, 3600

local MAIN_FIGHTS = {
	{ ago = 14 * DAY + 3 * HOUR, r = Store.KILL, zone = "Los Baldíos", subZone = "El Cruce", mapID = 1413, x = 0.5180, y = 0.3020, opp = 18, mine = 19 },
	{ ago = 14 * DAY + 2 * HOUR, r = Store.DEATH, zone = "Los Baldíos", subZone = "Camino del Oro Sur", mapID = 1413, x = 0.4630, y = 0.7390, opp = 18, mine = 19, how = "recap" },
	{ ago = 9 * DAY, r = Store.KILL, zone = "Sierra Espolón", subZone = "Molino Tarren", mapID = 1424, x = 0.6210, y = 0.2040, opp = 27, mine = 26 },
	{ ago = 5 * DAY + 6 * HOUR, r = Store.KILL, zone = "Vega de Tuercespina", subZone = "Bahía del Botín", mapID = 1434, x = 0.2730, y = 0.7710, opp = 38, mine = 37 },
	{ ago = 2 * DAY, r = Store.DEATH, zone = "Desolace", mapID = 1443, x = 0.5570, y = 0.5610, opp = 42, mine = 41, how = "targeting" },
	{ ago = 45 * 60, r = Store.KILL, zone = "Montañas de Alterac", subZone = "Ruinas de Alterac", mapID = 1416, x = 0.3940, y = 0.5880, opp = 44, mine = 44 },
}

-- A class for the man and one for the woman of each race (by race ID).
local CLASSES = {
	[1] = { "PALADIN", "PRIEST" },
	[3] = { "HUNTER", "WARRIOR" },
	[4] = { "DRUID", "ROGUE" },
	[7] = { "MAGE", "WARLOCK" },
	[95] = { "DRUID", "PRIEST" },
	[2] = { "WARRIOR", "SHAMAN" },
	[5] = { "WARLOCK", "MAGE" },
	[6] = { "SHAMAN", "DRUID" },
	[8] = { "ROGUE", "HUNTER" },
	[96] = { "WARRIOR", "MAGE" },
}

local function Encounter(fight, now)
	return {
		t = now - fight.ago, r = fight.r, zone = fight.zone, subZone = fight.subZone,
		mapID = fight.mapID, x = fight.x, y = fight.y,
		oppLevel = fight.opp, myLevel = fight.mine,
		how = fight.how or (fight.r == Store.KILL and "kill" or nil),
	}
end

local function AddPlayer(store, key, info, fights, now)
	for _, fight in ipairs(fights) do
		store:AddEncounter(key, Encounter(fight, now), info, { silent = true })
	end
	store:Get(key).test = true
end

-- Whether a race (by ID) is played by both factions, i.e. appears twice in Races.LIST.
local function SharedRace(race)
	for _, other in ipairs(Races.LIST) do
		if other.token == race.token and other.id ~= race.id then
			return true
		end
	end
	return false
end

-- labels: { male, female, Alliance, Horde } words for the names. raceName(id) gives the
-- localized race name (nil falls back to the token). Returns how many players were added.
function TestData.Add(store, labels, raceName, now)
	TestData.Clear(store, { silent = true })

	AddPlayer(store, TestData.MAIN_KEY, {
		class = "ROGUE", race = raceName(7) or "Gnome", raceFile = "Gnome", sex = Races.FEMALE,
		guild = TestData.GUILD, faction = "Alliance", level = 44,
	}, MAIN_FIGHTS, now)
	local main = store:Get(TestData.MAIN_KEY)
	main.extraKills, main.extraDeaths = 2, 1 -- also shows the "without details" line
	store:SetNote(TestData.MAIN_KEY, TestData.NOTE, { silent = true })

	local count, index = 1, 0
	for _, race in ipairs(Races.LIST) do
		local name = raceName(race.id) or race.token
		for sexIndex, sex in ipairs({ Races.MALE, Races.FEMALE }) do
			index = index + 1
			local level = 20 + index * 2
			local base = MAIN_FIGHTS[(index - 1) % #MAIN_FIGHTS + 1]
			local fights = {
				{ ago = (index + 1) * DAY, r = Store.KILL, zone = base.zone, subZone = base.subZone, mapID = base.mapID,
					x = base.x, y = base.y, opp = level, mine = level + 1 },
			}
			if index % 2 == 0 then
				fights[2] = { ago = index * HOUR, r = Store.DEATH, zone = base.zone, mapID = base.mapID, opp = level, mine = level, how = "recap" }
			end
			local suffix = sex == Races.MALE and labels.male or labels.female
			if SharedRace(race) then
				suffix = suffix .. " (" .. (labels[race.faction] or race.faction) .. ")"
			end
			AddPlayer(store, "Test-" .. name .. " " .. suffix, {
				class = CLASSES[race.id] and CLASSES[race.id][sexIndex] or "WARRIOR",
				race = name, raceFile = race.token, sex = sex,
				guild = TestData.GUILD, faction = race.faction, level = level,
			}, fights, now)
			count = count + 1
		end
	end

	store:Changed()
	return count
end

-- /tally skull ---------------------------------------------------------------------------------

-- What the user typed, "First Last" or "First-Last", as a store key ("First-Last").
-- nil for nothing.
function TestData.KeyFromName(text)
	if type(text) ~= "string" then
		return nil
	end
	local key = Util.Trim(text):gsub("%s+", " ")
	if key == "" then
		return nil
	end
	if not key:find("-", 1, true) then
		key = key:gsub(" ", "-", 1)
	end
	return key
end

-- Adds key as a test player with one kill at context (WowApi.CurrentContext: t, zone,
-- subZone, mapID, x, y, myLevel). info is what is known of them (nil: only the name).
-- A player already in the list is left alone (never mixed with test data): returns false.
function TestData.AddPlayer(store, key, info, context)
	assert(type(key) == "string" and key ~= "", "player key expected")
	if store:Get(key) then
		return false
	end
	context = context or {}
	store:AddEncounter(key, {
		t = context.t, r = Store.KILL, how = "test",
		zone = context.zone, subZone = context.subZone, mapID = context.mapID, x = context.x, y = context.y,
		oppLevel = info and info.level, myLevel = context.myLevel,
	}, info, { silent = true })
	store:Get(key).test = true
	store:Changed()
	return true
end

-- Removes every test player. Returns how many.
function TestData.Clear(store, options)
	return store:DeleteWhere(function(key, player)
		return player.test == true or key == TestData.MAIN_KEY
	end, options)
end
