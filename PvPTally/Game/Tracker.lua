-- PvP Tally: detecting kills and deaths.
--
-- On World of Warcraft: Forever the combat log is closed to addons, so the tracker works
-- from what is still open:
--   * enemy players are read from unit tokens (nameplates, target, focus, mouseover)
--     and cached by GUID with their name, class, race, guild and level;
--   * a kill is PARTY_KILL with our GUID (or our pet's) as the attacker, or a group
--     member's (or his pet's) when we took part in the fight (see TookPart);
--   * a death is PLAYER_DEAD; the killer comes from the death recap or, when the recap
--     cannot say, from the one enemy player who had us targeted just before.
-- Only the open world counts: battlegrounds, arenas and instances are ignored.
--
-- The tracker reaches the game only through `game` (WowApi in the addon, a fake in the
-- tests) and records fights only through `store`.

local _, ns = ...
local Store = ns.Store

local Tracker = {}
Tracker.__index = Tracker
ns.Tracker = Tracker

Tracker.SCAN_INTERVAL = 1        -- seconds between two scans of the visible enemies
Tracker.TARGETING_WINDOW = 6     -- seconds before a death that "had us targeted" counts
Tracker.TARGETING_MEMORY = 60    -- seconds a targeting note is kept at all
Tracker.KILL_DEDUP = 3           -- PARTY_KILL may fire twice for one death
Tracker.PARTICIPATION_WINDOW = 10 -- seconds before a group kill that count as taking part
Tracker.CACHE_LIMIT = 3000       -- enemies remembered by GUID before starting over
Tracker.RECAP_STALE_AGE = 60     -- a recap older than this is from before a /reload
Tracker.RECAP_RETRIES = { 0.5, 1.5, 3 } -- the recap is filled in shortly after PLAYER_DEAD

-- Recap results that leave the killer open; the targeting guess runs after them.
local RECAP_UNKNOWN = { unavailable = true, unreadable = true, empty = true, stale = true, hidden = true }

function Tracker.New(game, store)
	assert(type(game) == "table", "game adapter expected")
	assert(type(store) == "table", "store expected")
	return setmetatable({
		game = game,
		store = store,
		cache = {},          -- guid -> info (with info.key)
		cacheCount = 0,
		guidByKey = {},      -- key -> guid
		targetingMe = {},    -- key -> game.Now() when he last had us targeted
		lastTargeted = {},   -- key -> game.Now() when we last had him as target or focus
		lastSeen = {},       -- key -> game.Now() when we last saw him (any unit token)
		nameplates = {},     -- "nameplateN" -> true while shown
		recentKills = {},    -- guid -> game.Now()
		lastRecapID = nil,
		lastKill = nil,      -- diagnostics for /tally debug
		lastDeath = nil,
	}, Tracker)
end

-- Enemy cache ----------------------------------------------------------------------------------

function Tracker:Remember(guid, info)
	if type(guid) ~= "string" then
		return
	end
	if not self.cache[guid] then
		if self.cacheCount >= Tracker.CACHE_LIMIT then
			self.cache, self.guidByKey, self.cacheCount = {}, {}, 0
		end
		self.cacheCount = self.cacheCount + 1
	end
	self.cache[guid] = info
	self.guidByKey[info.key] = guid
end

function Tracker:InfoForKey(key)
	local guid = self.guidByKey[key]
	return guid and self.cache[guid] or { key = key }
end

