-- PvP Tally: the record of every enemy player and every fight of the account
-- (PvPTallyAccountDB), with the character of the user that fought each fight. The only
-- module that writes that data, and the per-character records (PvPTallyCharDB) it came
-- from.
--
-- Up to v1.5 each character kept its own record in PvPTallyCharDB. The game loads only the
-- one of the character that logs in, so each is folded into the account record the first
-- time that character logs in (MergeCharacter), and then kept as it was, as a backup.
--
-- Saved layout (schema 4), the same in both tables:
--   version = 4
--   imports = { spy = <epoch> }       -- imports of no known character: a per-character record
--                                     -- keeps its own here; the account record, only while
--                                     -- it does not know who is playing
--   characters[me] = {                -- the user's characters (account record)
--     class, race, raceFile, sex, faction, level,   -- last known
--     imports = { spy = <epoch of the first import> },
--     merged,                         -- epoch its PvPTallyCharDB was folded in
--   }
--   players[key] = {
--     name, class, race, raceFile, sex, guild, faction, level, lastZone,  -- last known
--     first, last,                    -- epoch of the first and last fight
--     extraKills, extraDeaths,        -- fights counted without details, all characters
--     extraByCharacter = { [me] = { kills, deaths } },  -- how many of those are whose
--     note,                           -- the user's own note: text with line breaks, never empty
--     noteFrom,                       -- the character a merged note came from, until edited
--     test,                           -- made up by /tally test
--     encounters = {                  -- oldest first
--       { t, r = "K" | "D", zone, subZone, mapID, x, y, oppLevel, oppGuild, myLevel, how, me },
--     },
--   }
-- key and me are "First-Surname", the key Spy uses too. Schema 3 had no characters,
-- extraByCharacter, noteFrom, oppGuild or me.

local _, ns = ...
local Util = ns.Util

local Store = {}
Store.__index = Store
ns.Store = Store

Store.KILL = "K"
Store.DEATH = "D"
Store.SCHEMA_VERSION = 4
Store.MAX_ENCOUNTERS = 500   -- per player; older fights are folded into the extra counts
Store.SAME_FIGHT_WINDOW = 10 -- seconds: two records of one result this close are one fight
Store.NOTE_MAX_LENGTH = 1000 -- characters, not bytes: the edit box counts letters too
-- A note joined from several characters may be longer than one can write; this only
-- stops a broken saved note from growing without end.
Store.NOTE_STORED_MAX = 20000

local INFO_STRINGS = { "class", "race", "raceFile", "guild", "faction", "lastZone" }

-- Migrations ------------------------------------------------------------------------------
-- MIGRATIONS[n] upgrades data from schema n to n + 1. me: the character the data belongs
-- to, when known.

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
	-- 3 -> 4: the record of one character: each fight, and the counts without details, are
	-- that character's.
	[3] = function(data, me)
		if type(me) ~= "string" or type(data.players) ~= "table" then
			return
		end
		for _, player in pairs(data.players) do
			if type(player) == "table" then
				for _, encounter in ipairs(type(player.encounters) == "table" and player.encounters or {}) do
					if type(encounter) == "table" and encounter.me == nil then
						encounter.me = me
					end
				end
				local kills, deaths = tonumber(player.extraKills) or 0, tonumber(player.extraDeaths) or 0
				if kills + deaths > 0 and player.extraByCharacter == nil then
					player.extraByCharacter = { [me] = { kills = kills, deaths = deaths } }
				end
			end
		end
	end,
}

local function RepairExtraByCharacter(player)
	local byCharacter = player.extraByCharacter
	if type(byCharacter) ~= "table" then
		player.extraByCharacter = nil
		return
	end
	for me, counts in pairs(byCharacter) do
		local kills = type(counts) == "table" and math.max(0, tonumber(counts.kills) or 0) or 0
		local deaths = type(counts) == "table" and math.max(0, tonumber(counts.deaths) or 0) or 0
		if type(me) ~= "string" or kills + deaths == 0 then
			byCharacter[me] = nil
		else
			counts.kills, counts.deaths = kills, deaths
		end
	end
	if next(byCharacter) == nil then
		player.extraByCharacter = nil
	end
end

