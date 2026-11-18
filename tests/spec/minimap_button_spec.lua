local T, Addon = ...
local describe, it, before_each = T.describe, T.it, T.before_each

describe("MinimapButton", function()
	local MinimapButton
	before_each(function()
		MinimapButton = Addon.LoadWith({ "UI/MinimapButton.lua" }).MinimapButton
	end)

	describe("Offset", function()
		it("puts the button just outside the rim of a round minimap, as LibDBIcon does", function()
			-- Forever's minimap is 198 wide: 99 to the rim, plus the same 5 as LibDBIcon.
			local x, y = MinimapButton.Offset(0, 198, 198, "ROUND")
			T.near(x, 104, 0.001)
			T.near(y, 0, 0.001)
			x, y = MinimapButton.Offset(math.pi / 2, 198, 198, "ROUND")
			T.near(x, 0, 0.001)
			T.near(y, 104, 0.001)
		end)

		it("follows the minimap size, not a fixed radius", function()
			local x = MinimapButton.Offset(math.pi, 140, 140, "ROUND")
			T.near(x, -75, 0.001)
		end)

		it("assumes the classic size when the minimap size is unknown", function()
			local x = MinimapButton.Offset(0, nil, nil, "ROUND")
			T.near(x, MinimapButton.DEFAULT_SIZE / 2 + MinimapButton.EDGE_OFFSET, 0.001)
		end)

		it("slides along the sides of a square minimap", function()
			-- Along the diagonal, sqrt(2) * 104 - 10, then clamped to the sides.
			local diagonal = math.sqrt(2 * 104 * 104) - 10
			local x, y = MinimapButton.Offset(math.pi / 6, 198, 198, "SQUARE")
			T.near(x, 104, 0.001, "clamped to the right side")
			T.near(y, 0.5 * diagonal, 0.001)
			x, y = MinimapButton.Offset(0, 198, 198, "SQUARE")
			T.near(x, 104, 0.001)
			T.near(y, 0, 0.001)
		end)

		it("rounds the corner of a square minimap a little inside it, as LibDBIcon does", function()
			local x, y = MinimapButton.Offset(math.pi / 4, 198, 198, "SQUARE")
			local inside = (math.sqrt(2 * 104 * 104) - 10) * math.cos(math.pi / 4)
			T.near(x, inside, 0.001)
			T.near(y, inside, 0.001)
			T.truthy(x < 104 and y < 104)
		end)

		it("is round only in the round quadrants of a mixed shape", function()
			local angle = 3 * math.pi / 4 -- top left
			local roundX = MinimapButton.Offset(angle, 198, 198, "ROUND")
			T.near(MinimapButton.Offset(angle, 198, 198, "CORNER-TOPLEFT"), roundX, 0.001)
			T.near(MinimapButton.Offset(5 * math.pi / 6, 198, 198, "CORNER-TOPRIGHT"), -104, 0.001,
				"square in the top left: clamped to the left side")
		end)

		it("treats an unknown shape as round", function()
			local x, y = MinimapButton.Offset(math.pi / 4, 198, 198, "HEXAGON")
			local roundX, roundY = MinimapButton.Offset(math.pi / 4, 198, 198, "ROUND")
			T.near(x, roundX, 0.001)
			T.near(y, roundY, 0.001)
		end)
	end)

	it("measures the angle from the minimap center", function()
		T.near(MinimapButton.AngleTo(100, 100, 200, 100), 0, 0.001)
		T.near(MinimapButton.AngleTo(100, 100, 100, 200), math.pi / 2, 0.001)
	end)
end)