-- Reads the enemy player behind a unit token, if any. Returns his key and info.
function Tracker:Scan(unit)
	local key, fresh = self.game.ReadEnemy(unit)
	if not key then
		return nil
	end
	local info = (fresh.guid and self.cache[fresh.guid]) or {}
	for field, value in pairs(fresh) do
		info[field] = value -- what is unknown now (a skull's level) keeps the earlier value
	end
	info.key = key
	self:Remember(fresh.guid, info)
	self.lastSeen[key] = self.game.Now()
	-- Keep a known enemy's record up to date (guild, level...).
	local player = self.store:Get(key)
	if player then
		Store.UpdateInfo(player, info)
	end
	return key, info
end

function Tracker:ScanAndNote(unit)
	local key = self:Scan(unit)
	if not key then
		return nil
	end
	if unit == "target" or unit == "focus" then
		self.lastTargeted[key] = self.game.Now()
	end
	if self.game.IsTargetingPlayer(unit) then
		self.targetingMe[key] = self.game.Now()
	end
	return key
end

function Tracker:ScanVisible()
	if not self.game.IsWorldPvP() then
		return
	end
	for unit in pairs(self.nameplates) do
		if self.game.UnitExists(unit) then
			self:ScanAndNote(unit)
		else
			self.nameplates[unit] = nil
		end
	end
	self:ScanAndNote("target")
	self:ScanAndNote("focus")
	self:Prune(self.game.Now())
end

function Tracker:Prune(now)
	for _, notes in ipairs({ self.targetingMe, self.lastTargeted, self.lastSeen }) do
		for key, when in pairs(notes) do
			if now - when > Tracker.TARGETING_MEMORY then notes[key] = nil end
		end
	end
	for guid, when in pairs(self.recentKills) do
		if now - when > Tracker.KILL_DEDUP * 10 then self.recentKills[guid] = nil end
	end
end

-- GUID -> player ---------------------------------------------------------------------------------

-- The key already in use for a name given by another API: "First-Last", "First Last",
-- or a bare first name that matches one single known enemy. nil when unknown.
function Tracker:KnownKey(name, realm)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local function known(key)
		return self.store:Get(key) ~= nil or self.guidByKey[key] ~= nil
	end
	local candidates = {}
	if type(realm) == "string" and realm ~= "" then
		candidates[#candidates + 1] = name .. "-" .. realm
		candidates[#candidates + 1] = name .. "-" .. realm:gsub("%s", "")
	end
	candidates[#candidates + 1] = name
	candidates[#candidates + 1] = (name:gsub("%s+", "-"))
	for _, key in ipairs(candidates) do
		if known(key) then
			return key
		end
	end

	local first = name:match("^([^%s%-]+)")
	if not first then
		return nil
	end
	local prefix = first:lower() .. "-"
	local found
	local function check(key)
		if key ~= found and key:lower():sub(1, #prefix) == prefix then
			if found then
				return false -- two players share this first name: no guess
			end
			found = key
		end
		return true
	end
	for key in pairs(self.guidByKey) do
		if not check(key) then return nil end
	end
	for key in self.store:Players() do
		if not check(key) then return nil end
	end
	return found
end

-- The key and info of the player behind a GUID, or nil.
function Tracker:ResolveGUID(guid)
	if type(guid) ~= "string" or not guid:find("^Player%-") then
		return nil
	end
	local cached = self.cache[guid]
	if cached then
		return cached.key, cached
	end
	local byGUID = self.game.PlayerInfoByGUID(guid)
	if not byGUID then
		return nil
	end
	local key = self:KnownKey(byGUID.name, byGUID.realm)
	if not key then
		key = (type(byGUID.realm) == "string" and byGUID.realm ~= "") and (byGUID.name .. "-" .. byGUID.realm) or byGUID.name
	end
	local info = { key = key, class = byGUID.class, race = byGUID.race, raceFile = byGUID.raceFile, sex = byGUID.sex }
	local player = self.store:Get(key)
	if player then
		info.level = player.level
	end
	return key, info
end

-- Recording ---------------------------------------------------------------------------------------

local function NewEncounter(result, context, info, how)
	return {
		t = context.t,
		r = result,
		zone = context.zone,
		subZone = context.subZone,
		mapID = context.mapID,
		x = context.x,
		y = context.y,
		oppLevel = info and type(info.level) == "number" and info.level > 0 and info.level or nil,
		myLevel = context.myLevel,
		how = how,
	}
end

-- Kills --------------------------------------------------------------------------------------------

-- Whether we took part in the fight against an enemy in the last seconds: we had him as
-- target or focus, he had us targeted, or we were in combat with him in sight (a healer
-- rarely targets the enemy). Returns true and how, or false.
function Tracker:TookPart(key, now)
	local function recent(when)
		return when ~= nil and now - when <= Tracker.PARTICIPATION_WINDOW
	end
	if recent(self.lastTargeted[key]) then
		return true, "targeted"
	end
	if recent(self.targetingMe[key]) then
		return true, "targeting us"
	end
	if recent(self.lastSeen[key]) and self.game.InCombat() then
		return true, "in combat, in sight"
	end
	return false
end

-- Whose kill this is: "kill" (ours or our pet's), "group" (a group member's or his pet's),
-- or nil.
function Tracker:KillerKind(attackerGUID)
	local playerGUID, petGUID = self.game.OwnGUIDs()
	if attackerGUID == playerGUID or (petGUID ~= nil and attackerGUID == petGUID) then
		return "kill"
	end
	if self.game.IsGroupGUID(attackerGUID) then
		return "group"
	end
	return nil
end

function Tracker:OnPartyKill(attackerGUID, targetGUID)
	if not self.game.IsWorldPvP() then
		return
	end
	local seen = { when = self.game.Time() }
	self.lastKill = seen
	if type(attackerGUID) ~= "string" then
		seen.result = "killer hidden"
		return
	end
	local how = self:KillerKind(attackerGUID)
	if not how then
		seen.result = "not our group's kill"
		return
	end
	local key, info = self:ResolveGUID(targetGUID)
	if not key then
		seen.result = "victim is not a known player"
		return
	end
	local now = self.game.Now()
	if how == "group" then
		local tookPart, why = self:TookPart(key, now)
		if not tookPart then
			seen.result = "group kill of " .. key .. ", we did not take part"
			return
		end
		seen.why = why
	end
	if self.recentKills[targetGUID] and now - self.recentKills[targetGUID] < Tracker.KILL_DEDUP then
		seen.result = "duplicate"
		return
	end
	self.recentKills[targetGUID] = now
	seen.result = how .. ": " .. key .. (seen.why and (" (" .. seen.why .. ")") or "")
	self.store:AddEncounter(key, NewEncounter(Store.KILL, self.game.CurrentContext(), info, how), info)
end

-- Deaths -------------------------------------------------------------------------------------------

-- The killing blow of the latest recap. Returns key, info, how; or nil, nil, why not.
function Tracker:KillerFromRecap()
	local recap, why = self.game.DeathRecap()
	if not recap then
		return nil, nil, why
	end
	if recap.id and recap.id == self.lastRecapID then
		return nil, nil, "stale" -- still the recap of an earlier death
	end
	local stamp = recap.timestamp
	if type(stamp) == "number" and stamp > 1000000000 and math.abs(self.game.Time() - stamp) > Tracker.RECAP_STALE_AGE then
		return nil, nil, "stale"
	end
	self.lastRecapID = recap.id
	if recap.hideCaster then
		return nil, nil, "hidden"
	end
	local key, info = self:ResolveGUID(recap.sourceGUID)
	if not key and type(recap.sourceName) == "string" and type(recap.sourceGUID) == "string"
		and recap.sourceGUID:find("^Player%-") then
		key = self:KnownKey(recap.sourceName) or (recap.sourceName:gsub("%s+", "-"))
		info = self:InfoForKey(key)
	end
	if key then
		return key, info, "recap"
	end
	return nil, nil, "no player"
end

-- The enemies who had us targeted in the last seconds.
function Tracker:Suspects(now)
	local suspects = {}
	for key, when in pairs(self.targetingMe) do
		if now - when <= Tracker.TARGETING_WINDOW then
			suspects[#suspects + 1] = key
		end
	end
	table.sort(suspects)
	return suspects
end

function Tracker:ResolveDeath(context, suspects, attempt)
	local key, info, how = self:KillerFromRecap()
	local retries = Tracker.RECAP_RETRIES
	if not key and how == "stale" and attempt < #retries then
		self.game.After(retries[attempt + 1] - retries[attempt], ns.Util.Guard("ResolveDeath", function()
			self:ResolveDeath(context, suspects, attempt + 1)
		end))
		return
	end
	if not key and RECAP_UNKNOWN[how] then
		if #suspects == 1 then
			key, info, how = suspects[1], self:InfoForKey(suspects[1]), "targeting"
		else
			how = (#suspects > 1 and "several enemies targeting" or "nobody targeting") .. " (recap: " .. how .. ")"
		end
	end
	self.lastDeath = { when = self.game.Time(), result = key and (how .. ": " .. key) or how }
	if key then
		self.store:AddEncounter(key, NewEncounter(Store.DEATH, context, info, how), info)
	end
end

function Tracker:OnPlayerDead()
	if not self.game.IsWorldPvP() then
		return
	end
	-- Taken now: the recap is read a moment later, maybe after releasing the spirit.
	local context = self.game.CurrentContext()
	local suspects = self:Suspects(self.game.Now())
	self.game.After(Tracker.RECAP_RETRIES[1], ns.Util.Guard("ResolveDeath", function()
		self:ResolveDeath(context, suspects, 1)
	end))
end

-- Events -------------------------------------------------------------------------------------------

local function IsWatchedUnit(unit)
	return type(unit) == "string"
		and (unit == "target" or unit == "focus" or unit == "mouseover" or unit:find("^nameplate%d+$") ~= nil)
end

local HANDLERS = {
	NAME_PLATE_UNIT_ADDED = function(self, unit)
		if type(unit) == "string" then
			self.nameplates[unit] = true
			if self.game.IsWorldPvP() then self:ScanAndNote(unit) end
		end
	end,
	NAME_PLATE_UNIT_REMOVED = function(self, unit)
		if type(unit) == "string" then self.nameplates[unit] = nil end
	end,
	PLAYER_TARGET_CHANGED = function(self) self:ScanAndNote("target") end,
	PLAYER_FOCUS_CHANGED = function(self) self:ScanAndNote("focus") end,
	UPDATE_MOUSEOVER_UNIT = function(self) self:Scan("mouseover") end,
	UNIT_TARGET = function(self, unit)
		if IsWatchedUnit(unit) and self.game.IsWorldPvP() then self:ScanAndNote(unit) end
	end,
	UNIT_SPELLCAST_SUCCEEDED = function(self, unit)
		if IsWatchedUnit(unit) and self.game.IsWorldPvP() then self:ScanAndNote(unit) end
	end,
	PARTY_KILL = function(self, attackerGUID, targetGUID)
		self:OnPartyKill(ns.Util.Readable(attackerGUID), ns.Util.Readable(targetGUID))
	end,
	PLAYER_DEAD = function(self) self:OnPlayerDead() end,
}

-- The game events the tracker listens to.
Tracker.EVENTS = {}
for event in pairs(HANDLERS) do
	Tracker.EVENTS[#Tracker.EVENTS + 1] = event
end
table.sort(Tracker.EVENTS)

function Tracker:HandleEvent(event, ...)
	local handler = HANDLERS[event]
	if handler then
		handler(self, ...)
	end
end