local function RepairCharacters(data)
	if type(data.characters) ~= "table" then
		data.characters = {}
	end
	for key, character in pairs(data.characters) do
		if type(key) ~= "string" or key == "" or type(character) ~= "table" then
			data.characters[key] = nil
		else
			if type(character.imports) ~= "table" then character.imports = {} end
			if type(character.merged) ~= "number" then character.merged = nil end
		end
	end
end

-- Brings saved data up to the current schema and drops whatever is malformed, so the
-- rest of the code can trust it. Works on the table in place and returns it. me: the
-- character an old per-character record belongs to (its fights get his key).
function Store.Migrate(data, me)
	if data.version == nil then
		-- A brand-new table is current; one with content predates the version field.
		data.version = next(data) == nil and Store.SCHEMA_VERSION or 1
	end
	data.version = tonumber(data.version) or 1
	while data.version < Store.SCHEMA_VERSION do
		local step = MIGRATIONS[data.version]
		if step then
			step(data, me)
		end
		data.version = data.version + 1
	end

	if type(data.players) ~= "table" then data.players = {} end
	if type(data.imports) ~= "table" then data.imports = {} end
	RepairCharacters(data)
	for key, player in pairs(data.players) do
		if type(key) ~= "string" or type(player) ~= "table" then
			data.players[key] = nil
		else
			if type(player.encounters) ~= "table" then player.encounters = {} end
			player.extraKills = tonumber(player.extraKills) or 0
			player.extraDeaths = tonumber(player.extraDeaths) or 0
			RepairExtraByCharacter(player)
			player.note = Store.CleanNote(player.note, Store.NOTE_STORED_MAX)
			if player.note == nil or type(player.noteFrom) ~= "string" then
				player.noteFrom = nil
			end
		end
	end
	return data
end

-- Player records (static helpers) ---------------------------------------------------------

-- A note as it is kept: trimmed, at most `limit` characters (NOTE_MAX_LENGTH when not
-- given), line breaks as "\n" with at most one blank line in a row, no other control
-- characters. nil for anything else, an empty text included, so "has a note" is just
-- `player.note ~= nil`.
function Store.CleanNote(text, limit)
	if type(text) ~= "string" then
		return nil
	end
	text = text:gsub("\r\n?", "\n"):gsub("[%z\1-\9\11-\31\127]", " ")
	text = text:gsub("[ ]+\n", "\n"):gsub("\n\n\n+", "\n\n")
	text = Util.Trim((Util.FirstCharacters(Util.Trim(text), limit or Store.NOTE_MAX_LENGTH)))
	return text ~= "" and text or nil
end

-- How long the note of a player may be: what one can write, or more for a note that is
-- already longer (joined from several characters), so opening and saving it loses nothing.
function Store.NoteLimit(note)
	local length = type(note) == "string" and Util.Length(note) or 0
	return math.min(Store.NOTE_STORED_MAX, math.max(Store.NOTE_MAX_LENGTH, length))
end

local function CopyInfo(player, info, onlyMissing)
	for _, field in ipairs(INFO_STRINGS) do
		local value = info[field]
		if type(value) == "string" and value ~= "" and not (onlyMissing and player[field] ~= nil) then
			player[field] = value
		end
	end
	if (info.sex == 2 or info.sex == 3) and not (onlyMissing and player.sex ~= nil) then
		player.sex = info.sex
	end
	if type(info.level) == "number" and info.level > 0 and not (onlyMissing and player.level ~= nil) then
		player.level = info.level
	end
end

-- Copies what is known about an enemy (class, race, guild, level...) onto his record.
-- Missing or empty values never erase known ones.
function Store.UpdateInfo(player, info)
	if type(player) ~= "table" or type(info) ~= "table" then
		return
	end
	CopyInfo(player, info, false)
end

-- Kills and deaths that have details (one encounter each); only those of character `me`
-- when given.
function Store.DetailedCounts(player, me)
	local kills, deaths = 0, 0
	for _, encounter in ipairs(player.encounters) do
		if me == nil or encounter.me == me then
			if encounter.r == Store.KILL then
				kills = kills + 1
			else
				deaths = deaths + 1
			end
		end
	end
	return kills, deaths
end

-- All kills and deaths, with and without details.
function Store.Counts(player)
	local kills, deaths = Store.DetailedCounts(player)
	return kills + (player.extraKills or 0), deaths + (player.extraDeaths or 0)
end

