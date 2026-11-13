local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("PortraitMarks", function()
	local ns, env, Marks, marks
	local players, keys, enabled
	before_each(function()
		ns, env = Addon.LoadWith({ "UI/ListModel.lua", "UI/Rows.lua", "UI/PortraitMarks.lua" })
		Marks = ns.PortraitMarks
		players = { ["Kane-Mochivich"] = { name = "Kane" } } -- the list
		keys = {}                                            -- unit token -> player key
		enabled = true
		marks = Marks.New({
			frames = { target = env.TargetFrame, focus = env.FocusFrame },
			playerKey = function(unit) return keys[unit] end,
			lookup = function(key) return players[key] end,
			isEnabled = function() return enabled end,
		})
	end)

	local function hasSkull(unit)
		local texture = marks.textures[unit]
		return texture ~= nil and texture:IsShown()
	end

	it("gives the skull to a player of the list and nothing to anyone else", function()
		T.eq(Marks.MarkFor({}), { file = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01" })
		T.isNil(Marks.MarkFor(nil))
	end)

	it("needs all its collaborators", function()
		T.raises(function() Marks.New() end, "options expected")
		T.raises(function() Marks.New({ playerKey = function() end }) end, "frames table expected")
		T.raises(function()
			Marks.New({ frames = {}, playerKey = function() end, lookup = function() end })
		end, "isEnabled function expected")
	end)

	it("lays the skull over the portrait, in its mask, just above it", function()
		keys.target = "Kane-Mochivich"
		marks:Update("target")
		local container = env.TargetFrame.TargetFrameContainer
		local texture = marks.textures.target
		T.truthy(hasSkull("target"))
		T.truthy(texture.__parent == container)
		T.truthy(texture.__allPoints == container.Portrait)
		T.eq({ texture.__layer, texture.__sublevel }, { "BACKGROUND", 2 })
		-- A round mask of its own, a little inside the portrait, so the ring covers the edge.
		local mask = texture.__mask
		T.truthy(mask.__parent == container)
		T.eq(mask.__file, Marks.MASK)
		T.eq(mask.__points, {
			{ "TOPLEFT", container.Portrait, "TOPLEFT", Marks.INSET, -Marks.INSET },
			{ "BOTTOMRIGHT", container.Portrait, "BOTTOMRIGHT", -Marks.INSET, Marks.INSET },
		})
	end)

	it("still shows the skull, unmasked, on a client without mask textures", function()
		env.TargetFrame.TargetFrameContainer.CreateMaskTexture = false
		keys.target = "Kane-Mochivich"
		marks:Update("target")
		T.truthy(hasSkull("target"))
		T.isNil(marks.textures.target.__mask)
	end)

	it("never goes past the top sublevel", function()
		env.TargetFrame.TargetFrameContainer.Portrait.__sublevel = 7
		keys.target = "Kane-Mochivich"
		marks:Update("target")
		T.eq(marks.textures.target.__sublevel, 7)
	end)

	it("leaves the portrait alone for anyone outside the list", function()
		keys.target = "Stranger-Nobody"
		marks:Update("target")
		T.isNil(marks.textures.target)
		marks:Update("focus") -- nobody
		T.isNil(marks.textures.focus)
	end)

	it("hides the skull when the target changes to someone else, and reuses it", function()
		keys.target = "Kane-Mochivich"
		marks:Update("target")
		local texture = marks.textures.target
		keys.target = "Stranger-Nobody"
		marks:Update("target")
		T.falsy(hasSkull("target"))
		keys.target = "Kane-Mochivich"
		marks:Update("target")
		T.truthy(hasSkull("target"))
		T.truthy(marks.textures.target == texture, "one texture per frame")
	end)

	it("follows the list and the option on refresh, for target and focus", function()
		keys.target, keys.focus = "Kane-Mochivich", "Cabo-Trancas"
		marks:Refresh()
		T.truthy(hasSkull("target"))
		T.falsy(hasSkull("focus"))

		players["Cabo-Trancas"] = {}
		marks:Refresh()
		T.truthy(hasSkull("focus"))

		enabled = false
		marks:Refresh()
		T.falsy(hasSkull("target"))
		T.falsy(hasSkull("focus"))
	end)

	it("ignores units it has no frame for and frames that are not Blizzard's", function()
		keys.target, keys.party1 = "Kane-Mochivich", "Kane-Mochivich"
		marks:Update("party1")
		marks.frames.target = ns.Util -- a table with no portrait
		marks:Update("target")
		T.isNil(marks.textures.target)
	end)
end)
