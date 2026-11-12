-- PvP Tally: races, and the icons of a player's race, faction and class.
--
-- A race icon comes from the race token ("Gnome", "Scourge", "Skyborne"...) and the sex,
-- as the client's "raceicon" atlases are named. Players read in game carry both. Players
-- imported from Spy only have the localized race name, often feminine ("Gnoma", "Elfa
-- de la noche"), so the token is looked up from the client's own race names, ignoring
-- the -o / -a endings.
--
-- Class icons use the modern class atlases, with the classic Icons-Classes sheet as a
-- fallback. On Forever both show the same art: each class drawn as its signature weapon
-- (a staff for priests, a bow for hunters...). That is Forever's look, not a bug.
--
-- Pure logic: the game is reached through the functions given to NewResolver, and icons
-- are returned as descriptors ({ atlas } or { file, coords }) for the UI to draw.

local _, ns = ...

local Races = {}
ns.Races = Races

Races.MALE = 2
Races.FEMALE = 3
Races.MAX_RACE_ID = 128

-- The playable races of Forever. Skyborne, Forever's own race, can be Alliance (95) or
-- Horde (96).
Races.LIST = {
	{ id = 1,  token = "Human",    faction = "Alliance" },
	{ id = 3,  token = "Dwarf",    faction = "Alliance" },
	{ id = 4,  token = "NightElf", faction = "Alliance" },
	{ id = 7,  token = "Gnome",    faction = "Alliance" },
	{ id = 95, token = "Skyborne", faction = "Alliance" },
	{ id = 2,  token = "Orc",      faction = "Horde" },
	{ id = 5,  token = "Scourge",  faction = "Horde" },
	{ id = 6,  token = "Tauren",   faction = "Horde" },
	{ id = 8,  token = "Troll",    faction = "Horde" },
	{ id = 96, token = "Skyborne", faction = "Horde" },
}

-- Races both factions can play: the race icon alone does not tell the side.
local BOTH_FACTIONS = { skyborne = true, pandaren = true }

-- Tokens whose atlas has another name.
local ATLAS_NAMES = {
	scourge = "undead",
	zandalaritroll = "zandalari",
	highmountaintauren = "highmountain",
	lightforgeddraenei = "lightforged",
	earthendwarf = "earthen",
	harronir = "haranir",
}

local ICON_COORDS = { 0.07, 0.93, 0.07, 0.93 } -- trims the border of an inventory icon

-- Races with no raceicon atlas get an icon instead.
local FALLBACK_ICONS = {
	skyborne = 132845,
}

local UNKNOWN_ICON = { file = "Interface\\Icons\\INV_Misc_QuestionMark", coords = ICON_COORDS }

-- The classic sheet of class icons, cut with CLASS_ICON_TCOORDS (last fallback).
local CLASS_ICON_SHEET = "Interface\\WorldStateFrame\\Icons-Classes"

local FACTION_BADGES = {
	Alliance = { atlas = "UI-HUD-UnitFrame-Player-PVP-AllianceIcon", file = "Interface\\TargetingFrame\\UI-PVP-Alliance" },
	Horde = { atlas = "UI-HUD-UnitFrame-Player-PVP-HordeIcon", file = "Interface\\TargetingFrame\\UI-PVP-Horde" },
}
-- The old target frame PvP icons have the emblem in the top left of the file.
local OLD_BADGE_COORDS = { 0, 0.62, 0, 0.62 }

-- "Elfa de la noche" and "Elfo de la noche" -> "elf de l noche"
function Races.Stem(name)
	return (name:lower():gsub("%S+", function(word)
		return (word:gsub("[ao]$", ""))
	end))
end

-- Resolver ------------------------------------------------------------------------------------

local Resolver = {}
Resolver.__index = Resolver

-- getRaceInfo(raceID) -> localized name, token (or nil). atlasExists(name) -> boolean.
-- classIconCoords: optional { CLASS = { left, right, top, bottom } } in the classic class
-- icon sheet (CLASS_ICON_TCOORDS), the last fallback for class icons.
function Races.NewResolver(getRaceInfo, atlasExists, classIconCoords)
	assert(type(getRaceInfo) == "function", "getRaceInfo function expected")
	assert(type(atlasExists) == "function", "atlasExists function expected")
	return setmetatable({
		getRaceInfo = getRaceInfo,
		atlasExists = atlasExists,
		classIconCoords = type(classIconCoords) == "table" and classIconCoords or {},
	}, Resolver)
end

-- Localized name -> token, built once. Not kept when empty (the game may not be ready
-- yet), so a later call tries again.
function Resolver:Index()
	if self.index then
		return self.index
	end
	local index, found = {}, false
	for raceID = 1, Races.MAX_RACE_ID do
		local name, token = self.getRaceInfo(raceID)
		if type(name) == "string" and name ~= "" and type(token) == "string" and token ~= "" then
			found = true
			index[name:lower()] = index[name:lower()] or { token = token, exact = true }
			local stem = Races.Stem(name)
			index[stem] = index[stem] or { token = token }
		end
	end
	if found then
		self.index = index
	end
	return index
end

-- The localized name of a race ID, or nil.
function Resolver:Name(raceID)
	local name = self.getRaceInfo(raceID)
	if type(name) == "string" and name ~= "" then
		return name
	end
	return nil
end

-- Token and sex of a player's race, or nil when unknown. With only a localized name,
-- the client's spelling means male and another ending (Gnoma for Gnomo) female.
function Resolver:Token(player)
	if type(player.raceFile) == "string" and player.raceFile ~= "" then
		return player.raceFile, player.sex
	end
	if type(player.race) ~= "string" or player.race == "" then
		return nil
	end
	local index = self:Index()
	local found = index[player.race:lower()]
	if found then
		return found.token, player.sex or Races.MALE
	end
	found = index[Races.Stem(player.race)]
	if found then
		return found.token, player.sex or Races.FEMALE
	end
	return nil
end

function Resolver:HasBothFactions(player)
	local token = self:Token(player)
	return token ~= nil and BOTH_FACTIONS[token:lower()] == true
end

-- The icon of a player's race: { atlas = name } or { file = path or ID, coords = {...} }.
-- nil when nothing at all is known of his race.
function Resolver:Icon(player)
	local token, sex = self:Token(player)
	if token then
		local key = token:lower()
		local race = ATLAS_NAMES[key] or key
		local genders = { sex == Races.FEMALE and "female" or "male", "male", "female" }
		for _, prefix in ipairs({ "raceicon128", "raceicon" }) do
			for _, gender in ipairs(genders) do
				local atlas = prefix .. "-" .. race .. "-" .. gender
				if self.atlasExists(atlas) then
					return { atlas = atlas }
				end
			end
		end
		if FALLBACK_ICONS[key] then
			return { file = FALLBACK_ICONS[key], coords = ICON_COORDS }
		end
	end
	if player.race or player.raceFile then
		return UNKNOWN_ICON
	end
	return nil
end

-- The icon of a class token ("ROGUE"): the round class atlas, the flat group finder one,
-- the classic sheet, or a question mark. Always returns a descriptor.
function Resolver:ClassIcon(class)
	if type(class) == "string" and class ~= "" then
		local key = class:lower()
		for _, atlas in ipairs({ "classicon-" .. key, "groupfinder-icon-class-" .. key }) do
			if self.atlasExists(atlas) then
				return { atlas = atlas }
			end
		end
		local coords = self.classIconCoords[class]
		if type(coords) == "table" then
			return { file = CLASS_ICON_SHEET, coords = coords }
		end
	end
	return UNKNOWN_ICON
end

-- A faction badge for a race both factions can play, or nil when none is needed.
function Resolver:FactionBadge(player)
	local badge = FACTION_BADGES[player.faction]
	if not badge or not self:HasBothFactions(player) then
		return nil
	end
	if self.atlasExists(badge.atlas) then
		return { atlas = badge.atlas }
	end
	return { file = badge.file, coords = OLD_BADGE_COORDS }
end
