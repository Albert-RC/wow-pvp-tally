local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("WowApi", function()
	local ns, env, Api
	local units
	before_each(function()
		ns, env = Addon.LoadWith({ "Game/WowApi.lua" })
		Api = ns.WowApi
		units = {
			target = { name = "Kane", realm = "Mochivich", enemy = true, guid = "Player-1-AAA", class = "WARLOCK",
				race = "Humano", raceFile = "Human", sex = 2, level = 25, guild = "Selecció Natural", faction = "Alliance" },
			focus = { name = "Ally", realm = "", enemy = false },
		}
		env.UnitExists = function(unit) return units[unit] ~= nil end
		env.UnitIsPlayer = function(unit) return units[unit] ~= nil end
		env.UnitName = function(unit) return units[unit].name, units[unit].realm end
		env.UnitIsEnemy = function(_, unit) return units[unit].enemy end
		env.UnitGUID = function(unit) return units[unit] and units[unit].guid end
		env.UnitClass = function(unit) return "Brujo", units[unit].class end
		env.UnitRace = function(unit) return units[unit].race, units[unit].raceFile end
		env.UnitSex = function(unit) return units[unit].sex end
		env.UnitLevel = function(unit) return units[unit] and units[unit].level or 0 end
		env.GetGuildInfo = function(unit) return units[unit].guild end
		env.UnitFactionGroup = function(unit) return units[unit].faction end
	end)

	describe("ReadEnemy", function()
		it("reads an enemy player", function()
			local key, info = Api.ReadEnemy("target")
			T.eq(key, "Kane-Mochivich")
			T.eq(info, {
				guid = "Player-1-AAA", class = "WARLOCK", race = "Humano", raceFile = "Human", sex = 2,
				guild = "Selecció Natural", faction = "Alliance", level = 25,
			})
		end)

		it("ignores friendly players and empty units", function()
			T.isNil(Api.ReadEnemy("focus"))
			T.isNil(Api.ReadEnemy("mouseover"))
		end)

		it("leaves the level out for a skull", function()
			units.target.level = -1
			local _, info = Api.ReadEnemy("target")
			T.isNil(info.level)
		end)

		it("never hands out a secret value", function()
			units.target.guild = env.Secret("hidden guild")
			units.target.level = env.Secret(25)
			local _, info = Api.ReadEnemy("target")
			T.isNil(info.guild)
			T.isNil(info.level)
		end)

		it("gives up on a secret name", function()
			units.target.name = env.Secret("Kane")
			T.isNil(Api.ReadEnemy("target"))
		end)
	end)

	describe("ReadPlayer", function()
		it("reads friendly players too", function()
			local key, info = Api.ReadPlayer("focus")
			T.eq(key, "Ally")
			T.notNil(info)
			T.eq(Api.ReadPlayer("target"), "Kane-Mochivich")
			T.isNil(Api.ReadPlayer("mouseover"))
		end)
	end)

	describe("IsWorldPvP", function()
		it("is true in the open world", function()
			T.truthy(Api.IsWorldPvP())
		end)

		it("is false in battlegrounds, arenas and dungeons", function()
			for _, kind in ipairs({ "pvp", "arena", "party", "raid" }) do
				env.IsInInstance = function() return true, kind end
				T.falsy(Api.IsWorldPvP(), kind)
			end
		end)
	end)

	describe("CurrentContext", function()
		it("reads zone, position and level", function()
			env.GetZoneText = function() return "Los Baldíos" end
			env.GetSubZoneText = function() return "El Cruce" end
			env.C_Map.GetBestMapForUnit = function() return 1413 end
			env.C_Map.GetPlayerMapPosition = function() return { GetXY = function() return 0.51234, 0.30201 end } end
			units.player = { level = 30 }
			local context = Api.CurrentContext()
			T.eq(context.zone, "Los Baldíos")
			T.eq(context.subZone, "El Cruce")
			T.eq(context.mapID, 1413)
			T.eq(context.x, 0.5123)
			T.eq(context.y, 0.302)
			T.eq(context.myLevel, 30)
			T.eq(type(context.t), "number")
		end)

		it("drops a sub-zone equal to the zone and an empty one", function()
			env.GetZoneText = function() return "Desolace" end
			env.GetSubZoneText = function() return "Desolace" end
			T.isNil(Api.CurrentContext().subZone)
		end)

		it("survives a client that hides the position", function()
			env.C_Map.GetBestMapForUnit = function() return 1413 end
			env.C_Map.GetPlayerMapPosition = function() error("restricted") end
			local context = Api.CurrentContext()
			T.eq(context.mapID, 1413)
			T.isNil(context.x)
		end)
	end)

	describe("DeathRecap", function()
		it("says when the client has no death recap", function()
			T.eq({ Api.DeathRecap() }, { nil, "unavailable" })
		end)

		it("reads the killing blow and the recap ID", function()
			env.C_DeathRecap = {
				GetRecapLink = function() return "|Hdeath:42|h[Death]|h" end,
				GetRecapEvents = function() return { { timestamp = 5, sourceGUID = "Player-1-AAA", sourceName = "Kane Mochivich" } } end,
			}
			T.eq(Api.DeathRecap(), { id = 42, timestamp = 5, sourceGUID = "Player-1-AAA", sourceName = "Kane Mochivich", hideCaster = false })
		end)

		it("reports an empty or unreadable recap", function()
			env.C_DeathRecap = { GetRecapEvents = function() return {} end }
			T.eq({ Api.DeathRecap() }, { nil, "empty" })
			env.C_DeathRecap = { GetRecapEvents = function() return { __secretTable = true } end }
			T.eq({ Api.DeathRecap() }, { nil, "unreadable" })
		end)
	end)

	it("reads race names and atlases", function()
		env.C_CreatureInfo.GetRaceInfo = function(id) return id == 7 and { raceName = "Gnomo", clientFileString = "Gnome" } or nil end
		env.C_Texture.GetAtlasInfo = function(name) return name == "raceicon128-gnome-male" and {} or nil end
		T.eq({ Api.RaceInfo(7) }, { "Gnomo", "Gnome" })
		T.isNil(Api.RaceInfo(8))
		T.truthy(Api.AtlasExists("raceicon128-gnome-male"))
		T.falsy(Api.AtlasExists("raceicon128-skyborne-male"))
	end)

	describe("IsGroupGUID", function()
		it("is false when we are alone", function()
			units.party1 = { guid = "Player-1-MATE" }
			T.falsy(Api.IsGroupGUID("Player-1-MATE"))
		end)

		it("finds party members and their pets", function()
			env.GetNumGroupMembers = function() return 3 end
			units.party1 = { guid = "Player-1-MATE" }
			units.partypet2 = { guid = "Pet-1-WOLF" }
			T.truthy(Api.IsGroupGUID("Player-1-MATE"))
			T.truthy(Api.IsGroupGUID("Pet-1-WOLF"))
			T.falsy(Api.IsGroupGUID("Player-1-STRANGER"))
		end)

		it("finds raid members", function()
			env.GetNumGroupMembers = function() return 12 end
			env.IsInRaid = function() return true end
			units.raid11 = { guid = "Player-1-RAIDER" }
			T.truthy(Api.IsGroupGUID("Player-1-RAIDER"))
		end)

		it("ignores secret or missing GUIDs", function()
			env.GetNumGroupMembers = function() return 2 end
			units.party1 = { guid = env.Secret("Player-1-MATE") }
			T.falsy(Api.IsGroupGUID("Player-1-MATE"))
			T.falsy(Api.IsGroupGUID(nil))
		end)
	end)

	describe("nameplates", function()
		it("gives the nameplate of a unit token", function()
			local nameplate = env.__showNamePlate("nameplate3")
			T.truthy(Api.NamePlateForUnit("nameplate3") == nameplate)
			T.isNil(Api.NamePlateForUnit("nameplate4"))
			T.isNil(Api.NamePlateForUnit(nil))
		end)

		it("refuses forbidden nameplates", function()
			env.__showNamePlate("nameplate1").__forbidden = true
			env.__showNamePlate("nameplate2").UnitFrame.__forbidden = true
			T.isNil(Api.NamePlateForUnit("nameplate1"))
			T.isNil(Api.NamePlateForUnit("nameplate2"))
			T.eq(Api.VisibleNamePlateUnits(), {})
		end)

		it("survives a client that raises or has no nameplate API", function()
			env.__showNamePlate("nameplate1")
			env.C_NamePlate.GetNamePlateForUnit = function() error("forbidden") end
			env.C_NamePlate.GetNamePlates = function() error("forbidden") end
			T.isNil(Api.NamePlateForUnit("nameplate1"))
			T.eq(Api.VisibleNamePlateUnits(), {})
			env.C_NamePlate = nil
			T.isNil(Api.NamePlateForUnit("nameplate1"))
			T.eq(Api.VisibleNamePlateUnits(), {})
		end)

		it("lists the unit tokens of the nameplates on screen", function()
			env.__showNamePlate("nameplate1")
			env.__showNamePlate("nameplate7")
			env.__showNamePlate("nameplate9").UnitFrame.unit = env.Secret("nameplate9")
			T.eq(Api.VisibleNamePlateUnits(), { "nameplate1", "nameplate7" })
		end)
	end)

	it("knows when we are in combat", function()
		T.falsy(Api.InCombat())
		env.InCombatLockdown = function() return true end
		T.truthy(Api.InCombat())
		env.InCombatLockdown = function() return env.Secret(true) end
		T.falsy(Api.InCombat(), "a secret answer counts as not known")
	end)

	it("reads map names", function()
		env.C_Map.GetMapInfo = function(id) return { name = id == 1413 and "Los Baldíos" or "?" } end
		T.eq(Api.MapName(1413), "Los Baldíos")
		T.isNil(Api.MapName(nil))
	end)
end)
