-- busted_shim.lua - just enough of busted's describe/it/before_each/assert to run the specs
-- without luarocks. Real `busted` runs the same spec files unchanged.

local results = { passed = 0, failed = 0, failures = {} }
local stack = {}

local function deepEqual(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do
        if not deepEqual(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

local function show(v)
    if type(v) ~= "table" then return tostring(v) end
    local parts = {}
    for k, val in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. show(val) end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function check(ok, msg)
    if not ok then error(msg, 3) end
end

local luaAssert = assert
local are = {
    equal = function(expected, actual)
        check(expected == actual, "expected " .. show(expected) .. ", got " .. show(actual))
    end,
    same = function(expected, actual)
        check(deepEqual(expected, actual), "expected " .. show(expected) .. ", got " .. show(actual))
    end,
}
assert = setmetatable({
    are = are,
    is_nil = function(v) check(v == nil, "expected nil, got " .. show(v)) end,
    is_true = function(v) check(v == true, "expected true, got " .. show(v)) end,
    is_false = function(v) check(v == false, "expected false, got " .. show(v)) end,
}, { __call = function(_, ...) return luaAssert(...) end })

function describe(name, fn)
    stack[#stack + 1] = { name = name, before = {} }
    fn()
    stack[#stack] = nil
end

function before_each(fn)
    local scope = stack[#stack]
    scope.before[#scope.before + 1] = fn
end

function it(name, fn)
    local names = {}
    for _, scope in ipairs(stack) do names[#names + 1] = scope.name end
    names[#names + 1] = name
    local ok, err = pcall(function()
        for _, scope in ipairs(stack) do
            for _, hook in ipairs(scope.before) do hook() end
        end
        fn()
    end)
    if ok then
        results.passed = results.passed + 1
    else
        results.failed = results.failed + 1
        results.failures[#results.failures + 1] = table.concat(names, " > ") .. "\n    " .. tostring(err)
    end
end

return results
