local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each
local Wow = require("wow")

describe("SettingsPanel", function()
	local ns, env, SettingsPanel, app, changes
	before_each(function()
		ns, env = Addon.LoadWith({ "UI/SettingsPanel.lua" })
		SettingsPanel = ns.SettingsPanel
		changes = {}
		app = {
			settings = ns.Settings.Init({}),
			SetSetting = function(key, value)
				changes[#changes + 1] = key .. "=" .. value
				return ns.Settings.Set(app.settings, key, value)
			end,
		}
	end)

	local function canvas()
		return env.__settings.registered[1].frame
	end

	it("adds a PvP Tally panel to Options > AddOns", function()
		T.truthy(SettingsPanel.Register(app))
		T.eq(#env.__settings.registered, 1)
		T.eq(env.__settings.registered[1].name, "PvP Tally")
		T.eq(canvas().Title:GetText(), "PvP Tally")
	end)

	it("gives the Options window the handlers it calls", function()
		SettingsPanel.Register(app)
		for _, handler in ipairs({ "OnCommit", "OnDefault", "OnRefresh" }) do
			T.eq(type(canvas()[handler]), "function", handler)
			canvas()[handler]()
		end
	end)

	describe("style dropdown", function()
		before_each(function()
			SettingsPanel.Register(app)
		end)

		it("offers every style, in order, with its label", function()
			local items = Wow.MenuItems(canvas().ThemeDropdown)
			T.eq(#items, #ns.Settings.THEMES)
			T.eq({ items[1].data, items[2].data }, { "classic", "forever" })
			T.eq({ items[1].text, items[2].text }, { "Classic", "Forever" })
			T.eq(canvas().ThemeLabel:GetText(), "Style")
		end)

		it("marks the current style", function()
			local items = Wow.MenuItems(canvas().ThemeDropdown)
			T.truthy(items[1].IsSelected())
			T.falsy(items[2].IsSelected())
		end)

		it("changes the style through the app", function()
			local items = Wow.MenuItems(canvas().ThemeDropdown)
			items[2].Select()
			T.eq(changes, { "theme=forever" })
			T.eq(app.settings.theme, "forever")
			T.truthy(Wow.MenuItems(canvas().ThemeDropdown)[2].IsSelected())
		end)
	end)

	it("registers once", function()
		SettingsPanel.Register(app)
		SettingsPanel.Register(app)
		T.eq(#env.__settings.registered, 1)
	end)

	it("opens the Options window on its own panel", function()
		SettingsPanel.Register(app)
		T.truthy(SettingsPanel.Open())
		T.eq(env.__settings.opened, { env.__settings.registered[1]:GetID() })
	end)

	it("cannot open before it is registered", function()
		T.falsy(SettingsPanel.Open())
		T.eq(env.__settings.opened, {})
	end)

	it("does nothing on a client without the Settings API", function()
		env.Settings = nil
		T.falsy(SettingsPanel.IsSupported())
		T.falsy(SettingsPanel.Register(app))
		T.falsy(SettingsPanel.Open())
	end)

	it("falls back to the style's name when it has no label", function()
		T.eq(SettingsPanel.ThemeLabel("neon"), "neon")
	end)
end)
