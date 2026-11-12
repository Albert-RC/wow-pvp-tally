local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Util", function()
	local ns, env, Util
	before_each(function()
		ns, env = Addon.LoadWith({})
		Util = ns.Util
	end)

	describe("Readable", function()
		it("passes plain values through", function()
			T.eq(Util.Readable("Kane"), "Kane")
			T.eq(Util.Readable(25), 25)
			T.eq(Util.Readable(false), false)
		end)

		it("turns secret values into nil", function()
			T.isNil(Util.Readable(env.Secret("Kane")))
			T.truthy(Util.IsSecret(env.Secret(1)))
		end)

		it("works when the client has no secret values at all", function()
			env.issecretvalue = nil
			T.eq(Util.Readable("x"), "x")
			T.falsy(Util.IsSecret("x"))
		end)
	end)

	describe("Guard", function()
		it("returns true and runs the function", function()
			local ran
			T.truthy(Util.Guard("label", function(value) ran = value end)(7))
			T.eq(ran, 7)
		end)

		it("keeps the error instead of raising it", function()
			local guarded = Util.Guard("Scan", function() error("boom") end)
			T.falsy(guarded())
			T.contains(Util.lastError, "Scan")
			T.contains(Util.lastError, "boom")
		end)
	end)

	describe("text", function()
		it("shows a player key with a space", function()
			T.eq(Util.DisplayName("Cabo-Trancas"), "Cabo Trancas")
			T.eq(Util.DisplayName("Mono"), "Mono")
			T.eq(Util.DisplayName("Test-Elfo de la noche hombre"), "Test Elfo de la noche hombre")
		end)

		it("trims", function()
			T.eq(Util.Trim("  test clear \n"), "test clear")
			T.eq(Util.Trim(nil), "")
		end)

		it("colors a name with the class color", function()
			T.eq(Util.ColoredName("Cabo-Trancas", "MAGE"), "|cff40c7ebCabo Trancas|r")
		end)

		it("uses gold for an unknown class", function()
			local r, g, b = Util.ClassColor(nil)
			T.eq({ r, g, b }, { 1, 0.82, 0 })
		end)

		it("formats dates short and long", function()
			local t = os.time({ year = 2026, month = 11, day = 12, hour = 18, min = 42 })
			T.eq(Util.FormatDate(t), "12/11/26 18:42")
			T.eq(Util.FormatDate(t, true), "12/11/2026 18:42")
			T.eq(Util.FormatDate(nil), "-")
		end)
	end)

	describe("numbers", function()
		it("clamps", function()
			T.eq(Util.Clamp(5, 1, 3), 3)
			T.eq(Util.Clamp(-5, 1, 3), 1)
			T.eq(Util.Clamp(2, 1, 3), 2)
		end)

		it("rejects NaN and infinities", function()
			T.truthy(Util.IsFiniteNumber(1.5))
			T.falsy(Util.IsFiniteNumber(0 / 0))
			T.falsy(Util.IsFiniteNumber(math.huge))
			T.falsy(Util.IsFiniteNumber("1"))
		end)
	end)

	it("prints to the chat with the addon name", function()
		Util.Print("hello")
		T.eq(env.__chat[1], "|cffffd100PvP Tally:|r hello")
	end)
end)
