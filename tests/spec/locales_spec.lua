local T, Addon = ...
local describe, it = T.describe, T.it

-- Every L.KEY the code uses, from the source files.
local function UsedKeys()
	local used = {}
	for _, file in ipairs(Addon.Toc().files) do
		if file ~= "Locales.lua" then
			for key in Addon.ReadFile(Addon.Path(file)):gmatch("%f[%w_]L%.([%u_][%w_]*)") do
				used[key] = file
			end
		end
	end
	return used
end

describe("Locales", function()
	it("defines every string the code uses, in English", function()
		local L = Addon.LoadWith({}, { locale = "enUS" }).L
		for key, file in pairs(UsedKeys()) do
			T.notNil(rawget(L, key), "L." .. key .. " used in " .. file)
		end
	end)

	it("translates into Spanish only keys that exist in English", function()
		local english = Addon.LoadWith({}, { locale = "enUS" }).L
		local spanish = Addon.LoadWith({}, { locale = "esES" }).L
		for key in pairs(spanish) do
			T.notNil(rawget(english, key), "L." .. key)
		end
		T.eq(spanish.COL_PLAYER, "Jugador")
		T.eq(rawget(spanish, "COL_FIRST"), "Primer encuentro")
	end)

	it("uses Spanish for Latin America too", function()
		T.eq(Addon.LoadWith({}, { locale = "esMX" }).L.WIN, "Victoria")
	end)

	it("keeps the format placeholders of the English strings", function()
		local english = Addon.LoadWith({}, { locale = "enUS" }).L
		local spanish = Addon.LoadWith({}, { locale = "esES" }).L
		local function placeholders(text)
			local list = {}
			for p in text:gmatch("%%[%d%.]*[sdf]") do list[#list + 1] = p end
			return table.concat(list, " ")
		end
		for key, value in pairs(english) do
			if type(value) == "string" and rawget(spanish, key) then
				T.eq(placeholders(spanish[key]), placeholders(value), "L." .. key)
			end
		end
	end)

	it("falls back to the key for a missing string", function()
		T.eq(Addon.LoadWith({}).L.NOT_A_STRING, "NOT_A_STRING")
	end)
end)
