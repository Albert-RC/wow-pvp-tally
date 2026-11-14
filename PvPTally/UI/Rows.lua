-- PvP Tally: the rows of the list (widgets). One frame type serves every row kind of
-- ListModel; frames are recycled by the ScrollBox, so Init sets everything each time.
--
-- Rows get what they need through `view`:
--   layout    the Columns.Layout in use
--   expanded  { [key] = true } for players shown open
--   races     the icon resolver (race, faction and class icons)
--   OnToggle(key), OnDelete(key), OnEditNote(key)

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
local NOTE_SIZE = 20
local NOTE_DIM_ALPHA = 0.35 -- the note button of a player without a note
local NAME_OFFSET = 4 + EXPAND_SIZE + 4 + CLASS_ICON_SIZE + 6 -- where the name starts

local GREEN = { 0.25, 1, 0.25 }
local RED = { 1, 0.3, 0.3 }
local GREY = { 0.5, 0.5, 0.5 }
local WHITE = { 1, 1, 1 }
local GOLD = { 1, 0.82, 0 }

-- A Vanilla item icon (always in the client), its border cropped to fit a small button.
Rows.NOTE_ICON = { file = "Interface\\Icons\\INV_Misc_Note_01", coords = { 0.08, 0.92, 0.08, 0.92 } }

local function SetColor(fontString, color)
	fontString:SetTextColor(color[1], color[2], color[3])
end

-- Draws an icon descriptor from Races ({ atlas } or { file, coords }) on a texture.
-- Frames are recycled, so the texture coordinates are always set again.
function Rows.ApplyIcon(texture, icon)
	if icon.atlas then
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetAtlas(icon.atlas)
	else
		texture:SetTexture(icon.file)
		texture:SetTexCoord(unpack(icon.coords or { 0, 1, 0, 1 }))
	end
end

-- Tooltips ----------------------------------------------------------------------------------------

-- The class name in the client's language, feminine for a woman where the language
-- has one (Pícara, Schurkin...).
function Rows.ClassName(class, sex)
	if not class then
		return nil
	end
	local names = sex == ns.Races.FEMALE and LOCALIZED_CLASS_NAMES_FEMALE or LOCALIZED_CLASS_NAMES_MALE
	local name = names and names[class]
	if not name and LOCALIZED_CLASS_NAMES_MALE then
		name = LOCALIZED_CLASS_NAMES_MALE[class]
	end
	return name
end

local function ShowPlayerTooltip(row, item)
	local player = item.player
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(Util.DisplayName(item.key), Util.ClassColor(player.class))
	local sex = row.view and row.view.races and row.view.races:Sex(player) or player.sex
	local className = Rows.ClassName(player.class, sex)
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
	if ListModel.HasNote(player) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L.COL_NOTE, GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:AddLine(player.note, 1, 1, 1, true)
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

-- The note of a player, or how to write one, over the note button.
local function ShowNoteTooltip(button)
	local data = button:GetParent().data
	if not data or data.kind ~= "player" then
		return
	end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	if ListModel.HasNote(data.player) then
		GameTooltip:AddLine(L.COL_NOTE, GOLD[1], GOLD[2], GOLD[3])
		GameTooltip:AddLine(data.player.note, 1, 1, 1, true)
		GameTooltip:AddLine(L.NOTE_EDIT_HINT, 0.6, 0.6, 0.6, true)
	else
		GameTooltip:AddLine(L.NOTE_ADD_HINT, 1, 1, 1, true)
	end
	GameTooltip:Show()
end

-- Setup and layout -------------------------------------------------------------------------------

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

local function PlaceCells(row, cells, columns)
	for _, column in ipairs(columns) do
		local cell = cells[column.key]
		cell:ClearAllPoints()
		cell:SetPoint("LEFT", row, "LEFT", column.x + 4, 0)
		cell:SetWidth(column.width - 8)
	end
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

local function OnNoteClick(button)
	local row = button:GetParent()
	local data, view = row.data, row.view
	if data and data.kind == "player" and view then
		view.OnEditNote(data.key)
	end
end

-- A button of its own, so a click on it opens the note instead of the player's fights.
local function CreateNoteButton(row)
	local button = CreateFrame("Button", nil, row)
	button:SetSize(NOTE_SIZE, NOTE_SIZE)
	button:SetPoint("CENTER", row.cells.note, "CENTER")
	button:RegisterForClicks("LeftButtonUp")
	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetAllPoints()
	Rows.ApplyIcon(button.Icon, Rows.NOTE_ICON)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetScript("OnClick", OnNoteClick)
	button:SetScript("OnEnter", ShowNoteTooltip)
	button:SetScript("OnLeave", OnLeave)
	return button
end

