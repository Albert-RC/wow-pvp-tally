-- The addon as a whole: TOC, globals, startup and a smoke test of the window.

local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

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
				"Columns", "ListModel", "Rows", "Window", "MinimapButton", "SettingsPanel", "Commands", "App" }) do
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
			T.eq(env.PvPTallyDB.notify, true)
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

		it("leaves the import button disabled without Spy", function()
			T.falsy(env.__settings.registered[1].frame.ImportButton.__enabled)
			T.truthy(env.__settings.registered[1].frame.SpyMissing:IsShown())
		end)

		it("no longer has the import button in the main window", function()
			ns.App.Toggle()
			T.isNil(rawget(env.PvPTallyFrame, "ImportButton"))
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
