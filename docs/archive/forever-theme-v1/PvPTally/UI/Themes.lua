-- PvP Tally: visual styles. Pure data and logic, no widgets: each theme says which
-- columns the list has and how every piece is drawn; Window and Rows only follow it.
--
--   classic  the original look: grey inset, Who list column tabs, +/- on the left,
--            striped rows, kills and deaths as numbers.
--   forever  the game's own Skills window (Character > Skills on Forever): textured
--            background, each player a gold box with +/- on the right, grey line
--            highlight, a green / red bar for kills and deaths.
--
-- Pieces are icon descriptors ({ atlas } or { file, coords, blend, alpha }), drawn with
-- Rows.ApplyIcon. Every Forever atlas was seen in game; still, Resolve checks them and a
-- missing one falls back to the classic piece, so a client change never breaks the window.

local _, ns = ...

local Themes = {}
ns.Themes = Themes

local HIGHLIGHT_ALPHA = 0.2 -- the Forever row highlight: a faint grey, as in the Skills window

Themes.DEFINITIONS = {
	classic = {
		columns = "classic",
		headerStyle = "tabs",          -- Who list column tabs
		headerStrip = nil,
		listBackground = nil,          -- nil: the inset's own grey background and border
		listEdge = nil,
		expandOnRight = false,
		expandIcons = {
			collapsed = { file = "Interface\\Buttons\\UI-PlusButton-Up" },
			expanded = { file = "Interface\\Buttons\\UI-MinusButton-Up" },
		},
		playerBox = nil,
		stripes = true,                -- every other player row lighter
		detailBand = true,             -- dark band behind the fights of an open player
		highlight = { file = "Interface\\QuestFrame\\UI-QuestTitleHighlight", blend = "ADD", alpha = 0.6 },
		highlightSide = nil,
		scoreBar = nil,
	},
	forever = {
		columns = "forever",
		headerStyle = "strip",         -- plain gold titles on a line, like the Skills headers
		headerStrip = { atlas = "UI-Character-Info-ScrollLine-Long" },
		listBackground = { atlas = "UI-Character-Info-General-BG" },
		listEdge = { atlas = "UI-Character-Info-ScrollLine-Long", useAtlasSize = true },
		expandOnRight = true,
		expandIcons = {
			collapsed = { atlas = "common-button-list-plus" },
			expanded = { atlas = "common-button-list-minus" },
		},
		playerBox = { atlas = "common-button-list-collapseExpand" },
		stripes = false,
		detailBand = false,
		-- The line art is white: at full alpha it covers the row (seen in game). The Skills
		-- window shows it as a faint grey.
		highlight = { atlas = "charactercreate-customize-dropdown-linemouseover-middle", alpha = HIGHLIGHT_ALPHA },
		highlightSide = { atlas = "charactercreate-customize-dropdown-linemouseover-side", alpha = HIGHLIGHT_ALPHA },
		scoreBar = {
			background = { atlas = "common-stat-bar-BG" },
			mask = { atlas = "common-stat-bar-Mask" },
			kills = { atlas = "common-stat-bar-green" },
			deaths = { atlas = "common-stat-bar-red" },
		},
	},
}

-- Whether a piece can be drawn: no piece, a file, or an atlas the client has.
local function Available(piece, atlasExists)
	if piece == nil or piece.file ~= nil then
		return true
	end
	return piece.atlas ~= nil and atlasExists(piece.atlas) == true
end

local function AllAvailable(pieces, atlasExists)
	for _, piece in pairs(pieces) do
		if not Available(piece, atlasExists) then
			return false
		end
	end
	return true
end

-- The theme to draw for a style name: a new table with its name, every piece checked.
-- An unknown name gives the default style; a missing atlas gives the classic piece.
function Themes.Resolve(name, atlasExists)
	if not Themes.DEFINITIONS[name] then
		name = ns.Settings.DEFAULT_THEME
	end
	local definition, classic = Themes.DEFINITIONS[name], Themes.DEFINITIONS.classic
	local theme = { name = name }
	for key, value in pairs(definition) do
		theme[key] = value
	end

	if not (Available(theme.listBackground, atlasExists) and Available(theme.listEdge, atlasExists)) then
		theme.listBackground, theme.listEdge = classic.listBackground, classic.listEdge
	end
	if not Available(theme.headerStrip, atlasExists) then
		theme.headerStrip = nil -- the titles still show, without the line
	end
	if not AllAvailable(theme.expandIcons, atlasExists) then
		theme.expandIcons = classic.expandIcons
	end
	if not Available(theme.playerBox, atlasExists) then
		theme.playerBox = nil
	end
	if not (Available(theme.highlight, atlasExists) and Available(theme.highlightSide, atlasExists)) then
		theme.highlight, theme.highlightSide = classic.highlight, classic.highlightSide
	end
	if theme.scoreBar and not AllAvailable(theme.scoreBar, atlasExists) then
		theme.scoreBar = nil -- the score column shows "kills / deaths" as text
	end
	return theme
end
