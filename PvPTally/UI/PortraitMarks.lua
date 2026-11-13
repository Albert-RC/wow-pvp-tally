-- PvP Tally: a skull in place of the portrait of the target and focus frames when the
-- player is in the list. A fallback for the nameplate skull, which addons that replace
-- the nameplates (Plater, Kui...) hide.
--
-- Blizzard's portrait is left as it is: the skull is a texture of our own laid over it,
-- in the same draw layer just above it, so the frame art stays on top. It is cut by a
-- round mask of its own, a little inside the portrait: the square icon must not spill
-- over the ring of the frame (Blizzard's PortraitMask alone let it, in the game).
--
-- Blizzard redraws its portrait whenever it likes (target change, portrait update) and
-- other addons hook it (BetterBlizzFrames' spec icons); an overlay is unaffected by
-- either. Frames on Forever, as BetterBlizzFrames reads them:
-- TargetFrame.TargetFrameContainer.Portrait, the same for FocusFrame.

local _, ns = ...
local Rows = ns.Rows

local PortraitMarks = {}
PortraitMarks.__index = PortraitMarks
ns.PortraitMarks = PortraitMarks

-- The addon's own icon: a human skull, square art that the round mask crops like a face.
PortraitMarks.SKULL = { file = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01" }

local MAX_SUBLEVEL = 7
-- The round mask Blizzard and BetterBlizzFrames use for portraits on Forever.
PortraitMarks.MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
-- How far inside the portrait the mask stops, in pixels, so the ring covers the edge.
PortraitMarks.INSET = 3

-- Pure: the icon for a player record of the store, or nil for no mark.
function PortraitMarks.MarkFor(player)
	if type(player) ~= "table" then
		return nil
	end
	return PortraitMarks.SKULL
end

-- options:
--   frames             { [unit] = unit frame }, e.g. { target = TargetFrame, focus = FocusFrame }
--   playerKey(unit)    the store key of the player behind a unit token, or nil
--   lookup(key)        the player record of the store, or nil when not in the list
--   isEnabled()        whether the option is on
function PortraitMarks.New(options)
	assert(type(options) == "table", "options expected")
	assert(type(options.frames) == "table", "frames table expected")
	for _, name in ipairs({ "playerKey", "lookup", "isEnabled" }) do
		assert(type(options[name]) == "function", name .. " function expected")
	end
	return setmetatable({
		frames = options.frames,
		playerKey = options.playerKey,
		lookup = options.lookup,
		isEnabled = options.isEnabled,
		textures = {}, -- unit -> our skull texture (made once per frame)
	}, PortraitMarks)
end

-- Widgets ---------------------------------------------------------------------------------------

-- The container and portrait of a unit frame, or nil when the frame is missing or not
-- Blizzard's (another addon may have replaced or hidden it).
local function Portrait(frame)
	local container = type(frame) == "table" and frame.TargetFrameContainer
	local portrait = type(container) == "table" and container.Portrait
	if type(portrait) ~= "table" or type(portrait.GetDrawLayer) ~= "function" then
		return nil
	end
	return container, portrait
end

local function CreateSkull(container, portrait)
	local layer, sublevel = portrait:GetDrawLayer()
	local texture = container:CreateTexture(nil, layer, nil, math.min((sublevel or 0) + 1, MAX_SUBLEVEL))
	texture:SetAllPoints(portrait)
	if container.CreateMaskTexture and texture.AddMaskTexture then
		local mask = container:CreateMaskTexture()
		mask:SetTexture(PortraitMarks.MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		local inset = PortraitMarks.INSET
		mask:SetPoint("TOPLEFT", portrait, "TOPLEFT", inset, -inset)
		mask:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", -inset, inset)
		texture:AddMaskTexture(mask)
	end
	return texture
end

-- Shows or hides the skull of one unit ("target" or "focus").
function PortraitMarks:Update(unit)
	local frame = self.frames[unit]
	if not frame then
		return
	end
	local icon
	if self.isEnabled() then
		local key = self.playerKey(unit)
		icon = PortraitMarks.MarkFor(key and self.lookup(key))
	end
	local texture = self.textures[unit]
	if not icon then
		if texture then
			texture:Hide()
		end
		return
	end
	if not texture then
		local container, portrait = Portrait(frame)
		if not container then
			return
		end
		texture = CreateSkull(container, portrait)
		self.textures[unit] = texture
	end
	Rows.ApplyIcon(texture, icon)
	texture:Show()
end

-- Every unit again: the list or the option changed.
function PortraitMarks:Refresh()
	for unit in pairs(self.frames) do
		self:Update(unit)
	end
end
