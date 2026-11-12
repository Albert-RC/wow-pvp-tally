-- PvP Tally: the rows of the list (widgets). One frame type serves every row kind of
-- ListModel and every theme; frames are recycled by the ScrollBox, so Init sets every
-- piece each time, showing what the theme asks for and hiding the rest.
--
-- Rows get what they need through `view`:
--   layout    the Columns.Layout in use
--   theme     the resolved theme (Themes.Resolve)
--   expanded  { [key] = true } for players shown open
--   races     the icon resolver (race, faction and class icons)
--   OnToggle(key), OnDelete(key)

local _, ns = ...
local L, Util, ListModel = ns.L, ns.Util, ns.ListModel

local Rows = {}
ns.Rows = Rows

Rows.HEIGHT = 34
local EXPAND_SIZE = 18
local CLASS_ICON_SIZE = 26
local RACE_ICON_SIZE = 30
local FACTION_BADGE_SIZE = 16
local RESULT_ICON_SIZE = 20
local SCORE_BAR_HEIGHT = 16
local HIGHLIGHT_SIDE_WIDTH = 16
local BOX_INSET = 2 -- the Forever player box leaves this much room around it

local GREEN = { 0.25, 1, 0.25 }
local RED = { 1, 0.3, 0.3 }
local GREY = { 0.5, 0.5, 0.5 }
local WHITE = { 1, 1, 1 }
local GOLD = { 1, 0.82, 0 }

local function SetColor(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3])
end

-- Draws an icon descriptor ({ atlas, useAtlasSize } or { file, coords, blend, alpha })
-- on a texture. Frames are recycled, so every property is set again.
function Rows.ApplyIcon(texture, icon)
	if icon.atlas then
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetAtlas(icon.atlas, icon.useAtlasSize == true)
	else
		texture:SetTexture(icon.file)
		texture:SetTexCoord(unpack(icon.coords or { 0, 1, 0, 1 }))
	end
	texture:SetBlendMode(icon.blend or "BLEND")
	texture:SetAlpha(icon.alpha or 1)
end

-- Shows a texture with a piece, or hides it when the theme has none.
local function ShowPiece(texture, piece)
	texture:SetShown(piece ~= nil)
	if piece then
		Rows.ApplyIcon(texture, piece)
	end
end

-- Tooltips ----------------------------------------------------------------------------------------

