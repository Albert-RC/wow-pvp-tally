-- PvP Tally: the minimap button, hand placed (no libraries). Named PvPTallyMinimapButton
-- so minimap button collectors can pick it up.

local _, ns = ...
local L, Util, Store = ns.L, ns.Util, ns.Store

local MinimapButton = {}
ns.MinimapButton = MinimapButton

-- How far past the minimap edge the button center sits, and the minimap size to assume
-- when it cannot be read. The same values as LibDBIcon, so the button lines up with the
-- other addon buttons (BugSack, Details...) when no button collector is installed.
MinimapButton.EDGE_OFFSET = 5
MinimapButton.DEFAULT_SIZE = 140
local ICON = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01"

-- Which quadrants of each minimap shape are round, as in LibDBIcon. Quadrant 1 is the
-- bottom right, 2 bottom left, 3 top right, 4 top left. Unknown shapes count as round.
local ROUND_QUADRANTS = {
	["ROUND"] = { true, true, true, true },
	["SQUARE"] = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local button
local app -- { store, settings, Toggle(), OpenSettings() }
local minimapShape -- function() -> shape name

-- Pure: where the button sits for an angle (radians) around the center of a minimap of
-- that size and shape: on its rim, or along the sides of a square corner.
function MinimapButton.Offset(angle, width, height, shape)
	local x, y = math.cos(angle), math.sin(angle)
	local quadrant = 1
	if x < 0 then quadrant = quadrant + 1 end
	if y > 0 then quadrant = quadrant + 2 end
	local round = ROUND_QUADRANTS[shape] or ROUND_QUADRANTS.ROUND
	local w = (width or MinimapButton.DEFAULT_SIZE) / 2 + MinimapButton.EDGE_OFFSET
	local h = (height or MinimapButton.DEFAULT_SIZE) / 2 + MinimapButton.EDGE_OFFSET
	if round[quadrant] then
		return x * w, y * h
	end
	local diagonalW = math.sqrt(2 * w * w) - 10
	local diagonalH = math.sqrt(2 * h * h) - 10
	return math.max(-w, math.min(x * diagonalW, w)), math.max(-h, math.min(y * diagonalH, h))
end

-- Pure: the angle from the minimap center to a point.
function MinimapButton.AngleTo(centerX, centerY, x, y)
	return math.atan2(y - centerY, x - centerX)
end

local function MinimapSize(read)
	local size = Util.Readable(read(Minimap))
	return type(size) == "number" and size > 0 and size or nil
end

-- Placed only when created and while dragged: a button collector (MinimapButtonButton)
-- moves the button into its own bar, and must not be undone.
local function Place(angle)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", MinimapButton.Offset(angle,
		MinimapSize(Minimap.GetWidth), MinimapSize(Minimap.GetHeight), minimapShape()))
end

local function CursorAngle()
	local scale = Util.Readable(Minimap:GetEffectiveScale()) or 1
	local cursorX, cursorY = GetCursorPosition()
	local centerX, centerY = Minimap:GetCenter()
	return MinimapButton.AngleTo(Util.Readable(centerX) or 0, Util.Readable(centerY) or 0,
		(Util.Readable(cursorX) or 0) / scale, (Util.Readable(cursorY) or 0) / scale)
end

local function ShowTooltip(self)
	local kills, deaths = 0, 0
	for _, player in app.store:Players() do
		local k, d = Store.Counts(player)
		kills, deaths = kills + k, deaths + d
	end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine(L.TITLE)
	GameTooltip:AddDoubleLine(L.COL_KILLS, kills, 1, 0.82, 0, 0.25, 1, 0.25)
	GameTooltip:AddDoubleLine(L.COL_DEATHS, deaths, 1, 0.82, 0, 1, 0.3, 0.3)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L.MINIMAP_LEFT, 0.8, 0.8, 0.8)
	GameTooltip:AddLine(L.MINIMAP_RIGHT, 0.8, 0.8, 0.8)
	GameTooltip:AddLine(L.MINIMAP_DRAG, 0.6, 0.6, 0.6)
	GameTooltip:Show()
end

-- context: { store, settings, Toggle(), OpenSettings() }; shape: function() -> minimap shape name
function MinimapButton.Create(context, shape)
	if button or not Minimap then
		return
	end
	app, minimapShape = context, shape or function() return "ROUND" end
	button = CreateFrame("Button", "PvPTallyMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	-- The layout LibDBIcon uses on modern clients, so it looks like the buttons next to it.
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(24, 24)
	background:SetPoint("CENTER")
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER")
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(50, 50)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			app.OpenSettings()
		else
			app.Toggle()
		end
	end)
	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			app.settings.minimap.angle = CursorAngle()
			Place(app.settings.minimap.angle)
		end)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	button:SetScript("OnEnter", ShowTooltip)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)

	Place(app.settings.minimap.angle)
	button:SetShown(not app.settings.minimap.hide)
end

function MinimapButton.SetShown(shown)
	app.settings.minimap.hide = not shown
	if button then
		button:SetShown(shown)
	end
end
