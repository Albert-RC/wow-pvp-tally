-- A fake World of Warcraft environment: the globals the addon touches, with frames that
-- record what is done to them. Enough to load every file, start the addon and draw the
-- window; not a full client.
--
-- Wow.NewEnv(options) returns an environment table. Helpers on it:
--   env.__fire(event, ...)   fires a game event on every frame registered for it
--   env.__runTimers()        runs the C_Timer.After callbacks queued so far
--   env.__chat               chat lines printed
--   env.__popups             StaticPopup_Show calls
--   env.__written            globals the addon set (name -> true)
--   env.__clock              what GetTime() returns (change it to move time)
--   env.Secret(value)        a "secret" value: issecretvalue() is true for it

local Wow = {}

-- Frames ----------------------------------------------------------------------------------
-- Unknown Capitalized keys (methods, template children such as frame.Inset) are "magic":
-- callable, indexable, and returning more magic. Lowercase keys are plain fields (nil
-- until set), as in the real client.

local Frame = {}
local FrameMeta

local function NewFrame(kind, name, env)
	local frame = { __kind = kind, __name = name, __env = env, __scripts = {}, __points = {}, __shown = true, __width = 0, __height = 0 }
	return setmetatable(frame, FrameMeta)
end

local Magic
local MagicMeta = {
	__index = function(self, key)
		if type(key) == "string" and key:match("^%u") then
			local child = Magic()
			rawset(self, key, child)
			return child
		end
		return nil
	end,
	__call = function()
		return NewFrame("Magic")
	end,
}
Magic = function()
	return setmetatable({}, MagicMeta)
end

FrameMeta = {
	__index = function(self, key)
		local method = Frame[key]
		if method then
			return method
		end
		if type(key) == "string" and key:match("^%u") then
			local child = Magic()
			rawset(self, key, child)
			return child
		end
		return nil
	end,
}

function Frame:SetScript(script, fn) self.__scripts[script] = fn end
function Frame:GetScript(script) return self.__scripts[script] end
function Frame:HookScript(script, fn)
	local previous = self.__scripts[script]
	self.__scripts[script] = function(...)
		if previous then previous(...) end
		fn(...)
	end
end
function Frame:RunScript(script, ...)
	local fn = self.__scripts[script]
	if fn then return fn(self, ...) end
end

function Frame:Show()
	local was = self.__shown
	self.__shown = true
	if not was then self:RunScript("OnShow") end
end
function Frame:Hide()
	local was = self.__shown
	self.__shown = false
	if was then self:RunScript("OnHide") end
end
function Frame:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Frame:IsShown() return self.__shown end

function Frame:SetText(text) self.__text = text end
function Frame:GetText() return self.__text end

-- Like the client, a new size is reported later: OnSizeChanged fires when something
-- reads the size (GetWidth / GetHeight) or the layout is flushed (env.__flushLayout),
-- not inside SetSize. Code that reads a size mid-update must be ready for it.
local function FlushSize(self)
	if self.__sizeDirty then
		self.__sizeDirty = nil
		if self.__env then self.__env.__dirtyFrames[self] = nil end
		self:RunScript("OnSizeChanged", self.__width, self.__height)
	end
end
local function Resized(self, width, height)
	if width ~= self.__width or height ~= self.__height then
		self.__width, self.__height = width, height
		self.__sizeDirty = true
		if self.__env then self.__env.__dirtyFrames[self] = true end
	end
end
function Frame:SetSize(width, height) Resized(self, width, height) end
function Frame:SetWidth(width) Resized(self, width, self.__height) end
function Frame:SetHeight(height) Resized(self, self.__width, height) end
function Frame:GetWidth() FlushSize(self); return self.__width end
function Frame:GetHeight() FlushSize(self); return self.__height end

