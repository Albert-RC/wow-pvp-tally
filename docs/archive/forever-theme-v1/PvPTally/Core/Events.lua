-- PvP Tally: a tiny publish / subscribe bus.
--
-- Modules talk through it instead of calling each other: the store announces new data,
-- the window and the chat notifications listen. Nothing in the core knows about the UI.

local _, ns = ...

local Events = {}
Events.__index = Events
ns.Events = Events

-- Fired when anything in the store changed. No arguments.
Events.DATA_CHANGED = "DATA_CHANGED"
-- Fired for a fight recorded as it happened (not for imports). Arguments: key, encounter, player.
Events.ENCOUNTER_ADDED = "ENCOUNTER_ADDED"
-- Fired when the user changes an option (Settings.Set). Arguments: key, value.
Events.SETTINGS_CHANGED = "SETTINGS_CHANGED"

function Events.New()
	return setmetatable({ listeners = {} }, Events)
end

function Events:On(event, listener)
	assert(type(event) == "string", "event name expected")
	assert(type(listener) == "function", "listener function expected")
	local list = self.listeners[event]
	if not list then
		list = {}
		self.listeners[event] = list
	end
	list[#list + 1] = listener
end

-- A failing listener is reported and does not stop the others.
function Events:Fire(event, ...)
	local list = self.listeners[event]
	if not list then
		return
	end
	for _, listener in ipairs(list) do
		local ok, err = pcall(listener, ...)
		if not ok then
			ns.Util.ReportError(event, err)
		end
	end
end

-- The bus the addon uses.
ns.bus = Events.New()
