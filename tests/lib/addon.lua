-- Loads the addon's files into an isolated fake-WoW environment, the way the client does:
-- each file is a chunk called with (addonName, namespace).

local Wow = require("wow")

local Addon = {}

Addon.NAME = "PvPTally"
Addon.ROOT = nil -- set by run.lua

function Addon.Path(file)
	return Addon.ROOT .. "/" .. Addon.NAME .. "/" .. file:gsub("\\", "/")
end

function Addon.ReadFile(path)
	local handle = assert(io.open(path, "rb"))
	local content = handle:read("*a")
	handle:close()
	return content
end

-- The TOC: { files = { "Locales/enUS.lua", "Core/Util.lua", ... }, fields = { Interface = "16001", ... } }
function Addon.Toc()
	local toc = { files = {}, fields = {} }
	for line in Addon.ReadFile(Addon.Path(Addon.NAME .. ".toc")):gmatch("[^\r\n]+") do
		local field, value = line:match("^##%s*([%w%-_]+):%s*(.-)%s*$")
		if field then
			toc.fields[field] = value
		elseif not line:match("^%s*#") and line:match("%S") then
			toc.files[#toc.files + 1] = (line:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\\", "/"))
		end
	end
	return toc
end

-- The files every module needs, in TOC order.
Addon.CORE = { "Core/Util.lua", "Core/Events.lua", "Core/Settings.lua", "Core/Store.lua", "Core/Races.lua" }

-- The texts: every file under Locales/, in TOC order (English first).
function Addon.LocaleFiles()
	local files = {}
	for _, file in ipairs(Addon.Toc().files) do
		if file:find("^Locales/") then files[#files + 1] = file end
	end
	return files
end

-- Loads `files` (TOC order) into a new environment. options: see Wow.NewEnv.
-- Returns the namespace and the environment.
function Addon.Load(files, options)
	local env = Wow.NewEnv(options)
	local ns = {}
	for _, file in ipairs(files) do
		local chunk = assert(loadfile(Addon.Path(file)))
		setfenv(chunk, env)
		chunk(Addon.NAME, ns)
	end
	return ns, env
end

-- The core plus some more files.
function Addon.LoadWith(extra, options)
	local files = {}
	for _, file in ipairs(Addon.LocaleFiles()) do files[#files + 1] = file end
	for _, file in ipairs(Addon.CORE) do files[#files + 1] = file end
	for _, file in ipairs(extra or {}) do files[#files + 1] = file end
	return Addon.Load(files, options)
end

-- Every file of the TOC, as the game loads them.
function Addon.LoadAll(options)
	return Addon.Load(Addon.Toc().files, options)
end

-- Loads everything and runs the startup events (saved variables come from options.globals).
function Addon.Start(options)
	local ns, env = Addon.LoadAll(options)
	env.__fire("ADDON_LOADED", Addon.NAME)
	env.__fire("PLAYER_LOGIN")
	return ns, env
end

return Addon
