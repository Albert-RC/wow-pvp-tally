-- PvP Tally: importing what Spy recorded.
--
-- This is NOT a dependency on Spy: PvP Tally never calls Spy's code. When Spy happens to
-- be enabled, the game loads its saved variables (SpyPerCharDB) like any other global
-- table, and this module reads that table. Without Spy, the import is simply not offered.
--
-- Spy keeps, per character:
--   PlayerData[name] = { class, race, guild, faction, level, isGuess, isEnemy, zone, time,
--                        wins, loses, ... }
--   Encounters = { { t, n = name, r = "W"|"L"|"P", k = "kill"|"group"|"probable"|...,
--                    c = class, l = level, g = guild, m = mapID, x, y }, ... }  (Forever port)
--
-- Every own kill ("W" + "kill") and every loss ("L") in Encounters becomes a fight with
-- details. Group kills and probable wins are left out. Wins and losses Spy counted with
-- no Encounters entry are added as counts without details. Running it again is safe:
-- fights already recorded are skipped and counts only go up to what Spy says.

local _, ns = ...
local Store = ns.Store

local SpyImport = {}
ns.SpyImport = SpyImport

SpyImport.SOURCE = "spy"

-- Spy's saved data for this character, when the game loaded it; nil otherwise.
function SpyImport.ReadSavedData()
	local data = _G.SpyPerCharDB
	if type(data) == "table" and type(data.PlayerData) == "table" then
		return data
	end
	return nil
end

function SpyImport.IsAvailable()
	return SpyImport.ReadSavedData() ~= nil
end

local function PlayerInfo(data)
	if type(data) ~= "table" then
		return nil
	end
	return {
		class = data.class,
		race = data.race,
		guild = data.guild,
		faction = data.faction,
		lastZone = data.zone,
		level = data.isGuess == false and tonumber(data.level) or nil,
	}
end

local function ResultOf(entry)
	if entry.r == "W" and (entry.k == nil or entry.k == "kill") then
		return Store.KILL
	elseif entry.r == "L" then
		return Store.DEATH
	end
	return nil
end

-- Imports spyData into store. mapName(mapID) gives zone names; now is the import time.
-- Returns { found, players, fights }: whether there was Spy data, how many players got
-- something new, how many fights with details were added.
function SpyImport.Run(store, spyData, mapName, now)
	local result = { found = false, players = 0, fights = 0 }
	if type(spyData) ~= "table" or type(spyData.PlayerData) ~= "table" then
		return result
	end
	result.found = true
	local playerData = spyData.PlayerData
	local touched = {}
	local function touch(key)
		if not touched[key] then
			touched[key] = true
			result.players = result.players + 1
		end
	end

	-- Fights with details.
	local encounters = type(spyData.Encounters) == "table" and spyData.Encounters or {}
	for _, entry in ipairs(encounters) do
		local valid = type(entry) == "table" and type(entry.n) == "string" and entry.n ~= "" and type(entry.t) == "number"
		local fightResult = valid and ResultOf(entry)
		if fightResult then
			local info = PlayerInfo(playerData[entry.n]) or {}
			info.class = info.class or entry.c
			info.guild = info.guild or entry.g
			local player = store:Get(entry.n)
			if not (player and Store.HasEncounterNear(player, fightResult, entry.t)) then
				store:AddEncounter(entry.n, {
					t = entry.t,
					r = fightResult,
					zone = mapName and mapName(entry.m) or nil,
					mapID = entry.m,
					x = entry.x,
					y = entry.y,
					oppLevel = tonumber(entry.l),
					how = SpyImport.SOURCE,
				}, info, { silent = true })
				result.fights = result.fights + 1
				touch(entry.n)
			end
		end
	end

	-- Counts Spy has without the details.
	for name, data in pairs(playerData) do
		if type(name) == "string" and name ~= "" and type(data) == "table" and data.isEnemy ~= false then
			local wins, losses = tonumber(data.wins) or 0, tonumber(data.loses) or 0
			if wins > 0 or losses > 0 then
				local player = store:GetOrCreate(name)
				Store.UpdateInfo(player, PlayerInfo(data))
				if store:EnsureTotals(name, wins, losses) then
					touch(name)
				end
				if not player.last then
					Store.TouchTimes(player, tonumber(data.time))
				end
			end
		end
	end

	store:MarkImported(SpyImport.SOURCE, now)
	if result.players > 0 then
		store:Changed()
	end
	return result
end
