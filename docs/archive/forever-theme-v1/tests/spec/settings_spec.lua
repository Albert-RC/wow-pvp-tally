local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Settings", function()
	local Settings
	before_each(function()
		Settings = Addon.LoadWith({}).Settings
	end)

	it("creates the defaults from nothing", function()
		local settings = Settings.Init(nil)
		T.eq(settings.notify, true)
		T.eq(settings.minimap, { angle = Settings.DEFAULT_MINIMAP_ANGLE, hide = false })
	end)

	it("keeps what was saved and returns the same table", function()
		local saved = { notify = false, minimap = { angle = 1, hide = true }, size = { 800, 600 } }
		local settings = Settings.Init(saved)
		T.truthy(settings == saved)
		T.eq(settings.notify, false)
		T.eq(settings.minimap, { angle = 1, hide = true })
		T.eq(settings.size, { 800, 600 })
	end)

	describe("style", function()
		it("starts with the classic style", function()
			T.eq(Settings.Init({}).theme, "classic")
			T.eq(Settings.DEFAULT_THEME, "classic")
		end)

		it("keeps a valid style and repairs an unknown one", function()
			T.eq(Settings.Init({ theme = "forever" }).theme, "forever")
			T.eq(Settings.Init({ theme = "neon" }).theme, "classic")
			T.eq(Settings.Init({ theme = 3 }).theme, "classic")
		end)
	end)

	describe("Set", function()
		local ns2, bus, fired, saved
		before_each(function()
			ns2 = Addon.LoadWith({})
			Settings = ns2.Settings
			bus = ns2.Events.New()
			fired = {}
			bus:On(ns2.Events.SETTINGS_CHANGED, function(key, value) fired[#fired + 1] = key .. "=" .. tostring(value) end)
			saved = Settings.Init({})
		end)

		it("changes a valid option and announces it", function()
			T.truthy(Settings.Set(saved, "theme", "forever", bus))
			T.eq(saved.theme, "forever")
			T.eq(fired, { "theme=forever" })
		end)

		it("refuses invalid values and unknown options", function()
			T.falsy(Settings.Set(saved, "theme", "neon", bus))
			T.falsy(Settings.Set(saved, "notify", false, bus), "only options with a validator change here")
			T.falsy(Settings.Set(saved, "whatever", 1, bus))
			T.eq(saved.theme, "classic")
			T.eq(fired, {})
		end)

		it("does nothing when the value is already set", function()
			T.falsy(Settings.Set(saved, "theme", "classic", bus))
			T.eq(fired, {})
		end)

		it("works without a bus", function()
			T.truthy(Settings.Set(saved, "theme", "forever"))
		end)
	end)

	it("repairs broken values", function()
		local settings = Settings.Init({ notify = "yes", minimap = { angle = 0 / 0 }, position = "x", size = 3 })
		T.eq(settings.notify, true)
		T.eq(settings.minimap.angle, Settings.DEFAULT_MINIMAP_ANGLE)
		T.isNil(settings.position)
		T.isNil(settings.size)
	end)
end)
