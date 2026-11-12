-- PvP Tally: the main window. A Blizzard ButtonFrame with sortable column headers over a
-- ScrollBox, a search box, and a resize grip.
--
-- The window owns only view state (sorting, search, open players, size, theme). The data
-- comes from the store through ListModel and the look from Themes; it refreshes when the
-- bus says the data or the style changed.

local _, ns = ...
local L, Util, Columns, ListModel, Rows, Themes = ns.L, ns.Util, ns.Columns, ns.ListModel, ns.Rows, ns.Themes

local Window = {}
ns.Window = Window

local HEADER_HEIGHT = 24
local HEADER_TOP = -60
local LIST_MARGIN = 44 -- window width around the list (insets and scroll bar)
local ICON = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01"

-- Size limits: narrower, the columns would overlap; bigger, the rows are mostly empty.
Window.MIN_WIDTH = Columns.LIST_WIDTH + LIST_MARGIN
Window.MIN_HEIGHT = 340
Window.MAX_WIDTH = 1100
Window.MAX_HEIGHT = 900
Window.DEFAULT_HEIGHT = 520

local SOUND_CLICK = SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856
local SOUND_OPEN = SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN or 839
local SOUND_CLOSE = SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_CLOSE or 840

local frame
local app        -- { store, settings, races, AtlasExists(), IsSpyAvailable(), ImportFromSpy(), ConfirmDelete(key), OpenSettings() }
local view = {   -- what the rows read (see Rows.lua)
	layout = Columns.Layout(Columns.LIST_WIDTH),
	theme = nil,
	expanded = {},
}
local sortKey, sortAscending = ListModel.DEFAULT_SORT, false

-- Shows a texture with a theme piece, or hides it when the theme has none.
local function ShowPiece(texture, piece)
	texture:SetShown(piece ~= nil)
	if piece then
		Rows.ApplyIcon(texture, piece)
	end
end

local function ListWidth()
	return math.max(Columns.LIST_WIDTH, math.floor(frame:GetWidth() - LIST_MARGIN))
end

-- Headers ----------------------------------------------------------------------------------------

local function UpdateSortArrows()
	for _, header in ipairs(frame.Headers) do
		local sorted = header.key == sortKey
		header.Arrow:SetShown(sorted)
		if sorted then
			header.Arrow:SetTexCoord(0, 0.5625, sortAscending and 1 or 0, sortAscending and 0 or 1)
		end
	end
end

local function OnHeaderClick(header)
	if sortKey == header.key then
		sortAscending = not sortAscending
	else
		sortKey, sortAscending = header.key, ListModel.DefaultAscending(header.key)
	end
	PlaySound(SOUND_CLICK)
	Window.Refresh()
end

local function ColumnTabTexture(header, left, right)
	local texture = header:CreateTexture(nil, "BACKGROUND")
	texture:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
	texture:SetTexCoord(left, right, 0, 0.75)
	return texture
end

-- Classic: a Who list column tab.
local function DecorateTab(header)
	local left = ColumnTabTexture(header, 0, 0.078125)
	left:SetSize(5, HEADER_HEIGHT)
	left:SetPoint("TOPLEFT")
	local right = ColumnTabTexture(header, 0.90625, 0.96875)
	right:SetSize(4, HEADER_HEIGHT)
	right:SetPoint("TOPRIGHT")
	local middle = ColumnTabTexture(header, 0.078125, 0.90625)
	middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
	middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")

	header:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", "ADD")
	local highlight = header:GetHighlightTexture()
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", left, "TOPLEFT", -2, 5)
	highlight:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", 2, -7)
end

-- One header button. style: "tabs" (classic) or "strip" (gold titles on a line).
local function CreateHeader(column, style)
	local header = CreateFrame("Button", nil, frame)
	header:SetHeight(HEADER_HEIGHT)
	header.key = column.key
	if style == "tabs" then
		DecorateTab(header)
	end

	header:SetNormalFontObject(style == "tabs" and "GameFontHighlightSmall" or "GameFontNormalSmall")
	header:SetText(column.label)
	local text = header:GetFontString()
	text:ClearAllPoints()
	if column.justify == "LEFT" then
		text:SetPoint("LEFT", 8, 0)
	else
		text:SetPoint("CENTER", -4, 0)
	end

	header.Arrow = header:CreateTexture(nil, "OVERLAY")
	header.Arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
	header.Arrow:SetSize(9, 8)
	header.Arrow:SetPoint("LEFT", text, "RIGHT", 3, -2)
	header.Arrow:Hide()

	if column.sortable ~= false then
		header:SetScript("OnClick", OnHeaderClick)
	else
		header:EnableMouse(false)
	end
	return header
