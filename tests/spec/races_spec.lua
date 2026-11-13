local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

-- The client's race names in Spanish, as C_CreatureInfo.GetRaceInfo gives them.
local SPANISH = {
	[1] = { "Humano", "Human" }, [2] = { "Orco", "Orc" }, [3] = { "Enano", "Dwarf" },
	[4] = { "Elfo de la noche", "NightElf" }, [5] = { "No-muerto", "Scourge" }, [6] = { "Tauren", "Tauren" },
	[7] = { "Gnomo", "Gnome" }, [8] = { "Trol", "Troll" },
	[95] = { "Cielonato de la Orden Eminente", "Skyborne" }, [96] = { "Cielonato de la Orden Eminente", "Skyborne" },
}

local function raceInfo(raceID)
	local race = SPANISH[raceID]
	if race then return race[1], race[2] end
end

describe("Races", function()
	local Races, resolver, atlases
	before_each(function()
		Races = Addon.LoadWith({}).Races
		-- Every raceicon128 atlas exists except Skyborne's, plus the modern faction icons.
		atlases = function(name)
			return (name:find("^raceicon128%-") and not name:find("skyborne")) or name:find("PVP%-") ~= nil
		end
		resolver = Races.NewResolver(raceInfo, function(name) return atlases(name) and true or false end)
	end)

	it("stems the -o / -a endings", function()
		T.eq(Races.Stem("Elfa de la noche"), Races.Stem("Elfo de la noche"))
		T.eq(Races.Stem("No-muerta"), Races.Stem("No-muerto"))
		T.eq(Races.Stem("Gnoma"), "gnom")
	end)

	describe("Token", function()
		it("prefers the token read in game", function()
			T.eq({ resolver:Token({ raceFile = "Orc", sex = 3, race = "Humano" }) }, { "Orc", 3 })
		end)

		it("finds the token from the client's (male) name", function()
			T.eq({ resolver:Token({ race = "Gnomo" }) }, { "Gnome", Races.MALE })
			T.eq({ resolver:Token({ race = "elfo de la noche" }) }, { "NightElf", Races.MALE })
		end)

		it("reads a feminine ending as a woman", function()
			T.eq({ resolver:Token({ race = "Gnoma" }) }, { "Gnome", Races.FEMALE })
			T.eq({ resolver:Token({ race = "Elfa de la noche" }) }, { "NightElf", Races.FEMALE })
			T.eq({ resolver:Token({ race = "No-muerta" }) }, { "Scourge", Races.FEMALE })
		end)

		it("keeps a known sex over the guess", function()
			T.eq({ resolver:Token({ race = "Gnoma", sex = Races.MALE }) }, { "Gnome", Races.MALE })
		end)

		it("reads the feminine names of other languages", function()
			local NAMES = {
				deDE = { [3] = { "Zwerg", "Dwarf" }, [4] = { "Nachtelf", "NightElf" }, [7] = { "Gnom", "Gnome" },
					[5] = { "Untoter", "Scourge" }, [6] = { "Tauren", "Tauren" }, [28] = { "Hochbergtauren", "HighmountainTauren" },
					[27] = { "Nachtgeborener", "Nightborne" } },
				frFR = { [1] = { "Humain", "Human" }, [3] = { "Nain", "Dwarf" }, [5] = { "Mort-vivant", "Scourge" },
					[4] = { "Elfe de la nuit", "NightElf" } },
				ptBR = { [3] = { "Anão", "Dwarf" }, [4] = { "Elfo Noturno", "NightElf" }, [5] = { "Morto-vivo", "Scourge" },
					[10] = { "Elfo Sangrento", "BloodElf" } },
				ruRU = { [7] = { "Гном", "Gnome" }, [3] = { "Дворф", "Dwarf" }, [4] = { "Ночной эльф", "NightElf" },
					[10] = { "Эльф крови", "BloodElf" } },
			}
			local function resolve(locale, name)
				local names = NAMES[locale]
				local localized = Races.NewResolver(function(id)
					if names[id] then return names[id][1], names[id][2] end
				end, atlases)
				return { localized:Token({ race = name }) }
			end
			T.eq(resolve("deDE", "Zwergin"), { "Dwarf", Races.FEMALE })
			T.eq(resolve("deDE", "Nachtelfe"), { "NightElf", Races.FEMALE })
			T.eq(resolve("deDE", "Gnomin"), { "Gnome", Races.FEMALE })
			T.eq(resolve("deDE", "Untote"), { "Scourge", Races.FEMALE })
			T.eq(resolve("deDE", "Taurin"), { "Tauren", Races.FEMALE })
			T.eq(resolve("frFR", "Naine"), { "Dwarf", Races.FEMALE })
			T.eq(resolve("frFR", "Humaine"), { "Human", Races.FEMALE })
			T.eq(resolve("frFR", "Morte-vivante"), { "Scourge", Races.FEMALE })
			T.eq(resolve("frFR", "Elfe de la nuit"), { "NightElf", Races.MALE })
			T.eq(resolve("ptBR", "Anã"), { "Dwarf", Races.FEMALE })
			T.eq(resolve("ptBR", "Elfa Noturna"), { "NightElf", Races.FEMALE })
			T.eq(resolve("ptBR", "Morta-viva"), { "Scourge", Races.FEMALE })
			T.eq(resolve("ruRU", "Гномка"), { "Gnome", Races.FEMALE })
			T.eq(resolve("ruRU", "Дворфийка"), { "Dwarf", Races.FEMALE })
			T.eq(resolve("ruRU", "Ночная эльфийка"), { "NightElf", Races.FEMALE })
		end)

		it("does not guess between two races with similar names", function()
			local names = { [1] = { "Orca", "Orc" }, [2] = { "Orco", "OtherOrc" } }
			local ambiguous = Races.NewResolver(function(id)
				if names[id] then return names[id][1], names[id][2] end
			end, atlases)
			T.isNil(ambiguous:Token({ race = "Orcu" }))
		end)

		it("matches words by UTF-8 letters, not bytes", function()
			local words = Races.Words("Anã Ночная")
			T.eq(#words, 2)
			T.eq(#words[1], 3)
			T.eq(#words[2], 6)
			T.truthy(Races.SameWord(Races.Words("Zwerg")[1], Races.Words("Zwergin")[1]))
			T.falsy(Races.SameWord(Races.Words("Nachtelfe")[1], Races.Words("Nachtgeborene")[1]))
		end)

		it("tells the sex, known or guessed from the race", function()
			T.eq(resolver:Sex({ sex = Races.MALE, race = "Gnoma" }), Races.MALE)
			T.eq(resolver:Sex({ race = "Gnoma" }), Races.FEMALE)
			T.eq(resolver:Sex({ race = "Gnomo" }), Races.MALE)
			T.isNil(resolver:Sex({}))
		end)

		it("returns nil for an unknown race", function()
			T.isNil(resolver:Token({ race = "Raza rara" }))
			T.isNil(resolver:Token({}))
		end)

		it("tries again when the game had no race names yet", function()
			local ready = false
			local lateResolver = Races.NewResolver(function(id) if ready then return raceInfo(id) end end, atlases)
			T.isNil(lateResolver:Token({ race = "Gnomo" }))
			ready = true
			T.eq(lateResolver:Token({ race = "Gnomo" }), "Gnome")
		end)
	end)

	describe("Icon", function()
		it("uses the atlas for the race and sex", function()
			T.eq(resolver:Icon({ raceFile = "Gnome", sex = Races.FEMALE }), { atlas = "raceicon128-gnome-female" })
			T.eq(resolver:Icon({ race = "Humano" }), { atlas = "raceicon128-human-male" })
		end)

		it("maps tokens whose atlas has another name", function()
			T.eq(resolver:Icon({ raceFile = "Scourge", sex = Races.MALE }), { atlas = "raceicon128-undead-male" })
		end)

		it("falls back to the older raceicon atlases", function()
			atlases = function(name) return name == "raceicon-orc-female" end
			T.eq(resolver:Icon({ raceFile = "Orc", sex = Races.FEMALE }), { atlas = "raceicon-orc-female" })
		end)

		it("gives Skyborne its own icon when there is no atlas", function()
			local icon = resolver:Icon({ race = "Cielonato de la Orden Eminente" })
			T.eq(icon.file, 132845)
		end)

		it("shows a question mark for a race it cannot place", function()
			T.contains(resolver:Icon({ race = "Raza rara" }).file, "QuestionMark")
		end)

		it("shows nothing when the race is unknown", function()
			T.isNil(resolver:Icon({}))
		end)
	end)

	describe("FactionBadge", function()
		it("marks the side of a race both factions play", function()
			T.eq(resolver:FactionBadge({ raceFile = "Skyborne", faction = "Horde" }), { atlas = "UI-HUD-UnitFrame-Player-PVP-HordeIcon" })
			T.eq(resolver:FactionBadge({ raceFile = "Skyborne", faction = "Alliance" }), { atlas = "UI-HUD-UnitFrame-Player-PVP-AllianceIcon" })
		end)

		it("uses the old PvP icon when the modern atlas is missing", function()
			atlases = function() return false end
			T.contains(resolver:FactionBadge({ raceFile = "Skyborne", faction = "Horde" }).file, "UI-PVP-Horde")
		end)

		it("is not needed for single-faction races or an unknown side", function()
			T.isNil(resolver:FactionBadge({ raceFile = "Orc", faction = "Horde" }))
			T.isNil(resolver:FactionBadge({ raceFile = "Skyborne" }))
		end)
	end)

	describe("ClassIcon", function()
		local coords = { ROGUE = { 0.5, 0.74, 0, 0.25 } }
		local available
		before_each(function()
			available = {}
			resolver = Races.NewResolver(raceInfo, function(name) return available[name] == true end, coords)
		end)

		it("uses the round class atlas", function()
			available["classicon-rogue"] = true
			available["groupfinder-icon-class-rogue"] = true
			T.eq(resolver:ClassIcon("ROGUE"), { atlas = "classicon-rogue" })
		end)

		it("falls back to the group finder atlas", function()
			available["groupfinder-icon-class-rogue"] = true
			T.eq(resolver:ClassIcon("ROGUE"), { atlas = "groupfinder-icon-class-rogue" })
		end)

		it("falls back to the classic sheet when there is no atlas", function()
			T.eq(resolver:ClassIcon("ROGUE"), { file = "Interface\\WorldStateFrame\\Icons-Classes", coords = coords.ROGUE })
		end)

		it("shows a question mark for an unknown or missing class", function()
			T.contains(resolver:ClassIcon("PALADIN").file, "QuestionMark")
			T.contains(resolver:ClassIcon(nil).file, "QuestionMark")
			T.contains(resolver:ClassIcon("").file, "QuestionMark")
		end)

		it("works without the classic sheet coordinates", function()
			local plain = Races.NewResolver(raceInfo, function() return false end)
			T.contains(plain:ClassIcon("ROGUE").file, "QuestionMark")
		end)
	end)

	it("lists Skyborne for both factions", function()
		local factions = {}
		for _, race in ipairs(Races.LIST) do
			if race.token == "Skyborne" then factions[race.faction] = race.id end
		end
		T.eq(factions, { Alliance = 95, Horde = 96 })
	end)

	it("gives localized names by race ID", function()
		T.eq(resolver:Name(4), "Elfo de la noche")
		T.isNil(resolver:Name(99))
	end)
end)