local function ShowPlayerTooltip(row, item)
	local player = item.player
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Util.DisplayName(item.key), Util.ClassColor(player.class))
	local className = player.class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[player.class]
	local parts = {}
	if player.level then parts[#parts + 1] = LEVEL .. " " .. player.level end
	if player.race then parts[#parts + 1] = player.race end
	if className then parts[#parts + 1] = className end
	if #parts > 0 then
		GameTooltip:AddLine(table.concat(parts, " "), 1, 1, 1)
	end
	if player.guild then
		GameTooltip:AddLine("<" .. player.guild .. ">", 1, 1, 1)
	end
	if player.faction then
		GameTooltip:AddLine(_G["FACTION_" .. player.faction:upper()] or player.faction, 0.8, 0.8, 0.8)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(L.COL_KILLS, item.kills, GOLD[1], GOLD[2], GOLD[3], GREEN[1], GREEN[2], GREEN[3])
	GameTooltip:AddDoubleLine(L.COL_DEATHS, item.deaths, GOLD[1], GOLD[2], GOLD[3], RED[1], RED[2], RED[3])
	if player.first then
		GameTooltip:AddDoubleLine(L.TT_FIRST, Util.FormatDate(player.first, true), GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)
	end
	if player.last then
		GameTooltip:AddDoubleLine(L.TT_LAST, Util.FormatDate(player.last, true), GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L.TT_HINT, 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

local function ShowFightTooltip(row, data)
	local encounter = data.encounter
	local won = encounter.r == ns.Store.KILL
	local color = won and GREEN or RED
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine((won and L.WIN or L.LOSS) .. " - " .. Util.DisplayName(data.key), color[1], color[2], color[3])
	GameTooltip:AddLine(Util.FormatDate(encounter.t, true), 1, 1, 1)
	GameTooltip:AddLine(ListModel.ZoneText(encounter), 1, 1, 1)
	if encounter.x and encounter.y then
		GameTooltip:AddLine(L.TT_COORDS:format(encounter.x * 100, encounter.y * 100), 0.8, 0.8, 0.8)
	end
	local how = encounter.how and rawget(L, "HOW_" .. encounter.how)
	if how then
		GameTooltip:AddLine(how, 0.6, 0.6, 0.6, true)
	end
	GameTooltip:Show()
end

-- Setup ---------------------------------------------------------------------------------------------

local function MakeCells(row, columns, font)
	local cells = {}
	for _, column in ipairs(columns) do
		local cell = row:CreateFontString(nil, "ARTWORK", font)
		cell:SetJustifyH(column.justify)
		cell:SetWordWrap(false)
		cells[column.key] = cell
	end
	return cells
end

local function OnClick(row, button)
	local data, view = row.data, row.view
	if not data or data.kind ~= "player" or not view then
		return
	end
	if button == "RightButton" then
		view.OnDelete(data.key)
	else
		view.OnToggle(data.key)
	end
end

local function OnEnter(row)
	local data = row.data
	if data and data.kind == "player" then
		ShowPlayerTooltip(row, data)
	elseif data and data.kind == "fight" then
		ShowFightTooltip(row, data)
	end
end

local function OnLeave()
	GameTooltip:Hide()
end

-- The kills / deaths bar of the Forever theme: background, red (deaths) under green
-- (kills), all cut by the bar mask, and the "3 / 1" text.
local function CreateScoreBar(row)
	local bar = {}
	bar.Background = row:CreateTexture(nil, "ARTWORK", nil, 1)
	bar.Deaths = row:CreateTexture(nil, "ARTWORK", nil, 2)
	bar.Kills = row:CreateTexture(nil, "ARTWORK", nil, 3)
	bar.Mask = row:CreateMaskTexture()
	bar.Mask:SetAllPoints(bar.Background)
	bar.Deaths:SetAllPoints(bar.Background)
	bar.Deaths:AddMaskTexture(bar.Mask)
	bar.Kills:AddMaskTexture(bar.Mask)
	bar.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	bar.Text:SetPoint("CENTER", bar.Background, "CENTER")
	return bar
end

-- Creates the widgets of a row frame, once: the pieces of every theme.
function Rows.Setup(row)
	if row.cells then
		return
	end
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	row.Background = row:CreateTexture(nil, "BACKGROUND")
	row.Background:SetAllPoints()

	-- Forever: the gold box behind a player.
	row.Box = row:CreateTexture(nil, "BACKGROUND", nil, 1)
	row.Box:SetPoint("TOPLEFT", BOX_INSET, -BOX_INSET)
	row.Box:SetPoint("BOTTOMRIGHT", -BOX_INSET, BOX_INSET)

	-- Mouse-over highlight: one stretched texture (classic) or three pieces (Forever).
	row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
	row.HighlightLeft = row:CreateTexture(nil, "HIGHLIGHT")
	row.HighlightLeft:SetPoint("TOPLEFT")
	row.HighlightLeft:SetPoint("BOTTOMLEFT")
	row.HighlightLeft:SetWidth(HIGHLIGHT_SIDE_WIDTH)
	row.HighlightRight = row:CreateTexture(nil, "HIGHLIGHT")
	row.HighlightRight:SetPoint("TOPRIGHT")
	row.HighlightRight:SetPoint("BOTTOMRIGHT")
	row.HighlightRight:SetWidth(HIGHLIGHT_SIDE_WIDTH)

	row.Expand = row:CreateTexture(nil, "ARTWORK")
	row.Expand:SetSize(EXPAND_SIZE, EXPAND_SIZE)

	row.ClassIcon = row:CreateTexture(nil, "ARTWORK")
	row.ClassIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)

	row.ResultIcon = row:CreateTexture(nil, "ARTWORK")
	row.ResultIcon:SetSize(RESULT_ICON_SIZE, RESULT_ICON_SIZE)
	row.ResultIcon:SetPoint("LEFT", ns.Columns.DETAIL_INDENT + 2, 0)

	row.cells = MakeCells(row, ns.Columns.AllPlayerColumns(), "GameFontHighlight")
	row.cells.name:SetFontObject("GameFontNormal")

	row.RaceIcon = row:CreateTexture(nil, "ARTWORK")
	row.RaceIcon:SetSize(RACE_ICON_SIZE, RACE_ICON_SIZE)
	row.RaceIcon:SetPoint("CENTER", row.cells.race, "CENTER")

	-- Faction badge on the race icon, for races both factions can play (Skyborne).
	row.FactionIcon = row:CreateTexture(nil, "OVERLAY")
	row.FactionIcon:SetSize(FACTION_BADGE_SIZE, FACTION_BADGE_SIZE)
	row.FactionIcon:SetPoint("BOTTOMRIGHT", row.RaceIcon, "BOTTOMRIGHT", 6, -2)

	row.Score = CreateScoreBar(row)

	row.detail = MakeCells(row, ns.Columns.DETAIL, "GameFontHighlightSmall")

	row.Extra = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	row.Extra:SetPoint("LEFT", ns.Columns.DETAIL_INDENT + 4, 0)
	row.Extra:SetPoint("RIGHT", -4, 0)
	row.Extra:SetJustifyH("LEFT")

	row:SetScript("OnClick", OnClick)
	row:SetScript("OnEnter", OnEnter)
	row:SetScript("OnLeave", OnLeave)
end

-- Layout --------------------------------------------------------------------------------------------

local function PlaceCells(row, cells, columns)
	for _, column in ipairs(columns) do
		local cell = cells[column.key]
		cell:ClearAllPoints()
		cell:SetPoint("LEFT", row, "LEFT", column.x + 4, 0)
		cell:SetWidth(column.width - 8)
	end
end

local function PlaceHighlight(row, theme)
	row.Highlight:ClearAllPoints()
	if theme.highlightSide then
		row.Highlight:SetPoint("TOPLEFT", row.HighlightLeft, "TOPRIGHT")
		row.Highlight:SetPoint("BOTTOMRIGHT", row.HighlightRight, "BOTTOMLEFT")
	else
		row.Highlight:SetAllPoints()
	end
	ShowPiece(row.Highlight, theme.highlight)
	ShowPiece(row.HighlightLeft, theme.highlightSide)
	ShowPiece(row.HighlightRight, theme.highlightSide)
	if theme.highlightSide then
		row.HighlightRight:SetRotation(math.pi) -- the right end is the left one turned round
	end
end

-- Puts every piece where a layout and a theme say. Cheap when neither changed.
function Rows.Layout(row, layout, theme)
	if row.layout == layout and row.theme == theme then
		return
	end
	row.layout, row.theme = layout, theme
	PlaceCells(row, row.cells, layout.player)
	PlaceCells(row, row.detail, layout.detail)
	row.detailShifted = nil

	-- The +/- goes left of the class icon (classic) or in its own column on the right.
	local iconLeft = 4
	row.Expand:ClearAllPoints()
	if theme.expandOnRight and layout.player.toggle then
		row.Expand:SetPoint("CENTER", row.cells.toggle, "CENTER")
	else
		row.Expand:SetPoint("LEFT", 4, 0)
		iconLeft = 4 + EXPAND_SIZE + 4
	end
	row.ClassIcon:ClearAllPoints()
	row.ClassIcon:SetPoint("LEFT", iconLeft, 0)
	local nameOffset = iconLeft + CLASS_ICON_SIZE + 6
	row.cells.name:ClearAllPoints()
	row.cells.name:SetPoint("LEFT", row, "LEFT", nameOffset, 0)
	row.cells.name:SetWidth(layout.player.name.width - nameOffset - 2)

	local score = layout.player.score
	if score then
		row.Score.Background:ClearAllPoints()
		row.Score.Background:SetPoint("LEFT", row, "LEFT", score.x + 4, 0)
		row.Score.Background:SetSize(score.width - 8, SCORE_BAR_HEIGHT)
		row.Score.Kills:ClearAllPoints()
		row.Score.Kills:SetPoint("TOPLEFT", row.Score.Background, "TOPLEFT")
		row.Score.Kills:SetPoint("BOTTOMLEFT", row.Score.Background, "BOTTOMLEFT")
	end

	PlaceHighlight(row, theme)
end

-- Moves the result cell of a fight row after its icon, or back for the header row.
local function ShiftResult(row, layout, shifted)
	if row.detailShifted == shifted then
		return
	end
	row.detailShifted = shifted
	local column = layout.detail.result
	local offset = shifted and (RESULT_ICON_SIZE + 6) or 4
	local cell = row.detail.result
	cell:ClearAllPoints()
	cell:SetPoint("LEFT", row, "LEFT", column.x + offset, 0)
	cell:SetWidth(column.width - offset - 4)
end

-- Filling -------------------------------------------------------------------------------------------

local function HideAll(list)
	for _, item in pairs(list) do
		item:Hide()
	end
end

-- Shows the cells of the active columns only.
local function ShowColumns(row, columns)
	HideAll(row.cells)
	for _, column in ipairs(columns) do
		row.cells[column.key]:Show()
	end
end

local function HideScore(row)
	for _, piece in pairs(row.Score) do
		piece:Hide()
	end
end

local function FillScore(row, data, theme, width)
	local bar = theme.scoreBar
	if not bar then
		-- No bar art: the score column shows the numbers.
		HideScore(row)
		row.cells.score:SetText(ListModel.ScoreText(data.kills, data.deaths))
		SetColor(row.cells.score, WHITE)
		return
	end
	row.cells.score:SetText("")
	local score = row.Score
	Rows.ApplyIcon(score.Background, bar.background)
	Rows.ApplyIcon(score.Deaths, bar.deaths)
	Rows.ApplyIcon(score.Kills, bar.kills)
	-- A mask texture only takes the shape: no blend mode or alpha.
	if bar.mask.atlas then
		score.Mask:SetAtlas(bar.mask.atlas)
	else
		score.Mask:SetTexture(bar.mask.file)
	end
	score.Background:Show()
	score.Mask:Show()
	score.Text:Show()
	-- With no fights at all the bar stays empty: neither green nor red.
	local share = ListModel.KillShare(data.kills, data.deaths)
	score.Deaths:SetShown(data.kills + data.deaths > 0)
	score.Kills:SetShown(share > 0)
	score.Kills:SetWidth(math.max(1, width * share))
	score.Text:SetText(ListModel.ScoreText(data.kills, data.deaths))
end

local function FillPlayer(row, data, view)
	local player, theme = data.player, view.theme
	ShowColumns(row, view.layout.player)

	if theme.stripes and data.index % 2 == 0 then
		row.Background:SetColorTexture(1, 1, 1, 0.05)
	else
		row.Background:SetColorTexture(0, 0, 0, 0)
	end
	ShowPiece(row.Box, theme.playerBox)

	row.Expand:Show()
	local icons = theme.expandIcons
	Rows.ApplyIcon(row.Expand, view.expanded[data.key] and icons.expanded or icons.collapsed)

	row.ClassIcon:Show()
	Rows.ApplyIcon(row.ClassIcon, view.races:ClassIcon(player.class))

	local raceIcon = view.races:Icon(player)
	row.RaceIcon:SetShown(raceIcon ~= nil)
	if raceIcon then
		Rows.ApplyIcon(row.RaceIcon, raceIcon)
	end
	local badge = raceIcon and view.races:FactionBadge(player)
	row.FactionIcon:SetShown(badge ~= nil)
	if badge then
		Rows.ApplyIcon(row.FactionIcon, badge)
	end

	local cells = row.cells
	cells.name:SetText(data.name)
	cells.name:SetTextColor(Util.ClassColor(player.class))
	cells.level:SetText(ListModel.LevelText(player.level))
	SetColor(cells.level, WHITE)
	cells.guild:SetText(player.guild and ("<" .. player.guild .. ">") or "")
	SetColor(cells.guild, GREY)
	cells.kills:SetText(data.kills)
	SetColor(cells.kills, data.kills > 0 and GREEN or GREY)
	cells.deaths:SetText(data.deaths)
	SetColor(cells.deaths, data.deaths > 0 and RED or GREY)
	cells.first:SetText(Util.FormatDate(data.first))
	SetColor(cells.first, WHITE)
	cells.toggle:SetText("")

	local score = view.layout.player.score
	if score then
		FillScore(row, data, theme, score.width - 8)
	else
		HideScore(row)
	end
end

local function FillHeader(row, view)
	for _, column in ipairs(view.layout.detail) do
		row.detail[column.key]:SetText(column.label)
		SetColor(row.detail[column.key], GOLD)
	end
	ShiftResult(row, view.layout, false)
end

local function FillFight(row, data, view)
	local encounter = data.encounter
	local won = encounter.r == ns.Store.KILL
	local cells = row.detail
	ShiftResult(row, view.layout, true)
	row.ResultIcon:SetTexture(won and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-NotReady")
	cells.result:SetText(won and L.WIN or L.LOSS)
	SetColor(cells.result, won and GREEN or RED)
	cells.date:SetText(Util.FormatDate(encounter.t, true))
	cells.zone:SetText(ListModel.ZoneText(encounter))
	cells.opp:SetText(ListModel.LevelText(encounter.oppLevel))
	cells.mine:SetText(ListModel.LevelText(encounter.myLevel))
	for _, key in ipairs({ "date", "zone", "opp", "mine" }) do
		SetColor(cells[key], WHITE)
	end
end

-- Shows one ListModel row on a frame.
function Rows.Init(row, data, view)
	Rows.Setup(row)
	Rows.Layout(row, view.layout, view.theme)
	row.data, row.view = data, view

	local kind = data.kind
	if kind == "player" then
		HideAll(row.detail)
		row.ResultIcon:Hide()
		row.Extra:Hide()
		FillPlayer(row, data, view)
		return
	end

	-- Inside an expanded player.
	HideAll(row.cells)
	HideScore(row)
	for _, piece in ipairs({ row.Box, row.Expand, row.ClassIcon, row.RaceIcon, row.FactionIcon }) do
		piece:Hide()
	end
	if view.theme.detailBand then
		row.Background:SetColorTexture(0, 0, 0, 0.35)
	else
		row.Background:SetColorTexture(0, 0, 0, 0)
	end
	for _, cell in pairs(row.detail) do
		cell:SetShown(kind == "fight" or kind == "header")
	end
	row.ResultIcon:SetShown(kind == "fight")
	row.Extra:SetShown(kind == "extra")

	if kind == "header" then
		FillHeader(row, view)
	elseif kind == "fight" then
		FillFight(row, data, view)
	elseif kind == "extra" then
		row.Extra:SetText(L.EXTRA:format(data.kills, data.deaths))
	end
end