end

-- The headers of a theme, created the first time it is shown.
local function HeaderSet(theme)
	frame.HeaderSets = frame.HeaderSets or {}
	local set = frame.HeaderSets[theme.name]
	if not set then
		set = {}
		for index, column in ipairs(Columns.SETS[theme.columns]) do
			set[index] = CreateHeader(column, theme.headerStyle)
		end
		frame.HeaderSets[theme.name] = set
	end
	return set
end

local function PlaceHeaders()
	for index, column in ipairs(view.layout.player) do
		local header = frame.Headers[index]
		header:ClearAllPoints()
		header:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 + column.x, HEADER_TOP)
		header:SetWidth(column.width)
	end
	frame.HeaderStrip:ClearAllPoints()
	frame.HeaderStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, HEADER_TOP)
	frame.HeaderStrip:SetSize(view.layout.width, HEADER_HEIGHT)
end

-- Theme ------------------------------------------------------------------------------------------

local applyingTheme = false

-- Draws the window in the style chosen in the options. The rows follow on the next refresh.
local function ApplyTheme()
	-- Reading the width can fire OnSizeChanged right away (a pending resize). Read it
	-- before anything changes, and keep OnSizeChanged out until theme, layout and
	-- headers agree again.
	local width = ListWidth()
	applyingTheme = true
	local theme = Themes.Resolve(app.settings.theme, app.AtlasExists)
	view.theme = theme
	view.layout = Columns.Layout(width, theme.columns)

	for _, set in pairs(frame.HeaderSets or {}) do
		for _, header in ipairs(set) do
			header:Hide()
		end
	end
	frame.Headers = HeaderSet(theme)
	for _, header in ipairs(frame.Headers) do
		header:Show()
	end
	PlaceHeaders()
	ShowPiece(frame.HeaderStrip, theme.headerStrip)

	-- The inset's own grey background and border, unless the theme brings its own.
	local native = theme.listBackground == nil
	local inset = frame.Inset
	if inset.Bg then inset.Bg:SetShown(native) end
	if inset.NineSlice then inset.NineSlice:SetShown(native) end
	ShowPiece(frame.ListBackground, theme.listBackground)
	ShowPiece(frame.ListEdgeTop, theme.listEdge)
	ShowPiece(frame.ListEdgeBottom, theme.listEdge)
	if theme.listEdge then
		frame.ListEdgeBottom:SetRotation(math.pi) -- the bottom line is the top one turned round
	end

	-- A column the new theme does not have cannot stay the sort column.
	if not view.layout.player[sortKey] then
		sortKey, sortAscending = ListModel.DEFAULT_SORT, false
	end
	applyingTheme = false
end

-- Size and position ---------------------------------------------------------------------------------

local function SavePosition()
	local point, _, relativePoint, x, y = frame:GetPoint()
	app.settings.position = { point, relativePoint, x, y }
end

local function SaveSize()
	app.settings.size = { math.floor(frame:GetWidth() + 0.5), math.floor(frame:GetHeight() + 0.5) }
end

local function RestoreGeometry()
	local size = app.settings.size
	local width, height = Window.MIN_WIDTH, Window.DEFAULT_HEIGHT
	if type(size) == "table" and Util.IsFiniteNumber(size[1]) and Util.IsFiniteNumber(size[2]) then
		width, height = size[1], size[2]
	end
	frame:SetSize(Util.Clamp(width, Window.MIN_WIDTH, Window.MAX_WIDTH), Util.Clamp(height, Window.MIN_HEIGHT, Window.MAX_HEIGHT))

	frame:ClearAllPoints()
	local position = app.settings.position
	if type(position) == "table" and type(position[1]) == "string" then
		frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
	else
		frame:SetPoint("CENTER")
	end
end

