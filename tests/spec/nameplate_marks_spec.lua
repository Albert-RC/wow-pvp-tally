local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("NameplateMarks", function()
	local ns, env, Marks, marks
	local players, keys, enabled
	before_each(function()
		ns, env = Addon.LoadWith({ "UI/ListModel.lua", "UI/Rows.lua", "UI/NameplateMarks.lua" })
		Marks = ns.NameplateMarks
		players = { ["Kane-Mochivich"] = { name = "Kane" } } -- the list
		keys = {}                                            -- unit token -> player key
		enabled = true
		marks = Marks.New({
			playerKey = function(unit) return keys[unit] end,
			namePlateFor = function(unit) return env.__nameplates[unit] end,
			lookup = function(key) return players[key] end,
			isEnabled = function() return enabled end,
		})
	end)

	-- A player's nameplate appears: on screen, then the event.
	local function appear(unit, key, nameplate)
		keys[unit] = key
		nameplate = env.__showNamePlate(unit, nameplate)
		marks:Show(unit)
		return nameplate
	end

	local function disappear(unit)
		marks:Remove(unit)
		env.__hideNamePlate(unit)
	end

	local function skull(nameplate)
		return marks.textures[nameplate]
	end

	local function hasSkull(nameplate)
		local texture = skull(nameplate)
		return texture ~= nil and texture:IsShown()
	end

	describe("MarkFor", function()
		it("gives the skull to a player of the list and nothing to anyone else", function()
			T.eq(Marks.MarkFor({ name = "Kane" }), { file = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" })
			T.isNil(Marks.MarkFor(nil))
			T.isNil(Marks.MarkFor("Kane-Mochivich"))
		end)
	end)

	it("needs all its collaborators", function()
		T.raises(function() Marks.New() end, "options expected")
		T.raises(function()
			Marks.New({ playerKey = function() end, namePlateFor = function() end, lookup = function() end })
		end, "isEnabled function expected")
	end)

	it("puts a skull left of the name of a player in the list", function()
		local nameplate = appear("nameplate1", "Kane-Mochivich")
		T.truthy(hasSkull(nameplate))
		local texture = skull(nameplate)
		T.eq(texture.__file, "Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
		T.eq({ texture.__width, texture.__height }, { Marks.SIZE, Marks.SIZE })
		T.eq(texture.__points[1], { "RIGHT", nameplate.UnitFrame.name, "LEFT", -Marks.GAP, 0 })
	end)

	it("puts nothing on players outside the list, unreadable names or NPCs", function()
		T.isNil(skull(appear("nameplate1", "Stranger-Nobody")))
		T.isNil(skull(appear("nameplate2", nil)))
	end)

	it("sits above the nameplate when Blizzard's frame has no name", function()
		keys.nameplate1 = "Kane-Mochivich"
		local nameplate = env.__showNamePlate("nameplate1")
		nameplate.UnitFrame.name = nil
		marks:Show("nameplate1")
		T.eq(skull(nameplate).__points[1], { "BOTTOM", nameplate.UnitFrame, "TOP", 0, 0 })
	end)

	it("leaves forbidden or missing nameplates alone", function()
		keys.nameplate1 = "Kane-Mochivich"
		marks:Show("nameplate1") -- no nameplate on screen
		T.isNil(marks.units.nameplate1)
		marks:Show(nil)
		marks:Remove(nil)
	end)

	it("hides the skull when the nameplate goes", function()
		local nameplate = appear("nameplate1", "Kane-Mochivich")
		disappear("nameplate1")
		T.falsy(hasSkull(nameplate))
		T.isNil(marks.units.nameplate1)
	end)

	describe("recycled nameplates", function()
		it("hides the skull when the nameplate comes back for someone else", function()
			local nameplate = appear("nameplate1", "Kane-Mochivich")
			disappear("nameplate1")
			appear("nameplate4", "Stranger-Nobody", nameplate)
			T.falsy(hasSkull(nameplate))
		end)

		it("shows it again, on the same texture, for another player of the list", function()
			players["Cabo-Trancas"] = {}
			local nameplate = appear("nameplate1", "Stranger-Nobody")
			disappear("nameplate1")
			appear("nameplate2", "Kane-Mochivich", nameplate)
			local texture = skull(nameplate)
			disappear("nameplate2")
			appear("nameplate3", "Cabo-Trancas", nameplate)
			T.truthy(hasSkull(nameplate))
			T.truthy(skull(nameplate) == texture, "one texture per nameplate")
		end)

		it("moves the skull when a unit token comes back on another nameplate", function()
			local first = appear("nameplate1", "Kane-Mochivich")
			env.__hideNamePlate("nameplate1") -- no NAME_PLATE_UNIT_REMOVED
			local second = appear("nameplate1", "Kane-Mochivich")
			T.falsy(hasSkull(first), "not left on the old nameplate")
			T.truthy(hasSkull(second))
		end)

		it("copes with a removal it never heard of", function()
			local nameplate = appear("nameplate1", "Kane-Mochivich")
			env.__hideNamePlate("nameplate1") -- no NAME_PLATE_UNIT_REMOVED
			appear("nameplate2", "Stranger-Nobody", nameplate)
			T.falsy(hasSkull(nameplate))
			T.isNil(marks.units.nameplate1, "the old unit no longer owns it")
			keys.nameplate2 = "Kane-Mochivich"
			marks:Refresh()
			T.truthy(hasSkull(nameplate))
		end)
	end)

	describe("Refresh", function()
		it("marks a player who just entered the list", function()
			local nameplate = appear("nameplate1", "Stranger-Nobody")
			players["Stranger-Nobody"] = {}
			marks:Refresh()
			T.truthy(hasSkull(nameplate))
		end)

		it("unmarks a player who was deleted", function()
			local nameplate = appear("nameplate1", "Kane-Mochivich")
			players["Kane-Mochivich"] = nil
			marks:Refresh()
			T.falsy(hasSkull(nameplate))
		end)

		it("follows the option", function()
			local nameplate = appear("nameplate1", "Kane-Mochivich")
			enabled = false
			marks:Refresh()
			T.falsy(hasSkull(nameplate))
			enabled = true
			marks:Refresh()
			T.truthy(hasSkull(nameplate))
		end)

		it("drops a nameplate that is gone or became forbidden", function()
			local nameplate = appear("nameplate1", "Kane-Mochivich")
			env.__hideNamePlate("nameplate1")
			marks:Refresh()
			T.falsy(hasSkull(nameplate))
			T.isNil(marks.units.nameplate1)
		end)
	end)

	it("takes its size from the settings, and follows changes on refresh", function()
		local size = 24
		marks = Marks.New({
			playerKey = function(unit) return keys[unit] end,
			namePlateFor = function(unit) return env.__nameplates[unit] end,
			lookup = function(key) return players[key] end,
			isEnabled = function() return true end,
			size = function() return size end,
		})
		local nameplate = appear("nameplate1", "Kane-Mochivich")
		T.eq({ skull(nameplate).__width, skull(nameplate).__height }, { 24, 24 })
		size = 12
		marks:Refresh()
		T.eq({ skull(nameplate).__width, skull(nameplate).__height }, { 12, 12 })
	end)

	it("draws nothing while the option is off", function()
		enabled = false
		T.isNil(skull(appear("nameplate1", "Kane-Mochivich")))
	end)
end)
