local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("Settings", function()
	local Settings
	before_each(function()
		Settings = Addon.LoadWith({}).Settings
	end)

	it("creates the defaults from nothing", function()
		local settings = Settings.Init(nil)
		T.eq(settings.notifyKills, true)
		T.eq(settings.notifyDeaths, true)
		T.eq(settings.minimap, { angle = Settings.DEFAULT_MINIMAP_ANGLE, hide = false })
	end)

	it("keeps what was saved and returns the same table", function()
		local saved = { notifyKills = false, notifyDeaths = true, minimap = { angle = 1, hide = true }, size = { 800, 600 } }
		local settings = Settings.Init(saved)
		T.truthy(settings == saved)
		T.eq(settings.notifyKills, false)
		T.eq(settings.notifyDeaths, true)
		T.eq(settings.minimap, { angle = 1, hide = true })
		T.eq(settings.size, { 800, 600 })
	end)

	it("drops options that were withdrawn (the style picker)", function()
		local settings = Settings.Init({ theme = "forever", notifyKills = false })
		T.isNil(settings.theme)
		T.eq(settings.notifyKills, false)
	end)

	describe("from the single notify switch of v1.1", function()
		it("keeps notifications off when they were off", function()
			local settings = Settings.Init({ notify = false })
			T.eq(settings.notifyKills, false)
			T.eq(settings.notifyDeaths, false)
			T.isNil(settings.notify)
		end)

		it("keeps notifications on when they were on", function()
			local settings = Settings.Init({ notify = true })
			T.eq(settings.notifyKills, true)
			T.eq(settings.notifyDeaths, true)
			T.isNil(settings.notify)
		end)

		it("does not override the new switches once they exist", function()
			local settings = Settings.Init({ notify = true, notifyKills = false, notifyDeaths = false })
			T.eq(settings.notifyKills, false)
			T.eq(settings.notifyDeaths, false)
		end)
	end)

	describe("notifications", function()
		it("switches each kind on its own", function()
			local saved = Settings.Init({})
			Settings.SetNotify(saved, "kills", false)
			T.falsy(Settings.IsNotifying(saved, "kills"))
			T.truthy(Settings.IsNotifying(saved, "deaths"))
		end)

		it("rejects an unknown kind", function()
			T.raises(function() Settings.SetNotify(Settings.Init({}), "assists", true) end, "kills or deaths")
			T.falsy(Settings.IsNotifying(Settings.Init({}), "assists"))
		end)

		it("toggles everything off when anything is on, and on otherwise", function()
			local saved = Settings.Init({ notifyKills = true, notifyDeaths = false })
			T.falsy(Settings.ToggleAllNotify(saved))
			T.eq({ saved.notifyKills, saved.notifyDeaths }, { false, false })
			T.truthy(Settings.ToggleAllNotify(saved))
			T.eq({ saved.notifyKills, saved.notifyDeaths }, { true, true })
		end)
	end)

	it("repairs broken values", function()
		local settings = Settings.Init({ notifyKills = "yes", minimap = { angle = 0 / 0 }, position = "x", size = 3 })
		T.eq(settings.notifyKills, true)
		T.eq(settings.minimap.angle, Settings.DEFAULT_MINIMAP_ANGLE)
		T.isNil(settings.position)
		T.isNil(settings.size)
	end)
end)
