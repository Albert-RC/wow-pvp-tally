local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("SettingsPanel", function()
	local ns, env, SettingsPanel, app, spyAvailable, imports, notifying
	before_each(function()
		ns, env = Addon.LoadWith({ "UI/SettingsPanel.lua" })
		SettingsPanel = ns.SettingsPanel
		spyAvailable, imports = true, {}
		notifying = { kills = true, deaths = false }
		app = {
			IsNotifying = function(kind) return notifying[kind] end,
			SetNotify = function(kind, enabled) notifying[kind] = enabled end,
			IsSpyAvailable = function() return spyAvailable end,
			ImportFromSpy = function(silent) imports[#imports + 1] = silent end,
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

	describe("Chat section", function()
		local function check(kind)
			for _, box in ipairs(canvas().NotifyChecks) do
				if box.kind == kind then return box end
			end
		end

		it("has a checkbox for kills and one for deaths, with their labels", function()
			SettingsPanel.Register(app)
			T.eq(canvas().ChatHeader:GetText(), "Chat")
			T.eq(#canvas().NotifyChecks, 2)
			T.contains(check("kills").Text:GetText(), "every kill")
			T.contains(check("deaths").Text:GetText(), "every death")
		end)

		it("shows the current settings", function()
			SettingsPanel.Register(app)
			T.truthy(check("kills"):GetChecked())
			T.falsy(check("deaths"):GetChecked())
		end)

		it("changes the setting when clicked", function()
			SettingsPanel.Register(app)
			check("kills"):Click()
			T.eq(notifying.kills, false)
			check("deaths"):Click()
			T.eq(notifying.deaths, true)
		end)

		it("follows changes made elsewhere (/tally notify) when refreshed", function()
			SettingsPanel.Register(app)
			notifying.kills, notifying.deaths = false, true
			SettingsPanel.Refresh()
			T.falsy(check("kills"):GetChecked())
			T.truthy(check("deaths"):GetChecked())
		end)
	end)

	describe("Spy section", function()
		it("explains the import and offers the button", function()
			SettingsPanel.Register(app)
			T.eq(canvas().SpyHeader:GetText(), "Spy")
			T.contains(canvas().SpyDescription:GetText(), "Spy recorded")
			T.eq(canvas().ImportButton:GetText(), "Import from Spy")
		end)

		it("imports when the button is clicked, with messages in the chat", function()
			SettingsPanel.Register(app)
			canvas().ImportButton:RunScript("OnClick")
			T.eq(imports, { false })
		end)

		it("is enabled only while Spy's data is loaded, and says why not", function()
			spyAvailable = false
			SettingsPanel.Register(app)
			T.falsy(canvas().ImportButton.__enabled)
			T.truthy(canvas().SpyMissing:IsShown())

			spyAvailable = true
			canvas():RunScript("OnShow") -- the panel checks again each time it opens
			T.truthy(canvas().ImportButton.__enabled)
			T.falsy(canvas().SpyMissing:IsShown())
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
		SettingsPanel.Refresh() -- nothing to refresh, no error
	end)
end)
