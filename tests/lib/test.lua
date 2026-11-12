-- A minimal test framework, so the suite needs nothing but a Lua 5.1 interpreter
-- (LuaJIT or PUC Lua 5.1, the language WoW runs).
--
--   describe(name, fn)   groups tests; may nest
--   before_each(fn)      runs before every test of the group (and nested groups declared after it)
--   it(name, fn)         a test
--   T.eq / T.truthy / T.falsy / T.isNil / T.notNil / T.raises / T.contains / T.near

local T = {}

local suites = {}
local stack = {}

local function current()
	local suite = stack[#stack]
	assert(suite, "it / before_each must be inside describe")
	return suite
end

function T.describe(name, fn)
	local parent = stack[#stack]
	local suite = {
		name = parent and (parent.name .. " > " .. name) or name,
		before = {},
		tests = {},
	}
	if parent then
		for _, hook in ipairs(parent.before) do
			suite.before[#suite.before + 1] = hook
		end
	end
	suites[#suites + 1] = suite
	stack[#stack + 1] = suite
	fn()
	stack[#stack] = nil
end

function T.before_each(fn)
	local suite = current()
	suite.before[#suite.before + 1] = fn
end

function T.it(name, fn)
	local suite = current()
	suite.tests[#suite.tests + 1] = { name = name, fn = fn }
end

-- Assertions -----------------------------------------------------------------------------

local function describeValue(value, depth)
	depth = depth or 0
	if type(value) == "string" then
		return ("%q"):format(value)
	end
	if type(value) ~= "table" or depth > 2 then
		return tostring(value)
	end
	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, key in ipairs(keys) do
		parts[#parts + 1] = tostring(key) .. "=" .. describeValue(value[key], depth + 1)
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end
T.describeValue = describeValue

local function deepEqual(a, b)
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in pairs(a) do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function fail(message, detail)
	error((message and (message .. ": ") or "") .. detail, 3)
end

function T.eq(actual, expected, message)
	if not deepEqual(actual, expected) then
		fail(message, "expected " .. describeValue(expected) .. ", got " .. describeValue(actual))
	end
end

function T.truthy(value, message)
	if not value then
		fail(message, "expected a true value, got " .. describeValue(value))
	end
end

function T.falsy(value, message)
	if value then
		fail(message, "expected a false value, got " .. describeValue(value))
	end
end

function T.isNil(value, message)
	if value ~= nil then
		fail(message, "expected nil, got " .. describeValue(value))
	end
end

function T.notNil(value, message)
	if value == nil then
		fail(message, "expected a value, got nil")
	end
end

function T.near(actual, expected, tolerance, message)
	if type(actual) ~= "number" or math.abs(actual - expected) > (tolerance or 1e-9) then
		fail(message, "expected about " .. tostring(expected) .. ", got " .. describeValue(actual))
	end
end

function T.contains(text, fragment, message)
	if type(text) ~= "string" or not text:find(fragment, 1, true) then
		fail(message, "expected " .. describeValue(text) .. " to contain " .. describeValue(fragment))
	end
end

function T.raises(fn, pattern, message)
	local ok, err = pcall(fn)
	if ok then
		fail(message, "expected an error")
	end
	if pattern and not tostring(err):find(pattern) then
		fail(message, "error " .. describeValue(tostring(err)) .. " does not match " .. describeValue(pattern))
	end
end

-- Running -------------------------------------------------------------------------------------

function T.run(output)
	output = output or io.write
	local passed, failures = 0, {}
	for _, suite in ipairs(suites) do
		for _, test in ipairs(suite.tests) do
			local ok, err = xpcall(function()
				for _, hook in ipairs(suite.before) do
					hook()
				end
				test.fn()
			end, debug.traceback)
			if ok then
				passed = passed + 1
				output(".")
			else
				failures[#failures + 1] = { name = suite.name .. " > " .. test.name, err = err }
				output("F")
			end
		end
	end
	output("\n\n")
	for _, failure in ipairs(failures) do
		output("FAIL " .. failure.name .. "\n" .. tostring(failure.err) .. "\n\n")
	end
	output(("%d passed, %d failed\n"):format(passed, #failures))
	return #failures == 0
end

return T
