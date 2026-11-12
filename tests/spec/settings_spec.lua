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

	it("drops options that were withdrawn (the style picker)", function()
		local settings = Settings.Init({ theme = "forever", notify = false })
		T.isNil(settings.theme)
		T.eq(settings.notify, false)
	end)

	it("repairs broken values", function()
		local settings = Settings.Init({ notify = "yes", minimap = { angle = 0 / 0 }, position = "x", size = 3 })
		T.eq(settings.notify, true)
		T.eq(settings.minimap.angle, Settings.DEFAULT_MINIMAP_ANGLE)
		T.isNil(settings.position)
		T.isNil(settings.size)
	end)
end)
