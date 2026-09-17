--!strict
--- `expect(value)` returns an expectation whose matchers are plain functions
--- closing over the value (`expect(x).toBe(y)` — no colon calls). Matchers
--- raise structured assertion failures; the runner recognizes the
--- `__lestAssertion` marker and reports them as `assertion` failures rather
--- than runtime errors. Every matcher returns the expectation for chaining.
---
--- Negated matchers are spelled `toNot...` because `not` is a Luau keyword,
--- so Jest's `.not.toBe` is unavailable.

local format = require('./format')
local context = require('./context')

local function fail (message: string, expected: string?, received: string?)
	error({
		__lestAssertion = true,
		message = message,
		expected = expected,
		received = received,
	}, 0)
end

--- Extracts a human-readable message from a caught error, unwrapping lest's
--- own assertion tables so `toThrow` can match on their message too.
local function errorMessage (err: any): string
	if type(err) == 'table' and (err :: any).message ~= nil then
		return tostring((err :: any).message)
	end
	return tostring(err)
end

local function expect (value: any): any
	local expectation: any = {}

	--- Identity: `==` semantics (tables compare by reference). For structural
	--- comparison use `toEqual`.
	function expectation.toBe (expected: any): any
		if value ~= expected then
			fail(
				`expected {format.value(value)} to be {format.value(expected)}`,
				format.value(expected),
				format.value(value)
			)
		end
		return expectation
	end

	function expectation.toNotBe (expected: any): any
		if value == expected then
			fail(
				`expected {format.value(value)} to not be {format.value(expected)}`,
				`not {format.value(expected)}`,
				format.value(value)
			)
		end
		return expectation
	end

	--- Deep structural equality (Jest's `toEqual`).
	function expectation.toEqual (expected: any): any
		if not format.deepEqual(value, expected) then
			fail(
				`expected {format.value(value)} to equal {format.value(expected)}`,
				format.value(expected),
				format.value(value)
			)
		end
		return expectation
	end

	function expectation.toNotEqual (expected: any): any
		if format.deepEqual(value, expected) then
			fail(
				`expected {format.value(value)} to not equal {format.value(expected)}`,
				`not {format.value(expected)}`,
				format.value(value)
			)
		end
		return expectation
	end

	function expectation.toBeTruthy (): any
		if not value then
			fail(`expected {format.value(value)} to be truthy`, nil, format.value(value))
		end
		return expectation
	end

	function expectation.toBeFalsy (): any
		if value then
			fail(`expected {format.value(value)} to be falsy`, nil, format.value(value))
		end
		return expectation
	end

	function expectation.toBeNil (): any
		if value ~= nil then
			fail(`expected {format.value(value)} to be nil`, 'nil', format.value(value))
		end
		return expectation
	end

	function expectation.toNotBeNil (): any
		if value == nil then
			fail('expected value to not be nil', 'not nil', 'nil')
		end
		return expectation
	end

	--- `typeof` check: `expect(x).toBeA('number')`.
	function expectation.toBeA (typeName: string): any
		if typeof(value) ~= typeName then
			fail(
				`expected {format.value(value)} to be a {typeName}, but it is a {typeof(value)}`,
				typeName,
				typeof(value)
			)
		end
		return expectation
	end

	--- Strings: plain substring. Arrays: any element deep-equal to `item`
	--- (reference equality is rarely what a Luau test means).
	function expectation.toContain (item: any): any
		if type(value) == 'string' then
			if type(item) ~= 'string' or string.find(value, item, 1, true) == nil then
				fail(
					`expected {format.value(value)} to contain {format.value(item)}`,
					format.value(item),
					format.value(value)
				)
			end
			return expectation
		end
		if type(value) == 'table' then
			for _, element in ipairs(value) do
				if format.deepEqual(element, item) then
					return expectation
				end
			end
			fail(
				`expected {format.value(value)} to contain {format.value(item)}`,
				format.value(item),
				format.value(value)
			)
		end
		fail(`expect(...).toContain requires a string or an array, got {format.value(value)}`)
		return expectation
	end

	function expectation.toHaveLength (length: number): any
		if type(value) ~= 'string' and type(value) ~= 'table' then
			fail(`expect(...).toHaveLength requires a string or a table, got {format.value(value)}`)
		end
		local actual = if type(value) == 'string' then #(value :: string) else #(value :: { any })
		if actual ~= length then
			fail(
				`expected {format.value(value)} to have length {length}, but its length is {actual}`,
				tostring(length),
				tostring(actual)
			)
		end
		return expectation
	end

	local function compare (op: string, expected: any, test: (any, any) -> boolean): any
		local comparable = (type(value) == 'number' and type(expected) == 'number')
			or (type(value) == 'string' and type(expected) == 'string')
		if not comparable then
			fail(
				`expect(...).{op} requires two numbers or two strings, got {format.value(value)} and {format.value(
					expected
				)}`
			)
		end
		if not test(value, expected) then
			fail(
				`expected {format.value(value)} {op} {format.value(expected)}`,
				`{op} {format.value(expected)}`,
				format.value(value)
			)
		end
		return expectation
	end

	function expectation.toBeGreaterThan (expected: any): any
		return compare('toBeGreaterThan', expected, function (a, b)
			return a > b
		end)
	end

	function expectation.toBeGreaterThanOrEqual (expected: any): any
		return compare('toBeGreaterThanOrEqual', expected, function (a, b)
			return a >= b
		end)
	end

	function expectation.toBeLessThan (expected: any): any
		return compare('toBeLessThan', expected, function (a, b)
			return a < b
		end)
	end

	function expectation.toBeLessThanOrEqual (expected: any): any
		return compare('toBeLessThanOrEqual', expected, function (a, b)
			return a <= b
		end)
	end

	--- Floating-point comparison: passes when |value - expected| < 10^-precision / 2.
	--- Precision defaults to 2, matching Jest.
	function expectation.toBeCloseTo (expected: number, precision: number?): any
		if type(value) ~= 'number' then
			fail(`expect(...).toBeCloseTo requires a number, got {format.value(value)}`)
		end
		-- Argument-side validation: a non-number `expected` would otherwise
		-- surface as a raw arithmetic error instead of a clear assertion.
		if type(expected) ~= 'number' then
			fail(`expect(...).toBeCloseTo requires a number to compare against, got {format.value(expected)}`)
		end
		-- NaN is never close to anything (and `NaN >= tolerance` is false, so
		-- the tolerance check alone would wrongly pass): reject it explicitly.
		if value ~= value or expected ~= expected then
			fail(
				`expected {format.value(value)} to be close to {format.value(expected)} (precision {precision or 2})`,
				format.value(expected),
				format.value(value)
			)
		end
		local digits = precision or 2
		local tolerance = 10 ^ -digits / 2
		if math.abs((value :: number) - expected) >= tolerance then
			fail(
				`expected {format.value(value)} to be close to {format.value(expected)} (precision {digits})`,
				format.value(expected),
				format.value(value)
			)
		end
		return expectation
	end

	--- Luau string pattern match (not a plain substring — see `toContain`).
	function expectation.toMatch (pattern: string): any
		if type(value) ~= 'string' then
			fail(`expect(...).toMatch requires a string, got {format.value(value)}`)
		end
		-- Argument-side validation: a non-string pattern would otherwise surface
		-- as a raw `string.match` error instead of a clear assertion.
		if type(pattern) ~= 'string' then
			fail(`expect(...).toMatch requires a string pattern, got {format.value(pattern)}`)
		end
		if string.match(value :: string, pattern) == nil then
			fail(
				`expected {format.value(value)} to match pattern {format.value(pattern)}`,
				format.value(pattern),
				format.value(value)
			)
		end
		return expectation
	end

	--- The expected value must be a function; it is called protected. With a
	--- string argument, the thrown error's message must contain it (plain
	--- substring, not a pattern).
	function expectation.toThrow (substring: string?): any
		if type(value) ~= 'function' then
			fail(`expect(...).toThrow requires a function, got {format.value(value)}`)
		end
		-- Argument-side validation: a non-string substring would otherwise
		-- surface as a raw `string.find` error instead of a clear assertion.
		if substring ~= nil and type(substring) ~= 'string' then
			fail(`expect(...).toThrow requires a string substring (or nothing), got {format.value(substring)}`)
		end
		local ok, err = pcall(value)
		if ok then
			fail('expected function to throw, but it did not')
		end
		if substring ~= nil then
			local message = errorMessage(err)
			if string.find(message, substring, 1, true) == nil then
				-- The received side is the raw message, not `format.value` of
				-- it: quoting-and-escaping a real error (which usually opens
				-- with a `path:line:` position) buried the comparison under
				-- doubled backslashes. The expected side stays quoted — it is
				-- a user-supplied substring whose exact boundaries matter.
				fail(`expected error message to contain {format.value(substring)}`, format.value(substring), message)
			end
		end
		return expectation
	end

	function expectation.toNotThrow (): any
		if type(value) ~= 'function' then
			fail(`expect(...).toNotThrow requires a function, got {format.value(value)}`)
		end
		local ok, err = pcall(value)
		if not ok then
			fail(`expected function to not throw, but it threw: {errorMessage(err)}`)
		end
		return expectation
	end

	--- Serializes the value and emits a `snapshot` event; the host (the CLI)
	--- owns the stored file and decides pass/fail, so this never compares or
	--- prints. `received` is `format.snapshot(value)` — a lossless, sorted-key
	--- string with no depth cap, identical across every backend. A value that
	--- cannot serialize deterministically (a cycle, or a non-scalar table key)
	--- fails the assertion instead of degrading the snapshot. The key is the
	--- describe path and test name joined with ` > `, plus a per-test 1-based
	--- counter so multiple calls in one test stay distinct; an explicit `hint`
	--- replaces that counter suffix.
	function expectation.toMatchSnapshot (hint: string?): any
		local current = context.current()
		if current == nil then
			fail('expect(...).toMatchSnapshot can only be called while a test is running')
			return expectation
		end
		-- Serialize before touching the counter, so a rejected value does not
		-- shift the keys of later snapshots in the same test.
		local received, problem = format.snapshot(value)
		if received == nil then
			fail(`expect(...).toMatchSnapshot: {problem}`)
			return expectation
		end
		local ctx = current :: context.TestContext
		ctx.count += 1
		local segments = table.clone(ctx.path)
		table.insert(segments, ctx.name)
		local key = table.concat(segments, ' > ') .. ' ' .. (hint or tostring(ctx.count))
		ctx.emit({
			kind = 'snapshot',
			path = ctx.path,
			name = ctx.name,
			key = key,
			received = received,
		})
		return expectation
	end

	return expectation
end

return expect