-- New column widths when the width changed; only the visible rows are moved, the data
-- is not rebuilt.
local function OnSizeChanged()
	if not view.theme or applyingTheme then
		return
	end
	local width = ListWidth()
	if width == view.layout.width then
		return
	end
	view.layout = Columns.Layout(width, view.theme.columns)
	PlaceHeaders()
	for _, row in frame.ScrollBox:EnumerateFrames() do
		Rows.Layout(row, view.layout, view.theme)
	end
end

local function CreateResizeGrip()
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(Window.MIN_WIDTH, Window.MIN_HEIGHT, Window.MAX_WIDTH, Window.MAX_HEIGHT)
	else
		frame:SetMinResize(Window.MIN_WIDTH, Window.MIN_HEIGHT)
		frame:SetMaxResize(Window.MAX_WIDTH, Window.MAX_HEIGHT)
	end
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -3, 4)
	grip:SetFrameLevel(frame:GetFrameLevel() + 10)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then
			frame:StartSizing("BOTTOMRIGHT")
		end
	end)
	grip:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		SavePosition()
		SaveSize()
	end)
	frame.ResizeGrip = grip
	frame:SetScript("OnSizeChanged", OnSizeChanged)
end

-- Building ----------------------------------------------------------------------------------------------

local function CreateList()
	local inset = frame.Inset
	inset:ClearAllPoints()
	inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, HEADER_TOP - HEADER_HEIGHT)
	inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 26)

	-- Forever: the textured background behind the rows.
	frame.ListBackground = inset:CreateTexture(nil, "BACKGROUND", nil, 1)
	frame.ListBackground:SetAllPoints(inset)
	frame.ListBackground:Hide()

	frame.ScrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
	frame.ScrollBox:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -3)
	frame.ScrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -20, 3)

	frame.ScrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
	frame.ScrollBar:SetPoint("TOPLEFT", frame.ScrollBox, "TOPRIGHT", 6, -2)
	frame.ScrollBar:SetPoint("BOTTOMLEFT", frame.ScrollBox, "BOTTOMRIGHT", 6, 2)

	local scrollView = CreateScrollBoxListLinearView()
	scrollView:SetElementExtent(Rows.HEIGHT)
	scrollView:SetElementInitializer("Button", function(row, data)
		Rows.Init(row, data, view)
	end)
	ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, scrollView)

	-- Forever: lines along the top and bottom of the list, drawn above the rows.
	local overlay = CreateFrame("Frame", nil, inset)
	overlay:SetAllPoints(inset)
	overlay:SetFrameLevel(frame.ScrollBox:GetFrameLevel() + 5)
	frame.ListEdgeTop = overlay:CreateTexture(nil, "OVERLAY")
	frame.ListEdgeTop:SetPoint("TOPLEFT")
	frame.ListEdgeTop:SetPoint("TOPRIGHT")
	frame.ListEdgeTop:Hide()
	frame.ListEdgeBottom = overlay:CreateTexture(nil, "OVERLAY")
	frame.ListEdgeBottom:SetPoint("BOTTOMLEFT")
	frame.ListEdgeBottom:SetPoint("BOTTOMRIGHT")
	frame.ListEdgeBottom:Hide()

	frame.Empty = inset:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	frame.Empty:SetPoint("CENTER")
	frame.Empty:SetText(L.EMPTY)
end

local function CreateTopBar()
	frame.Summary = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.Summary:SetPoint("TOPLEFT", 66, -36)
	frame.Summary:SetJustifyH("LEFT")

	frame.SearchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	frame.SearchBox:SetSize(170, 20)
	frame.SearchBox:SetPoint("TOPRIGHT", -14, -31)
	frame.SearchBox:SetAutoFocus(false)
	if frame.SearchBox.Instructions then
		frame.SearchBox.Instructions:SetText(L.SEARCH)
	end
	frame.SearchBox:HookScript("OnTextChanged", Window.Refresh)

	-- Forever: the line behind the column titles. The headers come with the theme.
	frame.HeaderStrip = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
	frame.HeaderStrip:Hide()
	frame.Headers = {}
end

