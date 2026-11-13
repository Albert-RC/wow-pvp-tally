-- PvP Tally: a skull on the nameplate of every player in the list, wherever they are
-- seen (open world and battlegrounds alike: it only shows what is known, it records
-- nothing). Research and in-game tests: docs/nameplate-marks.md.
--
-- The client recycles nameplates from one unit to the next, so the skull is shown or
-- hidden again every time a nameplate appears: never left over from the previous unit.
-- It is a texture of our own on the nameplate (no field is written on Blizzard's
-- frames), left of the name, where neither Blizzard nor BetterBlizzPlates put anything.

local _, ns = ...
local Rows = ns.Rows

local NameplateMarks = {}
NameplateMarks.__index = NameplateMarks
ns.NameplateMarks = NameplateMarks

-- The skull of the "??" level: it exists on Forever and BetterBlizzPlates draws it on
-- nameplates too. Not the raid marker skull, which would read as a real marker.
NameplateMarks.SKULL = { file = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" }
NameplateMarks.SIZE = 16 -- when no size is given
NameplateMarks.GAP = 2 -- between the skull and the name

-- Pure: the icon for a player record of the store, or nil for no mark.
function NameplateMarks.MarkFor(player)
	if type(player) ~= "table" then
		return nil
	end
	return NameplateMarks.SKULL
end

-- options:
--   playerKey(unit)     the store key of the player behind a unit token, or nil
--   namePlateFor(unit)  the nameplate of a unit token, or nil (none, or forbidden)
--   lookup(key)         the player record of the store, or nil when not in the list
--   isEnabled()         whether the option is on
--   size()              optional: the skull size in pixels (NameplateMarks.SIZE otherwise)
function NameplateMarks.New(options)
	assert(type(options) == "table", "options expected")
	for _, name in ipairs({ "playerKey", "namePlateFor", "lookup", "isEnabled" }) do
		assert(type(options[name]) == "function", name .. " function expected")
	end
	return setmetatable({
		playerKey = options.playerKey,
		namePlateFor = options.namePlateFor,
		lookup = options.lookup,
		isEnabled = options.isEnabled,
		size = options.size or function() return NameplateMarks.SIZE end,
		units = {},    -- unit token -> its nameplate, while on screen
		textures = {}, -- nameplate -> our skull texture (made once per nameplate)
	}, NameplateMarks)
end

-- Widgets ---------------------------------------------------------------------------------------

local function CreateSkull(nameplate)
	local texture = nameplate:CreateTexture(nil, "OVERLAY")
	local unitFrame = nameplate.UnitFrame
	-- Anchored to the name, it follows wherever Blizzard or another addon moves it.
	if unitFrame.name then
		texture:SetPoint("RIGHT", unitFrame.name, "LEFT", -NameplateMarks.GAP, 0)
	else
		texture:SetPoint("BOTTOM", unitFrame, "TOP", 0, 0)
	end
	return texture
end

local function HideOn(self, nameplate)
	local texture = nameplate and self.textures[nameplate]
	if texture then
		texture:Hide()
	end
end

function NameplateMarks:Update(unit, nameplate)
	local icon
	if self.isEnabled() then
		local key = self.playerKey(unit)
		icon = NameplateMarks.MarkFor(key and self.lookup(key))
	end
	if not icon then
		HideOn(self, nameplate)
		return
	end
	local texture = self.textures[nameplate]
	if not texture then
		texture = CreateSkull(nameplate)
		self.textures[nameplate] = texture
	end
	Rows.ApplyIcon(texture, icon)
	local size = self.size()
	texture:SetSize(size, size) -- every time: the size can change while the skull is shown
	texture:Show()
end

-- Events ------------------------------------------------------------------------------------------

-- NAME_PLATE_UNIT_ADDED, and every refresh.
function NameplateMarks:Show(unit)
	if type(unit) ~= "string" then
		return
	end
	local nameplate = self.namePlateFor(unit)
	local previous = self.units[unit]
	if previous and previous ~= nameplate then
		HideOn(self, previous)
	end
	self.units[unit] = nameplate
	if not nameplate then
		return
	end
	-- A recycled nameplate whose removal we missed: it belongs to this unit now.
	for other, plate in pairs(self.units) do
		if plate == nameplate and other ~= unit then
			self.units[other] = nil
		end
	end
	self:Update(unit, nameplate)
end

-- NAME_PLATE_UNIT_REMOVED.
function NameplateMarks:Remove(unit)
	if type(unit) ~= "string" then
		return
	end
	HideOn(self, self.units[unit])
	self.units[unit] = nil
end

-- Every nameplate on screen again: the list or the option changed.
function NameplateMarks:Refresh()
	local units = {}
	for unit in pairs(self.units) do
		units[#units + 1] = unit
	end
	for _, unit in ipairs(units) do
		self:Show(unit)
	end
end
