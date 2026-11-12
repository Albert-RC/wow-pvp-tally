local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Events", function()
	local ns, bus
	before_each(function()
		ns = Addon.LoadWith({})
		bus = ns.Events.New()
	end)

	it("calls every listener of an event with its arguments, in order", function()
		local calls = {}
		bus:On("X", function(a, b) calls[#calls + 1] = "first " .. a .. b end)
		bus:On("X", function(a) calls[#calls + 1] = "second " .. a end)
		bus:Fire("X", 1, 2)
		T.eq(calls, { "first 12", "second 1" })
	end)

	it("ignores events nobody listens to", function()
		bus:Fire("NOTHING")
	end)

	it("keeps going when a listener fails, and reports it", function()
		local reached = false
		bus:On("X", function() error("broken listener") end)
		bus:On("X", function() reached = true end)
		bus:Fire("X")
		T.truthy(reached)
		T.contains(ns.Util.lastError, "broken listener")
	end)

	it("rejects a listener that is not a function", function()
		T.raises(function() bus:On("X", "nope") end, "listener function expected")
	end)

	it("has one bus for the addon", function()
		T.notNil(ns.bus)
		T.notNil(ns.bus.On)
	end)
end)