local function CreateBottomBar()
	frame.ImportButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.ImportButton:SetSize(140, 22)
	frame.ImportButton:SetPoint("BOTTOMRIGHT", -24, 3)
	frame.ImportButton:SetText(L.IMPORT_BUTTON)
	frame.ImportButton:SetScript("OnClick", function() app.ImportFromSpy() end)
	frame.ImportButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L.IMPORT_BUTTON)
		GameTooltip:AddLine(L.IMPORT_TOOLTIP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	frame.ImportButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	-- Disabled buttons get no OnEnter: keep the tooltip explaining why.
	frame.ImportButton:SetMotionScriptsWhileDisabled(true)

	frame.ExpandButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.ExpandButton:SetSize(120, 22)
	frame.ExpandButton:SetPoint("BOTTOMLEFT", 4, 3)
	frame.ExpandButton:SetScript("OnClick", function()
		if next(view.expanded) then
			wipe(view.expanded)
		else
			for key in app.store:Players() do
				view.expanded[key] = true
			end
		end
		Window.Refresh()
	end)

	frame.SettingsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.SettingsButton:SetSize(100, 22)
	frame.SettingsButton:SetPoint("LEFT", frame.ExpandButton, "RIGHT", 4, 0)
	frame.SettingsButton:SetText(L.SETTINGS_BUTTON)
	frame.SettingsButton:SetScript("OnClick", function() app.OpenSettings() end)
end

local function Create()
	frame = CreateFrame("Frame", "PvPTallyFrame", UIParent, "ButtonFrameTemplate")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)
	frame:Hide()
	tinsert(UISpecialFrames, "PvPTallyFrame") -- Escape closes it

	if frame.SetTitle then
		frame:SetTitle(L.TITLE)
	elseif frame.TitleText then
		frame.TitleText:SetText(L.TITLE)
	end
	if frame.SetPortraitToAsset then
		frame:SetPortraitToAsset(ICON)
	end

	CreateTopBar()
	CreateList()
	CreateBottomBar()
	CreateResizeGrip()

	frame:SetScript("OnShow", function()
		PlaySound(SOUND_OPEN)
		Window.Refresh()
	end)
	frame:SetScript("OnHide", function()
		PlaySound(SOUND_CLOSE)
	end)

	RestoreGeometry()
	ApplyTheme()
end

-- Public --------------------------------------------------------------------------------------------------

-- context: { store, settings, races, AtlasExists(), IsSpyAvailable(), ImportFromSpy(), ConfirmDelete(key), OpenSettings() }
function Window.Init(context)
	app = context
	view.races = context.races
	view.OnToggle = function(key)
		PlaySound(SOUND_CLICK)
		view.expanded[key] = not view.expanded[key] or nil
		Window.Refresh()
	end
	view.OnDelete = function(key)
		context.ConfirmDelete(key)
	end
end

-- Follows a style change from the options. Nothing to do until the window exists: it
-- reads the style when it is created.
function Window.ApplyTheme()
	if not frame then
		return
	end
	ApplyTheme()
	Window.Refresh()
end

function Window.Refresh()
	if not frame or not frame:IsShown() then
		return
	end
	local rows, totals, count = ListModel.Build(app.store, {
		filter = frame.SearchBox:GetText(),
		sortKey = sortKey,
		ascending = sortAscending,
		expanded = view.expanded,
	})
	frame.ScrollBox:SetDataProvider(CreateDataProvider(rows), true)
	frame.Empty:SetShown(count == 0)
	frame.Summary:SetText(L.SUMMARY:format(
		Util.ColorText(totals.players, 1, 1, 1),
		Util.ColorText(totals.kills, 0.25, 1, 0.25),
		Util.ColorText(totals.deaths, 1, 0.3, 0.3),
		Util.ColorText(ListModel.Ratio(totals.kills, totals.deaths), 1, 1, 1)))
	frame.ExpandButton:SetText(next(view.expanded) and L.COLLAPSE_ALL or L.EXPAND_ALL)
	frame.ImportButton:SetEnabled(app.IsSpyAvailable())
	UpdateSortArrows()
end

function Window.Toggle()
	assert(app, "Window.Init must run first")
	if not frame then
		Create()
	end
	frame:SetShown(not frame:IsShown())
end

function Window.IsShown()
	return frame ~= nil and frame:IsShown()
end

-- The theme the window draws, for the tests and /tally debug.
function Window.CurrentTheme()
	return view.theme
end
