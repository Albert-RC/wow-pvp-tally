local T, Addon = ...
local describe, it = T.describe, T.it

-- Every client language and the file that translates it (enUS is the base).
local LOCALES = {
	enGB = "enUS", deDE = "deDE", esES = "esES", esMX = "esES", frFR = "frFR", itIT = "itIT",
	koKR = "koKR", ptBR = "ptBR", ptPT = "ptBR", ruRU = "ruRU", zhCN = "zhCN", zhTW = "zhTW",
}

-- Keys a translation may leave in English: names and symbols.
local SAME_EVERYWHERE = { TITLE = true, UNKNOWN_LEVEL = true, SETTINGS_SPY_HEADER = true }

local function IsLocaleFile(file)
	return file:find("^Locales/") ~= nil
end

-- Every L.KEY the code uses, from the source files.
local function UsedKeys()
	local used = {}
	for _, file in ipairs(Addon.Toc().files) do
		if not IsLocaleFile(file) then
			for key in Addon.ReadFile(Addon.Path(file)):gmatch("%f[%w_]L%.([%u_][%w_]*)") do
				used[key] = file
			end
		end
	end
	return used
end

-- The keys a locale file assigns.
local function AssignedKeys(file)
	local keys = {}
	for key in Addon.ReadFile(Addon.Path("Locales/" .. file .. ".lua")):gmatch("%f[%w_]L%.([%a_][%w_]*)%s*=") do
		keys[key] = true
	end
	return keys
end

local function Placeholders(text)
	local list = {}
	for p in text:gmatch("%%[%d%.]*[sdf]") do list[#list + 1] = p end
	return table.concat(list, " ")
end

local function Strings(locale)
	return Addon.LoadWith({}, { locale = locale }).L
end

describe("Locales", function()
	it("loads every locale file from the TOC, English first", function()
		local files = Addon.LocaleFiles()
		T.eq(files[1], "Locales/enUS.lua")
		local listed = {}
		for _, file in ipairs(files) do listed[file] = true end
		for _, file in pairs(LOCALES) do
			T.truthy(listed["Locales/" .. file .. ".lua"], file)
		end
	end)

	it("defines every string the code uses, in English", function()
		local L = Strings("enUS")
		for key, file in pairs(UsedKeys()) do
			T.notNil(rawget(L, key), "L." .. key .. " used in " .. file)
		end
	end)

	it("translates every English string in every language", function()
		local english = AssignedKeys("enUS")
		for locale, file in pairs(LOCALES) do
			if file ~= "enUS" then
				local translated = AssignedKeys(file)
				for key in pairs(english) do
					if not SAME_EVERYWHERE[key] then
						T.truthy(translated[key] == true, locale .. ": L." .. key)
					end
				end
			end
		end
	end)

	it("translates only keys that exist in English", function()
		local english = AssignedKeys("enUS")
		for _, file in pairs(LOCALES) do
			for key in pairs(AssignedKeys(file)) do
				T.truthy(english[key] == true, file .. ": L." .. key)
			end
		end
	end)

	it("keeps the format placeholders of the English strings, in order", function()
		local english = Strings("enUS")
		for locale in pairs(LOCALES) do
			local L = Strings(locale)
			for key, value in pairs(english) do
				T.eq(Placeholders(L[key]), Placeholders(value), locale .. ": L." .. key)
			end
		end
	end)

	it("only translates on its own client", function()
		T.eq(Strings("enUS").COL_PLAYER, "Player")
		T.eq(Strings("esES").COL_PLAYER, "Jugador")
		T.eq(Strings("esMX").WIN, "Victoria")
		T.eq(Strings("deDE").COL_PLAYER, "Spieler")
		T.eq(Strings("frFR").COL_PLAYER, "Joueur")
		T.eq(Strings("ptPT").COL_PLAYER, "Jogador")
		T.eq(Strings("zhTW").COL_PLAYER, "玩家")
	end)

	it("uses English on a client language without translation", function()
		T.eq(Strings("xxXX").COL_PLAYER, "Player")
	end)

	it("orders dates the way each language does", function()
		T.eq(Strings("enUS").DATE_SHORT, "%m/%d/%y %H:%M")
		T.eq(Strings("enGB").DATE_SHORT, "%d/%m/%y %H:%M")
		T.eq(Strings("deDE").DATE_LONG, "%d.%m.%Y %H:%M")
		T.eq(Strings("zhCN").DATE_LONG, "%Y/%m/%d %H:%M")
	end)

	it("falls back to the key for a missing string", function()
		T.eq(Addon.LoadWith({}).L.NOT_A_STRING, "NOT_A_STRING")
	end)

	describe("class names", function()
		it("uses the feminine class name for a woman", function()
			local ns, env = Addon.LoadAll({ locale = "esES" })
			env.LOCALIZED_CLASS_NAMES_MALE = { ROGUE = "Pícaro", MAGE = "Mago" }
			env.LOCALIZED_CLASS_NAMES_FEMALE = { ROGUE = "Pícara" }
			T.eq(ns.Rows.ClassName("ROGUE", ns.Races.FEMALE), "Pícara")
			T.eq(ns.Rows.ClassName("ROGUE", ns.Races.MALE), "Pícaro")
			T.eq(ns.Rows.ClassName("ROGUE", nil), "Pícaro")
			T.eq(ns.Rows.ClassName("MAGE", ns.Races.FEMALE), "Mago") -- no feminine form known
			T.isNil(ns.Rows.ClassName(nil, ns.Races.FEMALE))
		end)

		it("works when the client has no feminine names", function()
			local ns, env = Addon.LoadAll()
			env.LOCALIZED_CLASS_NAMES_FEMALE = nil
			T.eq(ns.Rows.ClassName("ROGUE", ns.Races.FEMALE), "Rogue")
		end)
	end)

	describe("TOC", function()
		it("has notes and category in every language", function()
			local fields = Addon.Toc().fields
			for locale in pairs(LOCALES) do
				if locale ~= "enGB" and locale ~= "ptPT" then
					T.notNil(fields["Notes-" .. locale], "Notes-" .. locale)
					T.notNil(fields["Category-" .. locale], "Category-" .. locale)
				end
			end
		end)
	end)
end)
