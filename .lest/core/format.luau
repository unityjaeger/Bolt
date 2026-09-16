--!strict
--- Value formatting and structural comparison shared by the matchers.
--- Failure events carry pre-formatted strings so the protocol stays JSON-safe.

local format = {}

local MAX_DEPTH = 4

local function sortedKeys (t: { [any]: any }): { any }
	local keys = {}
	for key in pairs(t) do
		table.insert(keys, key)
	end
	table.sort(keys, function (a: any, b: any): boolean
		local ta, tb = type(a), type(b)
		if ta ~= tb then
			return ta < tb
		end
		if ta == 'number' then
			return a < b
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function formatValue (value: any, depth: number, seen: { [any]: boolean }): string
	local t = type(value)
	if t == 'string' then
		return string.format('%q', value)
	end
	if t ~= 'table' then
		return tostring(value)
	end
	if seen[value] then
		return '<cycle>'
	end
	if depth >= MAX_DEPTH then
		return '{...}'
	end

	local keys = sortedKeys(value)
	if #keys == 0 then
		return '{}'
	end
	seen[value] = true
	local isArray = #value == #keys
	local parts = {}
	for _, key in keys do
		local entry = formatValue(value[key], depth + 1, seen)
		if isArray then
			table.insert(parts, entry)
		elseif type(key) == 'string' and string.match(key, '^[%a_][%w_]*$') ~= nil then
			table.insert(parts, `{key} = {entry}`)
		else
			table.insert(parts, `[{formatValue(key, depth + 1, seen)}] = {entry}`)
		end
	end
	seen[value] = nil
	return '{ ' .. table.concat(parts, ', ') .. ' }'
end

function format.value (value: any): string
	return formatValue(value, 0, {})
end

--- Lossless serializer behind `toMatchSnapshot`. Unlike `formatValue` — whose
--- depth cap keeps matcher *messages* short — a snapshot must capture the whole
--- value: truncating at a fixed depth would mean a change below that depth
--- could never fail the snapshot. So there is no depth cap here, and the two
--- shapes that cannot serialize deterministically are rejected outright rather
--- than papered over:
---
---   * cycles — there is no finite lossless rendering of one; and
---   * non-scalar table keys (table/function/userdata/…) — `tostring` on those
---     embeds a memory address, so any ordering derived from it changes across
---     runs and backends, making the snapshot nondeterministic.
---
--- Scalar keys sort deterministically (by type name, then value — see
--- `sortedKeys`). Non-table reference *values* (functions, threads, userdata)
--- render as a stable `<type>` placeholder for the same address reason.
local function serializeSnapshot (value: any, seen: { [any]: boolean }): string
	local t = type(value)
	if t == 'string' then
		return string.format('%q', value)
	end
	if t ~= 'table' then
		if t == 'function' or t == 'thread' or t == 'userdata' or t == 'buffer' then
			-- `tostring` here embeds a memory address; a fixed placeholder keeps
			-- the snapshot identical across runs and backends.
			return `<{typeof(value)}>`
		end
		return tostring(value)
	end
	if seen[value] then
		error('snapshot values must not contain cycles', 0)
	end

	for key in pairs(value) do
		local kt = type(key)
		if kt ~= 'string' and kt ~= 'number' and kt ~= 'boolean' then
			error(
				`snapshot table keys must be strings, numbers, or booleans, got a {typeof(key)} key`
					.. ' — non-scalar keys order by memory address, which is not deterministic across runs',
				0
			)
		end
	end

	local keys = sortedKeys(value)
	if #keys == 0 then
		return '{}'
	end
	seen[value] = true
	local isArray = #value == #keys
	local parts = {}
	for _, key in keys do
		local entry = serializeSnapshot(value[key], seen)
		if isArray then
			table.insert(parts, entry)
		elseif type(key) == 'string' and string.match(key, '^[%a_][%w_]*$') ~= nil then
			table.insert(parts, `{key} = {entry}`)
		else
			table.insert(parts, `[{serializeSnapshot(key, seen)}] = {entry}`)
		end
	end
	-- Cleared on the way out so a table shared by two sibling branches (a DAG)
	-- serializes in both places rather than being mistaken for a cycle.
	seen[value] = nil
	return '{ ' .. table.concat(parts, ', ') .. ' }'
end

--- Returns the lossless snapshot serialization of `value`, or `nil` plus a
--- human-readable reason when the value cannot be snapshotted (cycles,
--- non-scalar table keys). The caller turns the reason into an assertion
--- failure through the normal structured path.
function format.snapshot (value: any): (string?, string?)
	local ok, result = pcall(serializeSnapshot, value, {})
	if ok then
		return result :: string, nil
	end
	return nil, tostring(result)
end

--- `seen` records the (a, b) pairs currently being compared further up the
--- stack. Meeting a pair again means a back-reference on both sides, so the
--- comparison is treated as true — the standard co-inductive reading of
--- structural equality, and the only thing that stops cyclic tables (parent
--- pointers, graphs) from overflowing the stack. `formatValue` guards cycles the
--- same way, so a value that prints fine also compares fine.
local function deepEqual (a: any, b: any, seen: { [any]: { [any]: boolean } }): boolean
	if a == b then
		return true
	end
	-- Jest's `toEqual` treats NaN as equal to NaN; `toBe` keeps plain `==`
	-- semantics, where it is not. `x ~= x` is the NaN test, mirroring the guard
	-- in `toBeCloseTo` — both sides must be NaN for the pair to compare equal.
	if type(a) == 'number' and type(b) == 'number' and a ~= a and b ~= b then
		return true
	end
	if type(a) ~= 'table' or type(b) ~= 'table' then
		return false
	end

	local pairedWith = seen[a]
	if pairedWith == nil then
		pairedWith = {}
		seen[a] = pairedWith
	end
	if pairedWith[b] then
		return true
	end
	-- Never cleared on the way out: a false result unwinds the whole comparison
	-- immediately, and a true one is only ever re-derived.
	pairedWith[b] = true

	for key, valueA in pairs(a) do
		if not deepEqual(valueA, b[key], seen) then
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

function format.deepEqual (a: any, b: any): boolean
	return deepEqual(a, b, {})
end

return format
