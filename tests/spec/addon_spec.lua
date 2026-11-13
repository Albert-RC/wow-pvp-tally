-- The addon as a whole: TOC, globals, startup and a smoke test of the window.

local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each
local Wow = require("wow")

local function fileExists(path)
	local handle = io.open(path, "rb")
	if handle then handle:close() end
	return handle ~= nil
end

local SPY_DATA = {
	PlayerData = {
		["Cabo-Trancas"] = { class = "PRIEST", race = "Gnoma", level = 23, isGuess = false, isEnemy = true, wins = 1 },
	},
	Encounters = {
		{ t = 1794424972, n = "Cabo-Trancas", r = "W", k = "kill", l = 23, m = 1413 },
	},
}

describe("Addon", function()
	describe("TOC", function()
		it("lists only files that exist", function()
			for _, file in ipairs(Addon.Toc().files) do
				T.truthy(fileExists(Addon.Path(file)), file)
			end
		end)

		it("depends on no other addon", function()
			local fields = Addon.Toc().fields
			for _, field in ipairs({ "Dependencies", "RequiredDeps", "Dep", "OptionalDeps", "LoadWith", "LoadManagers" }) do
				T.isNil(fields[field], field)
			end
			for field in pairs(fields) do
				T.falsy(field:match("^Dep"), field)
			end
		end)

		it("targets the Forever client and declares the saved variables", function()
			local fields = Addon.Toc().fields
			T.eq(fields.Interface, "16001")
			T.eq(fields.SavedVariables, "PvPTallyDB")
			T.eq(fields.SavedVariablesPerCharacter, "PvPTallyCharDB")
		end)

		it("is listed under the Combat category", function()
			local fields = Addon.Toc().fields
			T.eq(fields.Category, "Combat")
			T.eq(fields["Category-esES"], "Combate")
			T.eq(fields["Category-esMX"], "Combate")
		end)

		it("ships no embedded libraries", function()
			for _, file in ipairs(Addon.Toc().files) do
				T.falsy(file:lower():find("libs?/"), file)
				T.falsy(file:lower():find("%.xml$"), file)
			end
		end)
	end)

	describe("loading", function()
		it("loads every file without errors", function()
			local ns = Addon.LoadAll()
			for _, module in ipairs({ "Util", "Events", "Store", "Races", "WowApi", "Tracker", "SpyImport", "TestData",
				"Columns", "ListModel", "Rows", "Window", "MinimapButton", "NameplateMarks", "PortraitMarks", "SettingsPanel", "Commands", "App" }) do
				T.notNil(ns[module], module)
			end
		end)

		it("creates only its own globals", function()
			local _, env = Addon.Start()
			local allowed = {
				PvPTallyDB = true, PvPTallyCharDB = true,
				SLASH_PVPTALLY1 = true, SLASH_PVPTALLY2 = true,
				PvPTally_OnAddonCompartmentClick = true,
			}
			for name in pairs(env.__written) do
				T.truthy(allowed[name], "unexpected global " .. tostring(name))
			end
		end)

		it("reads no other addon's code or conventions", function()
			for _, file in ipairs(Addon.Toc().files) do
				local source = Addon.ReadFile(Addon.Path(file))
				T.falsy(source:find("LibStub", 1, true), file .. " uses LibStub")
				T.falsy(source:find("CUSTOM_CLASS_COLORS", 1, true), file .. " uses CUSTOM_CLASS_COLORS")
				T.falsy(source:find("Spy:%u"), file .. " calls Spy's methods")
				T.falsy(source:find("Spy%.%u"), file .. " reaches into Spy's code")
				T.falsy(source:find("IsAddOnLoaded") or source:find("LoadAddOn"), file .. " checks or loads other addons")
			end
		end)
	end)

	describe("startup", function()
		it("starts with no saved data and no Spy", function()
			local ns, env = Addon.Start()
			T.eq(env.PvPTallyCharDB.version, ns.Store.SCHEMA_VERSION)
			T.eq(env.PvPTallyDB.notifyKills, true)
			T.eq(env.PvPTallyDB.notifyDeaths, true)
			T.notNil(ns.App.tracker)
			T.falsy(ns.App.store:IsImported("spy"))
			T.eq(#env.__chat, 0)
		end)

		it("keeps working when Spy is not installed: the import is just unavailable", function()
			local ns, env = Addon.Start()
			ns.App.ImportFromSpy(false)
			T.contains(env.__chat[1], "Spy data not found")
		end)

		it("imports from Spy on the first run only", function()
			local ns, env = Addon.Start({ globals = { SpyPerCharDB = SPY_DATA } })
			T.eq(#ns.App.store:Get("Cabo-Trancas").encounters, 1)
			T.contains(env.__chat[1], "Imported from Spy: 1 players")

			-- Next session: same saved data, no second import.
			local _, env2 = Addon.Start({ globals = { SpyPerCharDB = SPY_DATA, PvPTallyCharDB = env.PvPTallyCharDB } })
			T.eq(#env2.__chat, 0)
		end)

		it("upgrades data saved by the previous version", function()
			local old = { version = 1, spyImported = 123, players = { ["Kane-Mochivich"] = { encounters = { { t = 5, r = "K" } } } } }
			local ns = Addon.Start({ globals = { PvPTallyCharDB = old, SpyPerCharDB = SPY_DATA } })
			T.eq(ns.App.store.data.imports.spy, 123)
			T.isNil(ns.App.store:Get("Cabo-Trancas"), "already imported: not imported again")
		end)

		it("records a kill end to end and tells the chat", function()
			local ns, env = Addon.Start({ globals = {
				UnitExists = function(unit) return unit == "target" end,
				UnitIsPlayer = function() return true end,
				UnitName = function() return "Kane", "Mochivich" end,
				UnitIsEnemy = function() return true end,
				UnitGUID = function(unit) return unit == "player" and "Player-1-ME" or "Player-1-AAA" end,
				UnitLevel = function(unit) return unit == "player" and 30 or 25 end,
			} })
			env.__fire("PLAYER_TARGET_CHANGED")
			env.__fire("PARTY_KILL", "Player-1-ME", "Player-1-AAA")
			local player = ns.App.store:Get("Kane-Mochivich")
			T.eq(#player.encounters, 1)
			T.eq(player.encounters[1].oppLevel, 25)
			T.contains(env.__chat[1], "You killed")
		end)

		it("records a group member's kill when we had the enemy targeted", function()
			local ns, env = Addon.Start({ globals = {
				GetNumGroupMembers = function() return 2 end,
				UnitExists = function(unit) return unit == "target" end,
				UnitIsPlayer = function() return true end,
				UnitName = function() return "Kane", "Mochivich" end,
				UnitIsEnemy = function() return true end,
				UnitGUID = function(unit)
					if unit == "player" then return "Player-1-ME" end
					if unit == "party1" then return "Player-1-MATE" end
					return "Player-1-AAA"
				end,
				UnitLevel = function(unit) return unit == "player" and 30 or 25 end,
			} })
			env.__fire("PLAYER_TARGET_CHANGED")
			env.__fire("PARTY_KILL", "Player-1-MATE", "Player-1-AAA")
			local encounter = ns.App.store:Get("Kane-Mochivich").encounters[1]
			T.eq(encounter.how, "group")
			T.contains(env.__chat[1], "Your group killed")
		end)
	end)

	describe("options", function()
		local ns, env
		before_each(function()
			ns, env = Addon.Start()
		end)

		it("adds its panel to Options > AddOns at startup", function()
			T.eq(#env.__settings.registered, 1)
			T.eq(env.__settings.registered[1].name, "PvP Tally")
		end)

		it("opens from the command, the window button and a right-click on the minimap button", function()
			env.SlashCmdList.PVPTALLY("settings")
			ns.App.Toggle()
			env.PvPTallyFrame.SettingsButton:RunScript("OnClick")
			env.PvPTallyMinimapButton:RunScript("OnClick", "RightButton")
			T.eq(#env.__settings.opened, 3)
		end)

		it("still opens the window with a left-click on the minimap button", function()
			env.PvPTallyMinimapButton:RunScript("OnClick", "LeftButton")
			T.truthy(env.PvPTallyFrame:IsShown())
			T.eq(#env.__settings.opened, 0)
		end)

		it("refuses to open in combat and says why", function()
			env.InCombatLockdown = function() return true end
			T.falsy(ns.App.OpenSettings())
			T.eq(#env.__settings.opened, 0)
			T.contains(env.__chat[1], "in combat")
		end)

		it("says so on a client without the Settings API", function()
			local ns2, env2 = Addon.Start({ globals = { Settings = false } })
			T.falsy(ns2.App.OpenSettings())
			T.contains(env2.__chat[1], "no options panel")
		end)

		it("imports from Spy with the button in the options", function()
			local ns2, env2 = Addon.Start({ globals = { SpyPerCharDB = SPY_DATA, PvPTallyDB = {} } })
			ns2.App.store:Reset() -- forget the first-run import
			local panel = env2.__settings.registered[1].frame
			T.truthy(panel.ImportButton.__enabled)
			panel.ImportButton:RunScript("OnClick")
			T.eq(#ns2.App.store:Get("Cabo-Trancas").encounters, 1)
		end)

		it("stops kill messages from the options checkbox, and keeps it for the next session", function()
			local ns2, env2 = Addon.Start({ globals = {
				UnitExists = function(unit) return unit == "target" end,
				UnitIsPlayer = function() return true end,
				UnitName = function() return "Kane", "Mochivich" end,
				UnitIsEnemy = function() return true end,
				UnitGUID = function(unit) return unit == "player" and "Player-1-ME" or "Player-1-AAA" end,
			} })
			local panel = env2.__settings.registered[1].frame
			panel.NotifyChecks[1]:Click() -- kills
			T.eq(env2.PvPTallyDB.notifyKills, false)
			env2.__fire("PLAYER_TARGET_CHANGED")
			env2.__fire("PARTY_KILL", "Player-1-ME", "Player-1-AAA")
			T.eq(#ns2.App.store:Get("Kane-Mochivich").encounters, 1, "the kill is still recorded")
			T.eq(#env2.__chat, 0, "but not announced")
			T.eq(Addon.Start({ globals = { PvPTallyDB = env2.PvPTallyDB } }).App.settings.notifyKills, false)
		end)

		it("keeps the checkboxes in step with /tally notify", function()
			local panel = env.__settings.registered[1].frame
			env.SlashCmdList.PVPTALLY("notify")
			T.falsy(panel.NotifyChecks[1]:GetChecked())
			T.falsy(panel.NotifyChecks[2]:GetChecked())
			env.SlashCmdList.PVPTALLY("notify")
			T.truthy(panel.NotifyChecks[1]:GetChecked())
			T.truthy(panel.NotifyChecks[2]:GetChecked())
		end)

		it("leaves the import button disabled without Spy", function()
			T.falsy(env.__settings.registered[1].frame.ImportButton.__enabled)
			T.truthy(env.__settings.registered[1].frame.SpyMissing:IsShown())
		end)

		it("no longer has the import button in the main window", function()
			ns.App.Toggle()
			T.isNil(rawget(env.PvPTallyFrame, "ImportButton"))
		end)
	end)

	describe("nameplate skulls", function()
		-- Saved data with Kane in the list, fresh for each start (the store writes into it).
		local function KaneSaved()
			return { version = 2, players = { ["Kane-Mochivich"] = { name = "Kane", encounters = { { t = 5, r = "K" } } } } }
		end

		-- Who is behind each nameplate token: unit -> { name, realm, enemy }.
		local function Start(people, extra)
			local globals = {
				PvPTallyCharDB = KaneSaved(),
				UnitExists = function(unit) return people[unit] ~= nil end,
				UnitIsPlayer = function(unit) return people[unit] ~= nil end,
				UnitName = function(unit) return people[unit].name, people[unit].realm end,
				UnitIsEnemy = function(_, unit) return people[unit] ~= nil and people[unit].enemy == true end,
			}
			for key, value in pairs(extra or {}) do globals[key] = value end
			return Addon.Start({ globals = globals })
		end

		local function hasSkull(ns, nameplate)
			local texture = ns.App.nameplateMarks.textures[nameplate]
			return texture ~= nil and texture:IsShown()
		end

		it("marks a player of the list when the nameplate appears, friend or foe", function()
			local people = { nameplate1 = { name = "Kane", realm = "Mochivich", enemy = false }, nameplate2 = { name = "Ally", realm = "Nobody" } }
			local ns, env = Start(people)
			local kane = env.__showNamePlate("nameplate1")
			local ally = env.__showNamePlate("nameplate2")
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
			T.truthy(hasSkull(ns, kane))
			T.falsy(hasSkull(ns, ally))

			env.__fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
			T.falsy(hasSkull(ns, kane))
		end)

		it("marks the nameplates already on screen after a /reload", function()
			-- On screen before the addon starts listening: no NAME_PLATE_UNIT_ADDED for it.
			local kane = Wow.NewFrame("Frame")
			kane.UnitFrame = Wow.NewFrame("Frame")
			kane.UnitFrame.unit = "nameplate1"
			kane.UnitFrame.name = Wow.NewFrame("FontString")
			local ns = Start({ nameplate1 = { name = "Kane", realm = "Mochivich" } }, { C_NamePlate = {
				GetNamePlates = function() return { kane } end,
				GetNamePlateForUnit = function(unit) return unit == "nameplate1" and kane or nil end,
			} })
			T.truthy(hasSkull(ns, kane))
		end)

		it("shows in battlegrounds too", function()
			local people = { nameplate1 = { name = "Kane", realm = "Mochivich", enemy = true } }
			local ns, env = Start(people, { IsInInstance = function() return true, "pvp" end })
			local kane = env.__showNamePlate("nameplate1")
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
			T.truthy(hasSkull(ns, kane))
		end)

		it("marks an enemy as soon as the first fight with them is recorded", function()
			local people = { nameplate1 = { name = "Tulan", realm = "Ator", enemy = true } }
			local ns, env = Start(people, {
				UnitGUID = function(unit) return unit == "player" and "Player-1-ME" or "Player-1-TULAN" end,
			})
			local tulan = env.__showNamePlate("nameplate1")
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
			T.falsy(hasSkull(ns, tulan))
			env.__fire("PARTY_KILL", "Player-1-ME", "Player-1-TULAN")
			T.notNil(ns.App.store:Get("Tulan-Ator"))
			T.truthy(hasSkull(ns, tulan))
		end)

		it("is switched off and on from the options, and remembered", function()
			local people = { nameplate1 = { name = "Kane", realm = "Mochivich" } }
			local ns, env = Start(people)
			local kane = env.__showNamePlate("nameplate1")
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
			local check = env.__settings.registered[1].frame.NameplateCheck
			T.truthy(check:GetChecked())
			check:Click()
			T.falsy(hasSkull(ns, kane))
			T.eq(env.PvPTallyDB.nameplateMarks, false)
			T.falsy(Addon.Start({ globals = { PvPTallyDB = env.PvPTallyDB } }).App.IsMarkingNameplates())
			check:Click()
			T.truthy(hasSkull(ns, kane))
		end)

		describe("/tally skull", function()
			it("puts the named player on the list, so their nameplate gets the skull", function()
				local people = { nameplate1 = { name = "Tulan", realm = "Ator" } }
				local ns, env = Start(people)
				local tulan = env.__showNamePlate("nameplate1")
				env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
				T.falsy(hasSkull(ns, tulan))

				env.SlashCmdList.PVPTALLY("skull Tulan Ator")
				T.truthy(ns.App.store:Get("Tulan-Ator").test)
				T.truthy(hasSkull(ns, tulan))
				T.contains(env.__chat[1], "Tulan Ator")
				T.contains(env.__chat[1], "/tally test clear")

				env.SlashCmdList.PVPTALLY("test clear")
				T.isNil(ns.App.store:Get("Tulan-Ator"))
				T.falsy(hasSkull(ns, tulan))
			end)

			it("takes the player in the target when no name is given", function()
				local people = { target = { name = "Ally", realm = "Friend" } }
				local ns, env = Start(people, { UnitClass = function() return "Sacerdote", "PRIEST" end })
				env.SlashCmdList.PVPTALLY("skull")
				T.eq(ns.App.store:Get("Ally-Friend").class, "PRIEST")
			end)

			it("explains how to use it without a name or a player in the target", function()
				local ns, env = Start({})
				T.falsy(ns.App.AddSkullTest(""))
				T.contains(env.__chat[1], "Usage: /tally skull")
			end)

			it("leaves a player already in the list alone", function()
				local ns, env = Start({})
				env.SlashCmdList.PVPTALLY("skull Kane Mochivich")
				T.contains(env.__chat[1], "already in your list")
				T.isNil(ns.App.store:Get("Kane-Mochivich").test)
			end)
		end)

		it("changes size from the options, at once, and keeps it", function()
			local ns, env = Start({ nameplate1 = { name = "Kane", realm = "Mochivich" } })
			local kane = env.__showNamePlate("nameplate1")
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
			local texture = ns.App.nameplateMarks.textures[kane]
			T.eq(texture.__width, 28, "medium by default")

			local large = env.__settings.registered[1].frame.MarkSizeDropdown:__menu()[3]
			large.select()
			T.eq({ texture.__width, texture.__height }, { 36, 36 })
			T.truthy(large.isSelected())
			T.eq(Addon.Start({ globals = { PvPTallyDB = env.PvPTallyDB } }).App.GetMarkSize(), 36)
		end)

		describe("over the portrait", function()
			local function portraitSkull(ns, unit)
				local texture = ns.App.portraitMarks.textures[unit]
				return texture ~= nil and texture:IsShown()
			end

			it("covers the portrait of a target or focus in the list, and only theirs", function()
				local people = { target = { name = "Kane", realm = "Mochivich" } }
				local ns, env = Start(people)
				env.__fire("PLAYER_TARGET_CHANGED")
				T.truthy(portraitSkull(ns, "target"))
				local texture = ns.App.portraitMarks.textures.target
				T.truthy(texture.__parent == env.TargetFrame.TargetFrameContainer)
				T.truthy(texture.__allPoints == env.TargetFrame.TargetFrameContainer.Portrait)
				T.truthy(texture.__mask.__parent == env.TargetFrame.TargetFrameContainer)
				T.eq({ texture.__layer, texture.__sublevel }, { "BACKGROUND", 2 }, "just above the portrait")
				T.eq(texture.__file, ns.PortraitMarks.SKULL.file)
				T.contains(texture.__file, "INV_Misc_Bone_HumanSkull_01")

				people.target = { name = "Ally", realm = "Nobody" }
				env.__fire("PLAYER_TARGET_CHANGED")
				T.falsy(portraitSkull(ns, "target"))

				people.focus = { name = "Kane", realm = "Mochivich" }
				env.__fire("PLAYER_FOCUS_CHANGED")
				T.truthy(portraitSkull(ns, "focus"))
			end)

			it("appears when the target enters the list, and goes with the option", function()
				local people = { target = { name = "Tulan", realm = "Ator" } }
				local ns, env = Start(people)
				env.__fire("PLAYER_TARGET_CHANGED")
				T.falsy(portraitSkull(ns, "target"))
				env.SlashCmdList.PVPTALLY("skull")
				T.truthy(portraitSkull(ns, "target"))

				env.__settings.registered[1].frame.PortraitCheck:Click()
				T.eq(env.PvPTallyDB.portraitMarks, false)
				T.falsy(portraitSkull(ns, "target"))
			end)

			it("goes as soon as the player is deleted from the list", function()
				local ns, env = Start({ target = { name = "Kane", realm = "Mochivich" } })
				env.__fire("PLAYER_TARGET_CHANGED")
				T.truthy(portraitSkull(ns, "target"))
				ns.App.store:Delete("Kane-Mochivich")
				T.falsy(portraitSkull(ns, "target"))
			end)

			it("keeps an error for /tally debug instead of breaking", function()
				local people = {}
				local ns, env = Start(people)
				env.TargetFrame.TargetFrameContainer.CreateTexture = function() error("boom") end
				people.target = { name = "Kane", realm = "Mochivich" }
				env.__fire("PLAYER_TARGET_CHANGED")
				T.contains(ns.Util.lastError, "PortraitMarks")
				T.contains(ns.Util.lastError, "boom")
			end)

			it("does nothing when another addon took the target frame apart", function()
				local ns, env = Start({ target = { name = "Kane", realm = "Mochivich" } }, { TargetFrame = false })
				env.__fire("PLAYER_TARGET_CHANGED")
				T.isNil(ns.App.portraitMarks.textures.target)
				T.isNil(ns.Util.lastError)
			end)
		end)

		it("keeps an error for /tally debug instead of breaking", function()
			local people = { nameplate1 = { name = "Kane", realm = "Mochivich" } }
			local ns, env = Start(people)
			local nameplate = env.__showNamePlate("nameplate1")
			nameplate.CreateTexture = function() error("boom") end -- only the skull touches the nameplate
			env.__fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
			T.contains(ns.Util.lastError, "NameplateMarks")
			T.contains(ns.Util.lastError, "boom")
		end)
	end)

	describe("window", function()
		local ns, env
		before_each(function()
			ns, env = Addon.Start()
			ns.App.AddTestData()
			ns.App.Toggle()
		end)

		it("opens and lists the players", function()
			local frame = env.PvPTallyFrame
			T.truthy(frame:IsShown())
			T.eq(frame.ScrollBox.__count, 1 + #ns.Races.LIST * 2)
			T.contains(frame.Summary:GetText(), "Players:")
		end)

		it("fills a player row", function()
			local row = env.PvPTallyFrame.ScrollBox.__pool[1]
			T.eq(row.data.kind, "player")
			T.notNil(row.cells.name:GetText())
			T.notNil(row.cells.kills:GetText())
		end)

		it("draws class icons from the class atlases when the client has them", function()
			local ns2, env2 = Addon.Start({ globals = { C_Texture = {
				GetAtlasInfo = function(name) return name:find("^classicon%-") and {} or nil end,
			} } })
			ns2.App.AddTestData()
			ns2.App.Toggle()
			for index = 1, env2.PvPTallyFrame.ScrollBox.__count do
				local row = env2.PvPTallyFrame.ScrollBox.__pool[index]
				T.eq(row.ClassIcon.__atlas, "classicon-" .. row.data.player.class:lower(), row.data.key)
			end
		end)

		it("expands a player into his fights", function()
			ns.Window.Toggle() -- close
			ns.Window.Toggle() -- open
			local frame = env.PvPTallyFrame
			frame.ExpandButton:RunScript("OnClick")
			local kinds = {}
			for index = 1, frame.ScrollBox.__count do
				local kind = frame.ScrollBox.__pool[index].data.kind
				kinds[kind] = (kinds[kind] or 0) + 1
			end
			T.truthy(kinds.header > 0 and kinds.fight > 0 and kinds.extra == 1)
		end)

		it("sorts when a header is clicked", function()
			local frame = env.PvPTallyFrame
			frame.Headers[1]:RunScript("OnClick") -- name, A to Z
			local first = frame.ScrollBox.__pool[1].data.name
			local second = frame.ScrollBox.__pool[2].data.name
			T.truthy(first:lower() <= second:lower())
		end)

		it("filters with the search box", function()
			local frame = env.PvPTallyFrame
			frame.SearchBox:SetText("Test Reg")
			frame.SearchBox:RunScript("OnTextChanged")
			T.eq(frame.ScrollBox.__count, 1)
		end)

		it("widens the columns when resized, within the limits", function()
			local frame = env.PvPTallyFrame
			local before = frame.Headers[1]:GetWidth()
			frame:SetSize(1000, 700)
			env.__flushLayout()
			T.truthy(frame.Headers[1]:GetWidth() > before)
			frame.ResizeGrip:RunScript("OnMouseUp")
			T.eq(env.PvPTallyDB.size, { 1000, 700 })
		end)

		it("refreshes when the data changes", function()
			ns.App.ClearTestData()
			T.eq(env.PvPTallyFrame.ScrollBox.__count, 0)
		end)
	end)

	describe("window size", function()
		it("opens a window saved wider than the minimum (BugSack: Window.lua:149)", function()
			local ns, env = Addon.Start({ globals = { PvPTallyDB = { size = { 1079, 555 } } } })
			ns.App.AddTestData()
			ns.App.Toggle()
			env.__flushLayout()
			local frame = env.PvPTallyFrame
			T.eq(#frame.Headers, 7)
			T.truthy(frame.Headers[1]:GetWidth() > 220, "the columns use the extra width")
		end)
	end)
end)