-- The kills and deaths without details known to be of character `me`.
function Store.ExtraFor(player, me)
	local counts = player.extraByCharacter and player.extraByCharacter[me]
	if not counts then
		return 0, 0
	end
	return counts.kills, counts.deaths
end

-- Adds counts without details, on the totals and (when me is known) on that character.
local function AddExtra(player, me, kills, deaths)
	player.extraKills = player.extraKills + kills
	player.extraDeaths = player.extraDeaths + deaths
	if me == nil or kills + deaths == 0 then
		return
	end
	player.extraByCharacter = player.extraByCharacter or {}
	local counts = player.extraByCharacter[me]
	if not counts then
		counts = { kills = 0, deaths = 0 }
		player.extraByCharacter[me] = counts
	end
	counts.kills = counts.kills + kills
	counts.deaths = counts.deaths + deaths
end

-- Whether the player has a fight of `result` within `window` seconds of t; only fights
-- of character `me` count when given (another character's fight is never this one).
function Store.HasEncounterNear(player, result, t, window, me)
	window = window or Store.SAME_FIGHT_WINDOW
	for _, encounter in ipairs(player.encounters) do
		if encounter.r == result and math.abs((encounter.t or 0) - t) <= window
			and (me == nil or encounter.me == me) then
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

-- The oldest fights beyond the limit stay only as counts, still of their character.
local function Trim(player)
	while #player.encounters > Store.MAX_ENCOUNTERS do
		local oldest = table.remove(player.encounters, 1)
		local won = oldest.r == Store.KILL
		AddExtra(player, oldest.me, won and 1 or 0, won and 0 or 1)
	end
end

-- Store ---------------------------------------------------------------------------------------

-- data: the saved table (PvPTallyAccountDB), migrated in place. bus: an Events bus, optional.
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

-- Records a fight. encounter needs t (epoch) and r (KILL or DEATH); it is the fight of
-- the character playing now unless it says (me). info is what is known of the enemy at
-- that moment. options.silent skips the events (bulk imports call Changed once at the
-- end). Returns the encounter and the player record.
function Store:AddEncounter(key, encounter, info, options)
	assert(type(encounter) == "table", "encounter expected")
	assert(encounter.r == Store.KILL or encounter.r == Store.DEATH, "encounter.r must be KILL or DEATH")
	assert(type(encounter.t) == "number", "encounter.t must be a time")
	if encounter.me == nil then
		encounter.me = self.me
	end
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

-- Makes sure a player's totals with the character playing now (all of them, while it is
-- not known) are at least kills / deaths, adding what is missing as counts without
-- details. Never lowers anything. Returns whether something changed.
function Store:EnsureTotals(key, kills, deaths)
	local player = self:GetOrCreate(key)
	local me = self.me
	local detailedKills, detailedDeaths = Store.DetailedCounts(player, me)
	local extraKills, extraDeaths = player.extraKills, player.extraDeaths
	if me then
		extraKills, extraDeaths = Store.ExtraFor(player, me)
	end
	local addKills = math.max(0, (kills or 0) - detailedKills - extraKills)
	local addDeaths = math.max(0, (deaths or 0) - detailedDeaths - extraDeaths)
	AddExtra(player, me, addKills, addDeaths)
	return addKills + addDeaths > 0
end

-- Writes, changes or (with an empty text) removes the note of a player in the list.
-- A note longer than one can write (joined from several characters) may shrink but not
-- grow. options.silent skips the event. Returns whether something changed.
function Store:SetNote(key, text, options)
	local player = self.data.players[key]
	if not player then
		return false
	end
	local note = Store.CleanNote(text, Store.NoteLimit(player.note))
	if note == player.note then
		return false
	end
	player.note = note
	player.noteFrom = nil -- edited: the user's own now
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

-- Deletes every player and forgets the imports. The characters stay, and with them which
-- ones were merged: their old records must not come back at the next login.
function Store:Reset()
	self.data.players = {}
	self.data.imports = {}
	for _, character in pairs(self.data.characters) do
		character.imports = {}
	end
	self:Changed()
end

-- Characters of the user ------------------------------------------------------------------------