-- Creates the widgets of a row frame, once.
function Rows.Setup(row)
	if row.cells then
		return
	end
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	row:GetHighlightTexture():SetAlpha(0.6)

	row.Background = row:CreateTexture(nil, "BACKGROUND")
	row.Background:SetAllPoints()

	row.Expand = row:CreateTexture(nil, "ARTWORK")
	row.Expand:SetSize(EXPAND_SIZE, EXPAND_SIZE)
	row.Expand:SetPoint("LEFT", 4, 0)

	row.ClassIcon = row:CreateTexture(nil, "ARTWORK")
	row.ClassIcon:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
	row.ClassIcon:SetPoint("LEFT", 4 + EXPAND_SIZE + 4, 0)

	row.ResultIcon = row:CreateTexture(nil, "ARTWORK")
	row.ResultIcon:SetSize(RESULT_ICON_SIZE, RESULT_ICON_SIZE)
	row.ResultIcon:SetPoint("LEFT", ns.Columns.DETAIL_INDENT + 2, 0)

	row.cells = MakeCells(row, ns.Columns.PLAYER, "GameFontHighlight")
	row.cells.name:SetFontObject("GameFontNormal")

	row.RaceIcon = row:CreateTexture(nil, "ARTWORK")
	row.RaceIcon:SetSize(RACE_ICON_SIZE, RACE_ICON_SIZE)
	row.RaceIcon:SetPoint("CENTER", row.cells.race, "CENTER")

	-- Faction badge on the race icon, for races both factions can play (Skyborne).
	row.FactionIcon = row:CreateTexture(nil, "OVERLAY")
	row.FactionIcon:SetSize(FACTION_BADGE_SIZE, FACTION_BADGE_SIZE)
	row.FactionIcon:SetPoint("BOTTOMRIGHT", row.RaceIcon, "BOTTOMRIGHT", 6, -2)

	row.NoteButton = CreateNoteButton(row)

	row.detail = MakeCells(row, ns.Columns.DETAIL, "GameFontHighlightSmall")

	row.Extra = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	row.Extra:SetPoint("LEFT", ns.Columns.DETAIL_INDENT + 4, 0)
	row.Extra:SetPoint("RIGHT", -4, 0)
	row.Extra:SetJustifyH("LEFT")

	row:SetScript("OnClick", OnClick)
	row:SetScript("OnEnter", OnEnter)
	row:SetScript("OnLeave", OnLeave)
end

-- Puts the cells where a layout says. Cheap when the layout did not change.
function Rows.Layout(row, layout)
	if row.layout == layout then
		return
	end
	row.layout = layout
	PlaceCells(row, row.cells, layout.player)
	-- The name starts after the +/- and the class icon.
	local name = layout.player.name
	row.cells.name:ClearAllPoints()
	row.cells.name:SetPoint("LEFT", row, "LEFT", NAME_OFFSET, 0)
	row.cells.name:SetWidth(name.width - NAME_OFFSET - 2)
	PlaceCells(row, row.detail, layout.detail)
	row.detailShifted = nil
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

local function ShowCells(cells, shown)
	for _, cell in pairs(cells) do
		cell:SetShown(shown)
	end
end

local function FillPlayer(row, data, view)
	local player = data.player
	-- Blizzard stripes: every other player row slightly lighter.
	if data.index % 2 == 0 then
		row.Background:SetColorTexture(1, 1, 1, 0.05)
	else
		row.Background:SetColorTexture(0, 0, 0, 0)
	end
	row.Expand:SetTexture(view.expanded[data.key] and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")

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
	cells.note:SetText("")

	-- Lit when there is a note, faded when there is none.
	local hasNote = ListModel.HasNote(player)
	row.NoteButton.Icon:SetDesaturated(not hasNote)
	row.NoteButton.Icon:SetAlpha(hasNote and 1 or NOTE_DIM_ALPHA)
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
	Rows.Layout(row, view.layout)
	row.data, row.view = data, view

	local kind = data.kind
	ShowCells(row.cells, kind == "player")
	ShowCells(row.detail, kind == "fight" or kind == "header")
	row.Expand:SetShown(kind == "player")
	row.ClassIcon:SetShown(kind == "player")
	row.NoteButton:SetShown(kind == "player")
	row.ResultIcon:SetShown(kind == "fight")
	row.Extra:SetShown(kind == "extra")
	if kind ~= "player" then
		row.RaceIcon:Hide()
		row.FactionIcon:Hide()
		-- Inside an expanded player: a darker band.
		row.Background:SetColorTexture(0, 0, 0, 0.35)
	end

	if kind == "player" then
		FillPlayer(row, data, view)
	elseif kind == "header" then
		FillHeader(row, view)
	elseif kind == "fight" then
		FillFight(row, data, view)
	elseif kind == "extra" then
		row.Extra:SetText(L.EXTRA:format(data.kills, data.deaths))
	end
end
