-- PvP Tally: the minimap button, hand placed (no libraries). Named PvPTallyMinimapButton
-- so minimap button collectors can pick it up.

local _, ns = ...
local L, Util, Store = ns.L, ns.Util, ns.Store

local MinimapButton = {}
ns.MinimapButton = MinimapButton

MinimapButton.RADIUS = 80
local ICON = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01"

local button
local app -- { store, settings, Toggle(), OpenSettings() }

-- Pure: where the button sits for an angle (radians) around the minimap center.
function MinimapButton.Offset(angle, radius)
	radius = radius or MinimapButton.RADIUS
	return math.cos(angle) * radius, math.sin(angle) * radius
end

-- Pure: the angle from the minimap center to a point.
function MinimapButton.AngleTo(centerX, centerY, x, y)
	return math.atan2(y - centerY, x - centerX)
end

local function Place(angle)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", MinimapButton.Offset(angle))
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

-- context: { store, settings, Toggle(), OpenSettings() }
function MinimapButton.Create(context)
	if button or not Minimap then
		return
	end
	app = context
	button = CreateFrame("Button", "PvPTallyMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetPoint("CENTER")
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER")
	icon:SetTexture(ICON)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
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
