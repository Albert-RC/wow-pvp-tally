-- PvP Tally: a chat line for every kill and death as it happens.

local _, ns = ...
local L, Util, Store = ns.L, ns.Util, ns.Store

local Notifications = {}
ns.Notifications = Notifications

-- The chat line for a fight just recorded.
function Notifications.Message(key, encounter, player)
	local kills, deaths = Store.Counts(player)
	local name = Util.ColoredName(key, player.class)
	local template = encounter.r == Store.KILL and L.NOTIFY_KILL or L.NOTIFY_DEATH
	return template:format(name, L.SCORE:format(kills, deaths))
end

-- Listens on bus; settings.notify switches the messages on and off.
function Notifications.Attach(bus, settings)
	bus:On(ns.Events.ENCOUNTER_ADDED, function(key, encounter, player)
		if settings.notify then
			Util.Print(Notifications.Message(key, encounter, player))
		end
	end)
end
