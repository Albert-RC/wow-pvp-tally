-- Runs the PvP Tally test suite. From the repository root:
--
--   luajit tests/run.lua
--
-- Needs only a Lua 5.1 interpreter (LuaJIT or PUC Lua 5.1). Exits with 1 on failure.

local script = arg and arg[0] or "tests/run.lua"
local root = script:gsub("\\", "/"):match("^(.*)/tests/run%.lua$") or "."

package.path = root .. "/tests/lib/?.lua;" .. root .. "/tests/?.lua;" .. package.path

local T = require("test")
local Addon = require("addon")
Addon.ROOT = root

-- Specs, from the pure core outwards.
local SPECS = {
	"util_spec",
	"events_spec",
	"settings_spec",
	"store_spec",
	"races_spec",
	"wowapi_spec",
	"tracker_spec",
	"spy_import_spec",
	"test_data_spec",
	"notifications_spec",
	"columns_spec",
	"list_model_spec",
	"settings_panel_spec",
	"commands_spec",
	"locales_spec",
	"addon_spec",
}

for _, name in ipairs(SPECS) do
	local chunk = assert(loadfile(root .. "/tests/spec/" .. name .. ".lua"))
	chunk(T, Addon)
end

local ok = T.run()
os.exit(ok and 0 or 1)
