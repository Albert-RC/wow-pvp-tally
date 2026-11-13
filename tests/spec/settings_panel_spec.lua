local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("SettingsPanel", function()
	local ns, env, SettingsPanel, app, spyAvailable, imports, notifying, marking, markSize, portraits
	before_each(function()
		ns, env = Addon.LoadWith({ "UI/SettingsPanel.lua" })
		SettingsPanel = ns.SettingsPanel
		spyAvailable, imports = true, {}
		notifying = { kills = true, deaths = false }
		marking = true
		markSize = 28
		portraits = true
		app = {
			IsNotifying = function(kind) return notifying[kind] end,
			SetNotify = function(kind, enabled) notifying[kind] = enabled end,
			IsMarkingNameplates = function() return marking end,
			SetNameplateMarks = function(enabled) marking = enabled end,
			GetMarkSize = function() return markSize end,
			SetMarkSize = function(size) markSize = size end,
			IsMarkingPortraits = function() return portraits end,
			SetPortraitMarks = function(enabled) portraits = enabled end,
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

	describe("Skull section", function()
		it("has a checkbox for the skull, with its label and a note", function()
			SettingsPanel.Register(app)
			T.eq(canvas().NameplateHeader:GetText(), "Skull")
			T.contains(canvas().NameplateCheck.Text:GetText(), "skull")
			T.contains(canvas().NameplateNote:GetText(), "nameplates the game shows")
		end)

		it("shows the current setting and changes it when clicked", function()
			SettingsPanel.Register(app)
			T.truthy(canvas().NameplateCheck:GetChecked())
			canvas().NameplateCheck:Click()
			T.eq(marking, false)
			canvas().NameplateCheck:Click()
			T.eq(marking, true)
		end)

		it("offers three skull sizes and marks the one chosen", function()
			SettingsPanel.Register(app)
			T.eq(canvas().MarkSizeLabel:GetText(), "Skull size")
			local entries = canvas().MarkSizeDropdown:__menu()
			local texts, selected = {}, {}
			for index, entry in ipairs(entries) do
				texts[index] = entry.text
				selected[index] = entry.isSelected()
			end
			T.eq(texts, { "Small", "Medium", "Large" })
			T.eq(selected, { false, true, false })
		end)

		it("changes the size when one is picked", function()
			SettingsPanel.Register(app)
			canvas().MarkSizeDropdown:__menu()[3].select()
			T.eq(markSize, 36)
			canvas().MarkSizeDropdown:__menu()[1].select()
			T.eq(markSize, 22)
		end)

		it("puts long explanations in notes that wrap, and keeps the sections in order", function()
			SettingsPanel.Register(app)
			for _, note in ipairs({ "NameplateNote", "PortraitNote", "SpyDescription" }) do
				T.eq(canvas()[note].__width, 560, note .. " wraps instead of running out of the window")
			end
			T.truthy(canvas().SpyHeader.__points[1][2] == canvas().PortraitNote, "Spy below the skull section")
			T.truthy(canvas().NameplateHeader.__points[1][2] == canvas().NotifyChecks[2], "skull below the chat section")
		end)

		it("has a checkbox for the skull over the portrait of the target and focus", function()
			SettingsPanel.Register(app)
			T.contains(canvas().PortraitCheck.Text:GetText(), "portrait of your target and focus")
			T.contains(canvas().PortraitNote:GetText(), "another addon replaces the nameplates")
			T.truthy(canvas().PortraitCheck:GetChecked())
			canvas().PortraitCheck:Click()
			T.eq(portraits, false)
			portraits = true
			SettingsPanel.Refresh()
			T.truthy(canvas().PortraitCheck:GetChecked())
		end)

		it("follows changes made elsewhere when refreshed", function()
			SettingsPanel.Register(app)
			local generated = canvas().MarkSizeDropdown.__generated or 0
			marking = false
			SettingsPanel.Refresh()
			T.falsy(canvas().NameplateCheck:GetChecked())
			T.eq(canvas().MarkSizeDropdown.__generated, generated + 1, "the dropdown shows the size again")
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