-- The character playing now: his record is made or updated with info (class, race,
-- raceFile, sex, faction, level), and new fights and imports are his.
function Store:SetCharacter(key, info)
	assert(type(key) == "string" and key ~= "", "character key expected")
	local character = self.data.characters[key]
	if not character then
		character = { imports = {} }
		self.data.characters[key] = character
	end
	if type(info) == "table" then
		CopyInfo(character, info, false)
	end
	self.me = key
	return character
end

-- The key of the character playing now, or nil while it is not known.
function Store:CurrentCharacter()
	return self.me
end

-- The record of one of the user's characters, or nil.
function Store:Character(key)
	if key == nil then
		return nil
	end
	return self.data.characters[key]
end

-- Iterates key, character.
function Store:Characters()
	return pairs(self.data.characters)
end

-- Merge -----------------------------------------------------------------------------------------

local function NoteLabel(me)
	return "[" .. Util.DisplayName(me) .. "]"
end

-- Joins the note of another character onto the one of the account. A note only one
-- character wrote stays as it is; two different ones keep both, each under the name of
-- its character, however long that gets.
local function MergeNote(player, note, me)
	if note == nil or note == player.note then
		return
	end
	if player.note == nil then
		player.note, player.noteFrom = note, me
		return
	end
	local mine = player.note
	if player.noteFrom then
		mine = NoteLabel(player.noteFrom) .. "\n" .. mine
	end
	player.note = Store.CleanNote(mine .. "\n\n" .. NoteLabel(me) .. "\n" .. note, Store.NOTE_STORED_MAX)
	player.noteFrom = nil
end

local function SameFight(player, encounter)
	for _, other in ipairs(player.encounters) do
		if other.t == encounter.t and other.r == encounter.r and other.me == encounter.me then
			return true
		end
	end
	return false
end

local function CopyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

-- Folds one enemy of a character's record into the account record. Returns how many
-- fights it added.
local function MergePlayer(target, source, me)
	-- What is known of him comes from the record that saw him last; the other only fills gaps.
	CopyInfo(target, source, (source.last or 0) <= (target.last or 0))
	local fights = 0
	for _, encounter in ipairs(source.encounters) do
		if type(encounter) == "table" and type(encounter.t) == "number"
			and (encounter.r == Store.KILL or encounter.r == Store.DEATH) then
			local copy = CopyTable(encounter) -- the backup keeps its own
			if copy.me == nil then
				copy.me = me
			end
			if not SameFight(target, copy) then
				InsertByTime(target.encounters, copy)
				fights = fights + 1
			end
		end
	end
	Store.TouchTimes(target, source.first)
	Store.TouchTimes(target, source.last)
	AddExtra(target, me, source.extraKills, source.extraDeaths)
	MergeNote(target, source.note, me)
	Trim(target)
	return fights
end

-- Folds the record of character `me` (his PvPTallyCharDB, from before v1.6) into the
-- account record, once: it is migrated in place (his fights get his key) and stays as a
-- backup. Test data is left out. now: the time to remember the merge by. Returns
-- { players, fights } of what was added, or nil when that character was merged already.
function Store:MergeCharacter(charData, me, now)
	assert(type(me) == "string" and me ~= "", "character key expected")
	local character = self.data.characters[me] or self:SetCharacter(me)
	if character.merged then
		return nil
	end
	local result = { players = 0, fights = 0 }
	if type(charData) == "table" then
		Store.Migrate(charData, me)
		for key, source in pairs(charData.players) do
			if not source.test then
				local fresh = self.data.players[key] == nil
				local fights = MergePlayer(self:GetOrCreate(key), source, me)
				if fresh or fights > 0 then
					result.players = result.players + 1
				end
				result.fights = result.fights + fights
			end
		end
		for source, when in pairs(charData.imports) do
			if character.imports[source] == nil then
				character.imports[source] = when
			end
		end
	end
	character.merged = now or 0
	if result.players > 0 then
		self:Changed()
	end
	return result
end

-- Imports -----------------------------------------------------------------------------------------

-- Spy keeps its data per character, so each character imports his own.
local function Imports(self)
	local character = self.me and self.data.characters[self.me]
	return character and character.imports or self.data.imports
end

function Store:IsImported(source)
	return Imports(self)[source] ~= nil
end

-- When the character playing now first imported from `source`, or nil.
function Store:ImportedAt(source)
	return Imports(self)[source]
end

function Store:MarkImported(source, when)
	Imports(self)[source] = when
end