function Frame:SetPoint(...) self.__points[#self.__points + 1] = { ... } end
function Frame:ClearAllPoints() self.__points = {} end
function Frame:GetPoint() local p = self.__points[1] or { "CENTER" }; return p[1], nil, p[3] or p[1], p[4] or 0, p[5] or 0 end
function Frame:GetCenter() return 100, 100 end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetFrameLevel() return 1 end

function Frame:SetAtlas(atlas) self.__atlas, self.__file = atlas, nil end
function Frame:SetTexture(file) self.__file, self.__atlas = file, nil end
function Frame:SetTextColor(r, g, b) self.__color = { r, g, b } end

function Frame:CreateTexture() return NewFrame("Texture", nil, self.__env) end
function Frame:CreateFontString() return NewFrame("FontString", nil, self.__env) end
function Frame:GetFontString()
	self.__fontString = self.__fontString or NewFrame("FontString", nil, self.__env)
	return self.__fontString
end
function Frame:GetHighlightTexture()
	self.__highlight = self.__highlight or NewFrame("Texture", nil, self.__env)
	return self.__highlight
end

-- Dropdowns (WowStyle1DropdownTemplate): the menu generator is kept; Wow.MenuItems runs it.
function Frame:SetupMenu(generator) self.__menu = generator end
function Frame:GenerateMenu() end

function Frame:RegisterEvent(event)
	self.__env.__events[event] = self.__env.__events[event] or {}
	self.__env.__events[event][self] = true
end
function Frame:UnregisterEvent(event)
	if self.__env.__events[event] then self.__env.__events[event][self] = nil end
end
function Frame:UnregisterAllEvents()
	for _, frames in pairs(self.__env.__events) do frames[self] = nil end
end

-- A ScrollBox draws every row of its data provider on recycled row frames.
local ScrollBox = {}
function ScrollBox:SetDataProvider(rows)
	local view = self.__view
	self.__rowsData = rows
	self.__pool = self.__pool or {}
	for index, data in ipairs(rows) do
		local row = self.__pool[index] or NewFrame(view.frameType, nil, self.__env)
		self.__pool[index] = row
		view.initializer(row, data)
	end
	self.__count = #rows
end
function ScrollBox:EnumerateFrames()
	local frames = {}
	for index = 1, self.__count or 0 do frames[index] = self.__pool[index] end
	return ipairs(frames)
end

-- Environment -----------------------------------------------------------------------------------

function Wow.NewEnv(options)
	options = options or {}
	local env = {}
	env.__events = {}
	env.__chat = {}
	env.__popups = {}
	env.__timers = {}
	env.__written = {}
	env.__clock = 1000
	env.__dirtyFrames = {}

	-- The client's next layout pass: every pending OnSizeChanged fires.
	function env.__flushLayout()
		local frames = {}
		for frame in pairs(env.__dirtyFrames) do frames[#frames + 1] = frame end
		for _, frame in ipairs(frames) do FlushSize(frame) end
	end

	local secretMark = {}
	function env.Secret(value)
		return { [secretMark] = true, value = value }
	end
	function env.issecretvalue(value)
		return type(value) == "table" and value[secretMark] == true
	end
	function env.issecrettable(value)
		return type(value) == "table" and value.__secretTable == true
	end

	function env.CreateFrame(kind, name, parent, template)
		local frame = NewFrame(kind, name, env)
		frame.__parent, frame.__template = parent, template
		if template == "WowScrollBoxList" then
			for method, fn in pairs(ScrollBox) do frame[method] = fn end
		end
		if name then
			rawset(env, name, frame)
		end
		return frame
	end

	function env.__fire(event, ...)
		local frames = {}
		for frame in pairs(env.__events[event] or {}) do frames[#frames + 1] = frame end
		for _, frame in ipairs(frames) do frame:RunScript("OnEvent", event, ...) end
	end

	function env.__runTimers()
		while #env.__timers > 0 do
			table.remove(env.__timers, 1)()
		end
	end

	env.C_Timer = {
		After = function(_, callback) env.__timers[#env.__timers + 1] = callback end,
		NewTicker = function(_, callback) rawset(env, "__ticker", callback); return {} end,
	}
	env.GetTime = function() return env.__clock end
	env.time = function() return options.time or os.time() end
	env.date = os.date
	env.GetLocale = function() return options.locale or "enUS" end
	env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) env.__chat[#env.__chat + 1] = message end }
	env.StaticPopupDialogs = {}
	env.StaticPopup_Show = function(...) env.__popups[#env.__popups + 1] = { ... } end
	env.SlashCmdList = {}
	env.UISpecialFrames = {}
	env.UIParent = NewFrame("Frame", "UIParent", env)
	env.Minimap = NewFrame("Frame", "Minimap", env)
	env.GameTooltip = NewFrame("GameTooltip", "GameTooltip", env)
	env.PlaySound = function() end
	env.tinsert = table.insert
	env.wipe = function(t) for key in pairs(t) do t[key] = nil end return t end
	env.GetCursorPosition = function() return 0, 0 end
	env.CreateDataProvider = function(rows) return rows end
	env.CreateScrollBoxListLinearView = function()
		local view = Magic()
		view.SetElementInitializer = function(self, frameType, initializer)
			self.frameType, self.initializer = frameType, initializer
		end
		return view
	end
	env.ScrollUtil = {
		InitScrollBoxListWithScrollBar = function(box, _, view) box.__view = view end,
	}

	env.YES, env.NO, env.LEVEL, env.UNKNOWNOBJECT = "Yes", "No", "Level", "Unknown"
	env.FACTION_ALLIANCE, env.FACTION_HORDE = "Alliance", "Horde"
	env.RAID_CLASS_COLORS = {
		ROGUE = { r = 1, g = 0.96, b = 0.41 },
		PRIEST = { r = 1, g = 1, b = 1 },
		MAGE = { r = 0.25, g = 0.78, b = 0.92 },
	}
	env.CLASS_ICON_TCOORDS = { ROGUE = { 0.5, 0.74, 0, 0.25 }, PRIEST = { 0.49, 0.74, 0.25, 0.5 } }
	env.LOCALIZED_CLASS_NAMES_MALE = { ROGUE = "Rogue", PRIEST = "Priest" }

	-- Game state readers: nothing in sight, open world, no recap. Tests override them.
	env.UnitExists = function() return false end
	env.UnitIsPlayer = function() return false end
	env.UnitName = function() return nil end
	env.UnitIsEnemy = function() return false end
	env.UnitGUID = function() return nil end
	env.UnitClass = function() return nil end
	env.UnitRace = function() return nil end
	env.UnitSex = function() return nil end
	env.UnitLevel = function() return 0 end
	env.UnitIsUnit = function() return false end
	env.UnitFactionGroup = function() return nil end
	env.GetGuildInfo = function() return nil end
	env.GetPlayerInfoByGUID = function() return nil end
	env.IsInInstance = function() return false, "none" end
	env.GetZoneText = function() return "" end
	env.GetSubZoneText = function() return "" end
	env.C_Map = {
		GetBestMapForUnit = function() return nil end,
		GetPlayerMapPosition = function() return nil end,
		GetMapInfo = function() return nil end,
	}
	env.C_Texture = { GetAtlasInfo = function() return nil end }
	env.InCombatLockdown = function() return false end

	-- Blizzard's Settings API: env.__settings records the categories and what was opened.
	env.__settings = { categories = {}, registered = {}, opened = {} }
	env.Settings = {
		RegisterCanvasLayoutCategory = function(frame, name)
			local id = #env.__settings.categories + 1
			local category = { frame = frame, name = name, GetID = function() return id end }
			env.__settings.categories[id] = category
			return category
		end,
		RegisterAddOnCategory = function(category)
			env.__settings.registered[#env.__settings.registered + 1] = category
		end,
		OpenToCategory = function(id)
			env.__settings.opened[#env.__settings.opened + 1] = id
		end,
	}
	env.C_CreatureInfo = { GetRaceInfo = function() return nil end }

	for key, value in pairs(options.globals or {}) do
		env[key] = value
	end
	-- In the game, _G is the addon's global environment.
	env._G = env

	-- Lua's own library, read-only; every global the addon writes is recorded.
	return setmetatable(env, {
		__index = _G,
		__newindex = function(t, key, value)
			env.__written[key] = true
			rawset(t, key, value)
		end,
	})
end

Wow.NewFrame = function(kind, env) return NewFrame(kind or "Frame", nil, env) end

-- Runs a dropdown's menu generator and returns its radio entries:
-- { text, data, IsSelected(), Select() }.
function Wow.MenuItems(dropdown)
	local items = {}
	local root = {
		CreateRadio = function(_, text, isSelected, setSelected, data)
			items[#items + 1] = {
				text = text,
				data = data,
				IsSelected = function() return isSelected(data) end,
				Select = function() return setSelected(data) end,
			}
		end,
	}
	assert(dropdown.__menu, "the dropdown has no menu")
	dropdown.__menu(dropdown, root)
	return items
end

return Wow
