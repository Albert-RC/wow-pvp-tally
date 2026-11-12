-- PvP Tally: what the table shows. Pure logic, no widgets: filters, sorts and flattens
-- the store into the rows of the list.
--
-- Row kinds:
--   player  one enemy player              { key, player, name, kills, deaths, first, index }
--   header  titles above his fights       { key }
--   fight   one fight                     { key, player, encounter }
--   extra   fights counted w/o details    { key, kills, deaths }

local _, ns = ...
local Util, Store = ns.Util, ns.Store

local ListModel = {}
ns.ListModel = ListModel

ListModel.DEFAULT_SORT = "first"

-- Text columns read best A to Z, numbers and dates biggest first.
local ASCENDING_FIRST = { name = true, race = true, guild = true }

function ListModel.DefaultAscending(sortKey)
	return ASCENDING_FIRST[sortKey] == true
end

local function Contains(text, filter)
	return type(text) == "string" and text:lower():find(filter, 1, true) ~= nil
end

-- Whether a player matches the search box: name, guild or any zone he was fought in.
function ListModel.Matches(item, filter)
	if filter == "" then
		return true
	end
	local player = item.player
	if Contains(item.name, filter) or Contains(player.guild, filter) or Contains(player.lastZone, filter) then
		return true
	end
	for _, encounter in ipairs(player.encounters) do
		if Contains(encounter.zone, filter) or Contains(encounter.subZone, filter) then
			return true
		end
	end
	return false
end

local SORT_VALUES = {
	name = function(item) return item.name:lower() end,
	race = function(item) return (item.player.race or "~"):lower() end,
	level = function(item) return item.player.level or 0 end,
	guild = function(item) return (item.player.guild or "~"):lower() end,
	kills = function(item) return item.kills end,
	deaths = function(item) return item.deaths end,
	first = function(item) return item.first or 0 end,
}

function ListModel.SortValue(item, sortKey)
	return (SORT_VALUES[sortKey] or SORT_VALUES.first)(item)
end

local function NewestFirst(a, b)
	return (a.t or 0) > (b.t or 0)
end

-- options: { filter = text, sortKey, ascending, expanded = { [key] = true } }.
-- Returns rows, totals { players, kills, deaths } of what is shown, and the player count.
function ListModel.Build(store, options)
	options = options or {}
	local filter = Util.Trim(options.filter or ""):lower()
	local sortKey = options.sortKey or ListModel.DEFAULT_SORT
	local ascending = options.ascending == true
	local expanded = options.expanded or {}

	local items = {}
	local totals = { players = 0, kills = 0, deaths = 0 }
	for key, player in store:Players() do
		local kills, deaths = Store.Counts(player)
		if kills + deaths > 0 then
			local item = {
				kind = "player", key = key, player = player, name = Util.DisplayName(key),
				kills = kills, deaths = deaths, first = player.first,
			}
			if ListModel.Matches(item, filter) then
				items[#items + 1] = item
				totals.players = totals.players + 1
				totals.kills = totals.kills + kills
				totals.deaths = totals.deaths + deaths
			end
		end
	end

	table.sort(items, function(a, b)
		local va, vb = ListModel.SortValue(a, sortKey), ListModel.SortValue(b, sortKey)
		if va == vb then
			return a.name:lower() < b.name:lower()
		end
		if ascending then
			return va < vb
		end
		return va > vb
	end)

	local rows = {}
	for index, item in ipairs(items) do
		item.index = index
		rows[#rows + 1] = item
		if expanded[item.key] then
			rows[#rows + 1] = { kind = "header", key = item.key }
			local fights = {}
			for i, encounter in ipairs(item.player.encounters) do
				fights[i] = encounter
			end
			table.sort(fights, NewestFirst)
			for _, encounter in ipairs(fights) do
				rows[#rows + 1] = { kind = "fight", key = item.key, player = item.player, encounter = encounter }
			end
			local extraKills, extraDeaths = item.player.extraKills or 0, item.player.extraDeaths or 0
			if extraKills + extraDeaths > 0 then
				rows[#rows + 1] = { kind = "extra", key = item.key, kills = extraKills, deaths = extraDeaths }
			end
		end
	end
	return rows, totals, #items
end

-- Kills per death as shown in the summary.
function ListModel.Ratio(kills, deaths)
	if deaths == 0 then
		return kills > 0 and tostring(kills) or "-"
	end
	return ("%.2f"):format(kills / deaths)
end

-- "Zone - Sub-zone", or whichever is known.
function ListModel.ZoneText(encounter)
	if encounter.zone and encounter.subZone then
		return encounter.zone .. " - " .. encounter.subZone
	end
	return encounter.zone or encounter.subZone or "-"
end

function ListModel.LevelText(level)
	if type(level) == "number" and level > 0 then
		return tostring(level)
	end
	return ns.L.UNKNOWN_LEVEL
end
