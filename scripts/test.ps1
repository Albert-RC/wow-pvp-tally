# Runs the unit tests in tests/ with LuaJIT (Lua 5.1 compatible).
# Usage: ./scripts/test.ps1
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
	luajit tests/run.lua
	exit $LASTEXITCODE
}
finally {
	Pop-Location
}
