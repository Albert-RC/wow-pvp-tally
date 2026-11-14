-- PvP Tally: small helpers shared by every module. No state, no events.

local _, ns = ...

local Util = {}
ns.Util = Util

-- Secret values -------------------------------------------------------------------------
-- Forever runs the modern client: the API may hand addons opaque "secret" values that
-- can be displayed but not compared, concatenated or used as table keys. Everything
-- read from the game goes through Readable, which turns a secret into nil.

function Util.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) == true
end

function Util.IsSecretTable(value)
	return issecrettable ~= nil and issecrettable(value) == true
end

function Util.Readable(value)
	if value == nil or Util.IsSecret(value) then
		return nil
	end
	return value
end

-- Errors ----------------------------------------------------------------------------------

-- The last error caught by Guard, shown by /tally debug.
Util.lastError = nil

function Util.ReportError(label, err)
	Util.lastError = tostring(label) .. ": " .. tostring(err)
end

-- Wraps a handler so an error is kept for /tally debug instead of breaking the handler
-- (or spamming the chat) for the rest of the session.
function Util.Guard(label, fn)
	return function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			Util.ReportError(label, err)
		end
		return ok
	end
end

-- Text --------------------------------------------------------------------------------------

function Util.Trim(text)
	return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- The first `count` characters of a UTF-8 text (a cut by bytes could split a letter),
-- and whether something was left out.
function Util.FirstCharacters(text, count)
	local position, characters = 1, 0
	while position <= #text do
		characters = characters + 1
		if characters > count then
			return text:sub(1, position - 1), true
		end
		-- A lead byte takes its continuation bytes along; any other byte stands alone.
		local _, last = text:find("^[\192-\255][\128-\191]*", position)
		position = (last or position) + 1
	end
	return text, false
end

-- Player keys are "First-Surname" (the realm slot holds the surname on Forever), the
-- same key Spy uses. Shown with a space: "Cabo-Trancas" -> "Cabo Trancas".
function Util.DisplayName(key)
	return (tostring(key):gsub("%-", " ", 1))
end

local DEFAULT_COLOR = { r = 1, g = 0.82, b = 0 }

function Util.ClassColor(class)
	local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or DEFAULT_COLOR
	return color.r, color.g, color.b
end

local function ColorByte(value)
	return Util.Clamp(math.floor(value * 255 + 0.5), 0, 255)
end

function Util.ColorText(text, r, g, b)
	return ("|cff%02x%02x%02x%s|r"):format(ColorByte(r), ColorByte(g), ColorByte(b), tostring(text))
end

function Util.ColoredName(key, class)
	local r, g, b = Util.ClassColor(class)
	return Util.ColorText(Util.DisplayName(key), r, g, b)
end

-- Local time, in the order of the client's language (L.DATE_SHORT / L.DATE_LONG).
-- English: short "11/12/26 18:42", long "11/12/2026 18:42".
function Util.FormatDate(t, long)
	if type(t) ~= "number" then
		return "-"
	end
	return date(long and ns.L.DATE_LONG or ns.L.DATE_SHORT, t)
end

-- Numbers ------------------------------------------------------------------------------------

function Util.Clamp(value, low, high)
	return math.max(low, math.min(high, value))
end

function Util.IsFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Chat ----------------------------------------------------------------------------------------

function Util.Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. ns.L.TITLE .. ":|r " .. tostring(message))
end
