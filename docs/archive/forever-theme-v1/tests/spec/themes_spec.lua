local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

local function everyAtlas() return true end
local function noAtlas() return false end

describe("Themes", function()
	local ns, Themes
	before_each(function()
		ns = Addon.LoadWith({ "UI/Columns.lua", "UI/Themes.lua" })
		Themes = ns.Themes
	end)

	it("defines every style the options offer, with a column set", function()
		for _, name in ipairs(ns.Settings.THEMES) do
			local definition = Themes.DEFINITIONS[name]
			T.notNil(definition, name)
			T.notNil(ns.Columns.SETS[definition.columns], name .. " columns")
		end
	end)

	describe("classic", function()
		it("is the original look", function()
			local theme = Themes.Resolve("classic", noAtlas)
			T.eq(theme.name, "classic")
			T.eq(theme.columns, "classic")
			T.eq(theme.headerStyle, "tabs")
			T.isNil(theme.listBackground)
			T.isNil(theme.playerBox)
			T.isNil(theme.scoreBar)
			T.falsy(theme.expandOnRight)
			T.truthy(theme.stripes)
			T.truthy(theme.detailBand)
			T.contains(theme.highlight.file, "UI-QuestTitleHighlight")
		end)
	end)

	describe("forever", function()
		it("uses the Skills window art when the client has it", function()
			local theme = Themes.Resolve("forever", everyAtlas)
			T.eq(theme.name, "forever")
			T.eq(theme.columns, "forever")
			T.eq(theme.headerStyle, "strip")
			T.eq(theme.listBackground, { atlas = "UI-Character-Info-General-BG" })
			T.eq(theme.playerBox, { atlas = "common-button-list-collapseExpand" })
			T.eq(theme.expandIcons.collapsed, { atlas = "common-button-list-plus" })
			T.eq(theme.expandIcons.expanded, { atlas = "common-button-list-minus" })
			T.eq(theme.highlightSide.atlas, "charactercreate-customize-dropdown-linemouseover-side")
			T.truthy(theme.highlight.alpha < 0.5 and theme.highlightSide.alpha < 0.5, "the highlight must not cover the row")
			T.eq(theme.scoreBar.kills, { atlas = "common-stat-bar-green" })
			T.eq(theme.scoreBar.deaths, { atlas = "common-stat-bar-red" })
			T.truthy(theme.expandOnRight)
			T.falsy(theme.stripes)
			T.falsy(theme.detailBand)
		end)

		it("draws every piece the classic way when no atlas exists, but keeps its columns", function()
			local theme = Themes.Resolve("forever", noAtlas)
			local classic = Themes.DEFINITIONS.classic
			T.eq(theme.columns, "forever")
			T.isNil(theme.listBackground)
			T.isNil(theme.listEdge)
			T.isNil(theme.headerStrip)
			T.isNil(theme.playerBox)
			T.isNil(theme.scoreBar, "the score shows as text")
			T.truthy(theme.expandIcons == classic.expandIcons)
			T.truthy(theme.highlight == classic.highlight)
			T.isNil(theme.highlightSide)
		end)

		it("replaces only the piece whose atlas is missing", function()
			local theme = Themes.Resolve("forever", function(atlas) return atlas ~= "common-stat-bar-red" end)
			T.isNil(theme.scoreBar, "the whole bar needs all its parts")
			T.eq(theme.playerBox, { atlas = "common-button-list-collapseExpand" })
			T.notNil(theme.listBackground)
		end)

		it("keeps the highlight pieces together", function()
			local theme = Themes.Resolve("forever", function(atlas) return not atlas:find("linemouseover%-side") end)
			T.contains(theme.highlight.file, "UI-QuestTitleHighlight")
			T.isNil(theme.highlightSide)
		end)
	end)

	it("falls back to the default style for an unknown name", function()
		T.eq(Themes.Resolve("neon", everyAtlas).name, ns.Settings.DEFAULT_THEME)
		T.eq(Themes.Resolve(nil, everyAtlas).name, ns.Settings.DEFAULT_THEME)
	end)

	it("returns a new table and never changes the definitions", function()
		local first = Themes.Resolve("forever", noAtlas)
		T.falsy(first == Themes.DEFINITIONS.forever)
		T.notNil(Themes.DEFINITIONS.forever.scoreBar, "the definition keeps its bar")
		T.notNil(Themes.Resolve("forever", everyAtlas).scoreBar)
	end)
end)
