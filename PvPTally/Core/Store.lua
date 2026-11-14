-- PvP Tally: the record of every enemy player and every fight, per character
-- (PvPTallyCharDB). The only module that writes that data.
--
-- Saved layout (schema 3):
--   version = 3
--   imports = { spy = <epoch of the first import> }
--   players[key] = {
--     name, class, race, raceFile, sex, guild, faction, level, lastZone,  -- last known
--     first, last,                    -- epoch of the first and last fight
--     extraKills, extraDeaths,        -- fights counted without details
--     note,                           -- the user's own note: one line, never empty
--     test,                           -- made up by /tally test
--     encounters = {                  -- oldest first
--       { t, r = "K" | "D", zone, subZone, mapID, x, y, oppLevel, myLevel, how },
--     },
--   }
-- key is "First-Surname", the key Spy uses too.

local _, ns = ...
local Util = ns.Util

local Store = {}
Store.__index = Store
ns.Store = Store

Store.KILL = "K"
Store.DEATH = "D"
Store.SCHEMA_VERSION = 3
Store.MAX_ENCOUNTERS = 250   -- per player; older fights are folded into the extra counts
Store.SAME_FIGHT_WINDOW = 10 -- seconds: two records of one result this close are one fight
Store.NOTE_MAX_LENGTH = 200  -- characters, not bytes: the popup counts letters too

local INFO_STRINGS = { "class", "race", "raceFile", "guild", "faction", "lastZone" }

-- Migrations ------------------------------------------------------------------------------
-- MIGRATIONS[n] upgrades data from schema n to n + 1.

local MIGRATIONS = {
	-- 1 -> 2: the Spy import flag moves under imports.
	[1] = function(data)
		data.imports = type(data.imports) == "table" and data.imports or {}
		if data.spyImported then
			data.imports.spy = data.spyImported
			data.spyImported = nil
		end
	end,
	-- 2 -> 3: players may have a note. Nothing to convert; Migrate cleans it like any field.
	[2] = function() end,
}

-- Brings saved data up to the current schema and drops whatever is malformed, so the
-- rest of the code can trust it. Works on the table in place and returns it.
function Store.Migrate(data)
	if data.version == nil then
		-- A brand-new table is current; one with content predates the version field.
		data.version = next(data) == nil and Store.SCHEMA_VERSION or 1
	end
	data.version = tonumber(data.version) or 1
	while data.version < Store.SCHEMA_VERSION do
		local step = MIGRATIONS[data.version]
		if step then
			step(data)
		end
		data.version = data.version + 1
	end

	if type(data.players) ~= "table" then data.players = {} end
	if type(data.imports) ~= "table" then data.imports = {} end
	for key, player in pairs(data.players) do
		if type(key) ~= "string" or type(player) ~= "table" then
			data.players[key] = nil
		else
			if type(player.encounters) ~= "table" then player.encounters = {} end
			player.extraKills = tonumber(player.extraKills) or 0
			player.extraDeaths = tonumber(player.extraDeaths) or 0
			player.note = Store.CleanNote(player.note)
		end
	end
	return data
end

-- Player records (static helpers) ---------------------------------------------------------

-- The first `count` characters of a UTF-8 text (a cut by bytes could split a letter).
local function FirstCharacters(text, count)
	local position, characters = 1, 0
	while position <= #text do
		characters = characters + 1
		if characters > count then
			return text:sub(1, position - 1)
		end
		-- A lead byte takes its continuation bytes along; any other byte stands alone.
		local _, last = text:find("^[\192-\255][\128-\191]*", position)
		position = (last or position) + 1
	end
	return text
end

-- A note as it is kept: one line, trimmed, at most NOTE_MAX_LENGTH characters. nil for
-- anything else, an empty text included, so "has a note" is just `player.note ~= nil`.
function Store.CleanNote(text)
	if type(text) ~= "string" then
		return nil
	end
	text = Util.Trim(FirstCharacters(Util.Trim((text:gsub("%c+", " "))), Store.NOTE_MAX_LENGTH))
	return text ~= "" and text or nil
end

-- Copies what is known about an enemy (class, race, guild, level...) onto his record.
-- Missing or empty values never erase known ones.
function Store.UpdateInfo(player, info)
	if type(player) ~= "table" or type(info) ~= "table" then
		return
	end
	for _, field in ipairs(INFO_STRINGS) do
		local value = info[field]
		if type(value) == "string" and value ~= "" then
			player[field] = value
		end
	end
	if info.sex == 2 or info.sex == 3 then
		player.sex = info.sex
	end
	if type(info.level) == "number" and info.level > 0 then
		player.level = info.level
	end
end

-- Kills and deaths that have details (one encounter each).
function Store.DetailedCounts(player)
	local kills, deaths = 0, 0
	for _, encounter in ipairs(player.encounters) do
		if encounter.r == Store.KILL then
			kills = kills + 1
		else
			deaths = deaths + 1
		end
	end
	return kills, deaths
end

