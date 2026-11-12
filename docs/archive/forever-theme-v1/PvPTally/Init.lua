-- PvP Tally: startup. Builds the objects, wires them together and hooks them to the
-- game. The only file that knows every module.
--
--   ADDON_LOADED  saved variables are ready: settings, store, races, UI, options panel, commands
--   PLAYER_LOGIN  the world is ready: tracker, minimap button, first-run Spy import

local ADDON_NAME, ns = ...
local L, Util = ns.L, ns.Util

-- What the UI and the commands act on.
local App = {}
ns.App = App

function App.Toggle()
	ns.Window.Toggle()
end

-- Whether the client has an atlas (themes fall back to classic pieces without it).
function App.AtlasExists(atlas)
	return ns.WowApi.AtlasExists(atlas)
end

-- Changes an option chosen in the options panel. Returns whether it changed.
function App.SetSetting(key, value)
	return ns.Settings.Set(App.settings, key, value, ns.bus)
end

-- Opens Options > AddOns > PvP Tally. Returns whether it opened.
function App.OpenSettings()
	if ns.WowApi.InCombat() then
		Util.Print(L.SETTINGS_IN_COMBAT)
		return false
	end
	if not ns.SettingsPanel.Open() then
		Util.Print(L.SETTINGS_UNAVAILABLE)
		return false
	end
	return true
end

function App.IsSpyAvailable()
	return ns.SpyImport.IsAvailable()
end

function App.ImportFromSpy(silent)
	local result = ns.SpyImport.Run(App.store, ns.SpyImport.ReadSavedData(), ns.WowApi.MapName, ns.WowApi.Time())
	if not result.found then
		if not silent then Util.Print(L.SPY_NOT_FOUND) end
	elseif result.players > 0 then
		Util.Print(L.IMPORT_DONE:format(result.players, result.fights))
	elseif not silent then
		Util.Print(L.IMPORT_NOTHING)
	end
	return result
end

function App.ConfirmDelete(key)
	ns.Commands.ConfirmDelete(key)
end

function App.ToggleNotify()
	App.settings.notify = not App.settings.notify
	Util.Print(App.settings.notify and L.NOTIFY_ON or L.NOTIFY_OFF)
end

function App.ToggleMinimap()
	local show = App.settings.minimap.hide
	ns.MinimapButton.SetShown(show)
	if not show then
		Util.Print(L.MINIMAP_HIDDEN)
	end
end

function App.AddTestData()
	local labels = {
		male = L.TEST_MALE,
		female = L.TEST_FEMALE,
		Alliance = FACTION_ALLIANCE or "Alliance",
		Horde = FACTION_HORDE or "Horde",
	}
	local count = ns.TestData.Add(App.store, labels, function(raceID) return App.races:Name(raceID) end, ns.WowApi.Time())
	Util.Print(L.TEST_ADDED:format(count))
end

function App.ClearTestData()
	ns.TestData.Clear(App.store)
	Util.Print(L.TEST_REMOVED)
end

-- Startup -------------------------------------------------------------------------------------

local function OnAddonLoaded()
	PvPTallyDB = ns.Settings.Init(PvPTallyDB)
	if type(PvPTallyCharDB) ~= "table" then
		PvPTallyCharDB = {}
	end
	App.settings = PvPTallyDB
	App.store = ns.Store.New(PvPTallyCharDB, ns.bus)
	App.races = ns.Races.NewResolver(ns.WowApi.RaceInfo, ns.WowApi.AtlasExists, CLASS_ICON_TCOORDS)

	ns.Window.Init(App)
	ns.SettingsPanel.Register(App)
	ns.Commands.Register(App)
	ns.Notifications.Attach(ns.bus, App.settings)
	ns.bus:On(ns.Events.DATA_CHANGED, ns.Window.Refresh)
	ns.bus:On(ns.Events.SETTINGS_CHANGED, function(key)
		if key == "theme" then
			ns.Window.ApplyTheme()
		end
	end)
end

local function StartTracker()
	local tracker = ns.Tracker.New(ns.WowApi, App.store)
	App.tracker = tracker
	local events = CreateFrame("Frame")
	for _, event in ipairs(ns.Tracker.EVENTS) do
		pcall(events.RegisterEvent, events, event) -- an event this client lacks is skipped
	end
	events:SetScript("OnEvent", function(_, event, ...)
		local ok, err = pcall(tracker.HandleEvent, tracker, event, ...)
		if not ok then
			Util.ReportError(event, err)
		end
	end)
	ns.WowApi.NewTicker(ns.Tracker.SCAN_INTERVAL, Util.Guard("ScanVisible", function()
		tracker:ScanVisible()
	end))
end

local function OnPlayerLogin()
	StartTracker()
	ns.MinimapButton.Create(App)
	-- First run on this character: bring in what Spy already knows, if Spy is around.
	if not App.store:IsImported(ns.SpyImport.SOURCE) and ns.SpyImport.IsAvailable() then
		App.ImportFromSpy(true)
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name == ADDON_NAME then
		self:UnregisterEvent("ADDON_LOADED")
		OnAddonLoaded()
	elseif event == "PLAYER_LOGIN" then
		self:UnregisterEvent("PLAYER_LOGIN")
		OnPlayerLogin()
	end
end)
