-- PvP Tally: startup. Builds the objects, wires them together and hooks them to the
-- game. The only file that knows every module.
--
--   ADDON_LOADED  saved variables are ready: settings, store, races, UI, options panel, commands
--   PLAYER_LOGIN  the world is ready: tracker, nameplate and portrait skulls, minimap button,
--                 first-run Spy import

local ADDON_NAME, ns = ...
local L, Util = ns.L, ns.Util

-- What the UI and the commands act on.
local App = {}
ns.App = App

function App.Toggle()
	ns.Window.Toggle()
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

-- The chat notification checkboxes of the options panel. kind: "kills" or "deaths".
function App.IsNotifying(kind)
	return ns.Settings.IsNotifying(App.settings, kind)
end

function App.SetNotify(kind, enabled)
	ns.Settings.SetNotify(App.settings, kind, enabled)
end

-- The nameplate skull checkbox of the options panel.
function App.IsMarkingNameplates()
	return ns.Settings.IsMarkingNameplates(App.settings)
end

function App.SetNameplateMarks(enabled)
	ns.Settings.SetNameplateMarks(App.settings, enabled)
	if App.nameplateMarks then
		App.nameplateMarks:Refresh()
	end
end

-- The portrait skull checkbox of the options panel.
function App.IsMarkingPortraits()
	return ns.Settings.IsMarkingPortraits(App.settings)
end

function App.SetPortraitMarks(enabled)
	ns.Settings.SetPortraitMarks(App.settings, enabled)
	if App.portraitMarks then
		App.portraitMarks:Refresh()
	end
end

-- The skull size picker of the options panel (one of Settings.MARK_SIZES).
function App.GetMarkSize()
	return ns.Settings.MarkSize(App.settings)
end

function App.SetMarkSize(size)
	ns.Settings.SetMarkSize(App.settings, size)
	if App.nameplateMarks then
		App.nameplateMarks:Refresh()
	end
end

function App.ToggleNotify()
	local enabled = ns.Settings.ToggleAllNotify(App.settings)
	ns.SettingsPanel.Refresh()
	Util.Print(enabled and L.NOTIFY_ON or L.NOTIFY_OFF)
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

-- /tally skull [First Last]: puts a player in the list as test data, so their nameplate
-- shows the skull. Without a name, the player in the target, friend or foe.
function App.AddSkullTest(name)
	local key, info
	if name and name ~= "" then
		key = ns.TestData.KeyFromName(name)
	else
		key, info = ns.WowApi.ReadPlayer("target")
	end
	if not key then
		Util.Print(L.SKULL_USAGE)
		return false
	end
	local display = Util.ColoredName(key, info and info.class)
	if not ns.TestData.AddPlayer(App.store, key, info, ns.WowApi.CurrentContext()) then
		Util.Print(L.SKULL_EXISTS:format(display))
		return false
	end
	Util.Print(L.SKULL_ADDED:format(display))
	return true
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

-- The skulls on the nameplates. Not tied to the tracker: they show in battlegrounds too.
local function StartNameplateMarks()
	local marks = ns.NameplateMarks.New({
		playerKey = ns.WowApi.PlayerKey,
		namePlateFor = ns.WowApi.NamePlateForUnit,
		lookup = function(key) return App.store:Get(key) end,
		isEnabled = function() return ns.Settings.IsMarkingNameplates(App.settings) end,
		size = App.GetMarkSize,
	})
	App.nameplateMarks = marks
	local events = CreateFrame("Frame")
	for _, event in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }) do
		pcall(events.RegisterEvent, events, event)
	end
	events:SetScript("OnEvent", Util.Guard("NameplateMarks", function(_, event, unit)
		if event == "NAME_PLATE_UNIT_ADDED" then
			marks:Show(unit)
		else
			marks:Remove(unit)
		end
	end))
	-- After a /reload the nameplates are already on screen.
	for _, unit in ipairs(ns.WowApi.VisibleNamePlateUnits()) do
		marks:Show(unit)
	end
	-- A new player in the list (or one deleted) gets (or loses) the skull at once.
	ns.bus:On(ns.Events.DATA_CHANGED, function() marks:Refresh() end)
end

-- The skull over the portrait of the target and focus frames: the fallback for when
-- another addon replaces the nameplates.
local function StartPortraitMarks()
	local marks = ns.PortraitMarks.New({
		frames = { target = TargetFrame, focus = FocusFrame },
		playerKey = ns.WowApi.PlayerKey,
		lookup = function(key) return App.store:Get(key) end,
		isEnabled = function() return ns.Settings.IsMarkingPortraits(App.settings) end,
	})
	App.portraitMarks = marks
	local events = CreateFrame("Frame")
	for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED" }) do
		pcall(events.RegisterEvent, events, event)
	end
	events:SetScript("OnEvent", Util.Guard("PortraitMarks", function(_, event)
		marks:Update(event == "PLAYER_FOCUS_CHANGED" and "focus" or "target")
	end))
	marks:Refresh()
	ns.bus:On(ns.Events.DATA_CHANGED, function() marks:Refresh() end)
end

local function OnPlayerLogin()
	StartTracker()
	StartNameplateMarks()
	StartPortraitMarks()
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