-- All kills and deaths, with and without details.
function Store.Counts(player)
	local kills, deaths = Store.DetailedCounts(player)
	return kills + (player.extraKills or 0), deaths + (player.extraDeaths or 0)
end

function Store.HasEncounterNear(player, result, t, window)
	window = window or Store.SAME_FIGHT_WINDOW
	for _, encounter in ipairs(player.encounters) do
		if encounter.r == result and math.abs((encounter.t or 0) - t) <= window then
			return true
		end
	end
	return false
end

function Store.TouchTimes(player, t)
	if type(t) ~= "number" then
		return
	end
	if not player.first or t < player.first then player.first = t end
	if not player.last or t > player.last then player.last = t end
end

-- Keeps the list ordered by time, oldest first. Fights usually arrive in order, so the
-- search starts from the end.
local function InsertByTime(list, encounter)
	local index = #list + 1
	while index > 1 and (list[index - 1].t or 0) > encounter.t do
		index = index - 1
	end
	table.insert(list, index, encounter)
end

-- The oldest fights beyond the limit stay only as counts.
local function Trim(player)
	while #player.encounters > Store.MAX_ENCOUNTERS do
		local oldest = table.remove(player.encounters, 1)
		if oldest.r == Store.KILL then
			player.extraKills = player.extraKills + 1
		else
			player.extraDeaths = player.extraDeaths + 1
		end
	end
end

-- Store ---------------------------------------------------------------------------------------

-- data: the saved table (PvPTallyCharDB), migrated in place. bus: an Events bus, optional.
function Store.New(data, bus)
	assert(type(data) == "table", "saved data table expected")
	return setmetatable({ data = Store.Migrate(data), bus = bus }, Store)
end

function Store:Get(key)
	return self.data.players[key]
end

function Store:GetOrCreate(key)
	assert(type(key) == "string" and key ~= "", "player key expected")
	local player = self.data.players[key]
	if not player then
		player = { name = key, encounters = {}, extraKills = 0, extraDeaths = 0 }
		self.data.players[key] = player
	end
	return player
end

-- Iterates key, player.
function Store:Players()
	return pairs(self.data.players)
end

-- Tells listeners the data changed.
function Store:Changed()
	if self.bus then
		self.bus:Fire(ns.Events.DATA_CHANGED)
	end
end

-- Records a fight. encounter needs t (epoch) and r (KILL or DEATH); info is what is known
-- of the enemy at that moment. options.silent skips the events (bulk imports call
-- Changed once at the end). Returns the encounter and the player record.
function Store:AddEncounter(key, encounter, info, options)
	assert(type(encounter) == "table", "encounter expected")
	assert(encounter.r == Store.KILL or encounter.r == Store.DEATH, "encounter.r must be KILL or DEATH")
	assert(type(encounter.t) == "number", "encounter.t must be a time")
	local player = self:GetOrCreate(key)
	Store.UpdateInfo(player, info)
	InsertByTime(player.encounters, encounter)
	Store.TouchTimes(player, encounter.t)
	Trim(player)
	if not (options and options.silent) and self.bus then
		self.bus:Fire(ns.Events.ENCOUNTER_ADDED, key, encounter, player)
		self:Changed()
	end
	return encounter, player
end

-- Makes sure a player's totals are at least kills / deaths, adding what is missing as
-- counts without details. Never lowers anything. Returns whether something changed.
function Store:EnsureTotals(key, kills, deaths)
	local player = self:GetOrCreate(key)
	local detailedKills, detailedDeaths = Store.DetailedCounts(player)
	local extraKills = math.max(player.extraKills, (kills or 0) - detailedKills)
	local extraDeaths = math.max(player.extraDeaths, (deaths or 0) - detailedDeaths)
	local changed = extraKills ~= player.extraKills or extraDeaths ~= player.extraDeaths
	player.extraKills, player.extraDeaths = extraKills, extraDeaths
	return changed
end

-- Writes, changes or (with an empty text) removes the note of a player in the list.
-- options.silent skips the event. Returns whether something changed.
function Store:SetNote(key, text, options)
	local player = self.data.players[key]
	if not player then
		return false
	end
	local note = Store.CleanNote(text)
	if note == player.note then
		return false
	end
	player.note = note
	if not (options and options.silent) then
		self:Changed()
	end
	return true
end

function Store:Delete(key)
	if not self.data.players[key] then
		return false
	end
	self.data.players[key] = nil
	self:Changed()
	return true
end

-- Deletes every player for which predicate(key, player) is true. Returns how many.
function Store:DeleteWhere(predicate, options)
	local count = 0
	for key, player in pairs(self.data.players) do
		if predicate(key, player) then
			self.data.players[key] = nil
			count = count + 1
		end
	end
	if count > 0 and not (options and options.silent) then
		self:Changed()
	end
	return count
end

function Store:Reset()
	self.data.players = {}
	self.data.imports = {}
	self:Changed()
end

-- Imports -----------------------------------------------------------------------------------------

function Store:IsImported(source)
	return self.data.imports[source] ~= nil
end

function Store:MarkImported(source, when)
	self.data.imports[source] = when
end
