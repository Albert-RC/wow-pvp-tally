-- PvP Tally: the game adapter. The only module that reads the WoW API (outside the UI
-- widgets). Every value goes through Util.Readable, so callers never see a secret.
--
-- The tracker depends on this interface, not on the API itself, which lets the tests
-- hand it a fake game.

local _, ns = ...
local R = ns.Util.Readable

local WowApi = {}
ns.WowApi = WowApi

-- Time and timers ----------------------------------------------------------------------------

function WowApi.Now()
	return GetTime()
end

function WowApi.Time()
	return time()
end

function WowApi.After(delay, callback)
	C_Timer.After(delay, callback)
end

function WowApi.NewTicker(interval, callback)
	return C_Timer.NewTicker(interval, callback)
end

-- Whether we are in combat (protected UI, such as the Options window, is locked then).
function WowApi.InCombat()
	return R(InCombatLockdown()) == true
end

-- Units -------------------------------------------------------------------------------------------

function WowApi.UnitExists(unit)
	return R(UnitExists(unit)) == true
end

-- "Name" or "Name-Surname" (Forever puts the surname where Classic had the realm).
function WowApi.PlayerKey(unit)
	if not WowApi.UnitExists(unit) or not R(UnitIsPlayer(unit)) then
		return nil
	end
	local name, realm = UnitName(unit)
	name, realm = R(name), R(realm)
	if type(name) ~= "string" or name == "" or name == UNKNOWNOBJECT then
		return nil
	end
	if type(realm) == "string" and realm ~= "" then
		name = name .. "-" .. realm
	end
	return name
end

-- An enemy player behind a unit token: key and { guid, class, race, raceFile, sex, guild,
-- faction, level }. nil for anything else. level is nil for a skull (??).
function WowApi.ReadEnemy(unit)
	local key = WowApi.PlayerKey(unit)
	if not key or not R(UnitIsEnemy("player", unit)) then
		return nil
	end
	local _, class = UnitClass(unit)
	local race, raceFile = UnitRace(unit)
	local level = tonumber(R(UnitLevel(unit)))
	return key, {
		guid = R(UnitGUID(unit)),
		class = R(class),
		race = R(race),
		raceFile = R(raceFile),
		sex = tonumber(R(UnitSex(unit))),
		guild = R((GetGuildInfo(unit))),
		faction = R((UnitFactionGroup(unit))),
		level = level and level > 0 and level or nil,
	}
end

function WowApi.IsTargetingPlayer(unit)
	local ok, same = pcall(UnitIsUnit, unit .. "target", "player")
	return ok and R(same) == true
end

-- Our GUID and our pet's (nil when there is none).
function WowApi.OwnGUIDs()
	return R(UnitGUID("player")), R(UnitGUID("pet"))
end

-- What the client tells of a player GUID: { name, realm, class, race, raceFile, sex }.
function WowApi.PlayerInfoByGUID(guid)
	local ok, _, class, race, raceFile, sex, name, realm = pcall(GetPlayerInfoByGUID, guid)
	if not ok then
		return nil
	end
	name = R(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return { name = name, realm = R(realm), class = R(class), race = R(race), raceFile = R(raceFile), sex = tonumber(R(sex)) }
end

-- Where we are --------------------------------------------------------------------------------------

-- The open world: not a battleground, arena, dungeon or raid.
function WowApi.IsWorldPvP()
	local inInstance, instanceType = IsInInstance()
	return not (R(inInstance) and R(instanceType) ~= "none")
end

local function MapPosition(mapID)
	local ok, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
	if not ok or type(position) ~= "table" or not position.GetXY then
		return nil
	end
	local x, y = position:GetXY()
	x, y = R(x), R(y)
	if type(x) ~= "number" or type(y) ~= "number" or x <= 0 or y <= 0 or x >= 1 or y >= 1 then
		return nil
	end
	return math.floor(x * 10000 + 0.5) / 10000, math.floor(y * 10000 + 0.5) / 10000
end

-- Where and when we are right now, and our level: the context of a fight.
function WowApi.CurrentContext()
	local context = {
		t = time(),
		zone = R(GetZoneText()),
		subZone = R(GetSubZoneText()),
		myLevel = tonumber(R(UnitLevel("player"))),
	}
	if context.zone == "" then context.zone = nil end
	if context.subZone == "" or context.subZone == context.zone then context.subZone = nil end
	local mapID = C_Map and C_Map.GetBestMapForUnit and R(C_Map.GetBestMapForUnit("player"))
	if type(mapID) == "number" then
		context.mapID = mapID
		context.x, context.y = MapPosition(mapID)
	end
	return context
end

function WowApi.MapName(mapID)
	if type(mapID) ~= "number" or not (C_Map and C_Map.GetMapInfo) then
		return nil
	end
	local ok, info = pcall(C_Map.GetMapInfo, mapID)
	if ok and type(info) == "table" then
		return R(info.name)
	end
	return nil
end

-- Death recap -------------------------------------------------------------------------------------

-- The killing blow of the latest death recap: { id, timestamp, sourceGUID, sourceName,
-- hideCaster }, or nil and why ("unavailable", "unreadable", "empty").
function WowApi.DeathRecap()
	if not (C_DeathRecap and C_DeathRecap.GetRecapEvents) then
		return nil, "unavailable"
	end
	local id
	if C_DeathRecap.GetRecapLink then
		local ok, link = pcall(C_DeathRecap.GetRecapLink)
		link = ok and R(link)
		if type(link) == "string" then
			id = tonumber(link:match("death:(%d+)"))
		end
	end
	local ok, events = pcall(C_DeathRecap.GetRecapEvents)
	if not ok or type(events) ~= "table" or ns.Util.IsSecretTable(events) then
		return nil, "unreadable"
	end
	local event = events[1]
	if type(event) ~= "table" or ns.Util.IsSecretTable(event) then
		return nil, "empty"
	end
	return {
		id = id,
		timestamp = R(event.timestamp),
		sourceGUID = R(event.sourceGUID),
		sourceName = R(event.sourceName),
		hideCaster = R(event.hideCaster) and true or false,
	}
end

-- Races ----------------------------------------------------------------------------------------------

-- Localized name and token of a race ID, for Races.NewResolver.
function WowApi.RaceInfo(raceID)
	if not (C_CreatureInfo and C_CreatureInfo.GetRaceInfo) then
		return nil
	end
	local ok, info = pcall(C_CreatureInfo.GetRaceInfo, raceID)
	if ok and type(info) == "table" then
		return R(info.raceName), R(info.clientFileString)
	end
	return nil
end

function WowApi.AtlasExists(atlas)
	return C_Texture ~= nil and C_Texture.GetAtlasInfo ~= nil and C_Texture.GetAtlasInfo(atlas) ~= nil
end
