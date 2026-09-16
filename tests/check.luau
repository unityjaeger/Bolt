--!strict

local Lest = require('@lest')
local expect = Lest.expect

local DEFAULT_EPSILON = 1e-5

--the epsilon assertions fail by comparing two descriptive strings rather than by asserting on a
--bare boolean, so the report says what the difference actually was instead of "expected true"
local function fail_comparison(message: string?, got: string, wanted: string)
	local prefix = if message ~= nil then `{message}: ` else ''
	expect(`{prefix}{got}`).toBe(`{prefix}{wanted}`)
end

local function equal(actual: any, expected: any, message: string?)
	expect(actual).toBe(expected)
end

local function same(actual: any, expected: any, message: string?)
	--rawequal in the old framework, which for every value the suite compares is what toBe does
	expect(actual).toBe(expected)
end

local function truthy(actual: any, message: string?)
	expect(actual).toBeTruthy()
end

local function falsy(actual: any, message: string?)
	expect(actual).toBeFalsy()
end

local function is_nil(actual: any, message: string?)
	expect(actual).toBeNil()
end

--returns the value so callers can keep writing check.near(check.non_nil(distance), ...)
local function non_nil<T>(actual: T?, message: string?): T
	expect(actual).toNotBeNil()
	return actual :: T
end

--inclusive, and NaN always fails, matching the framework this replaced
local function near(actual: number, expected: number, epsilon: number?, message: string?)
	local tolerance = epsilon or DEFAULT_EPSILON
	local difference = math.abs(actual - expected)

	if difference <= tolerance then
		return
	end

	fail_comparison(
		message,
		`{actual} differs from {expected} by {difference}`,
		`a difference of at most {tolerance}`
	)
end

local function vector_near(actual: Vector3, expected: Vector3, epsilon: number?, message: string?)
	local tolerance = epsilon or DEFAULT_EPSILON
	local delta = actual - expected
	local difference = math.sqrt(vector.dot(delta :: any, delta :: any))

	if difference <= tolerance then
		return
	end

	fail_comparison(
		message,
		`{actual} differs from {expected} by {difference}`,
		`a difference of at most {tolerance}`
	)
end

--naming the failure keeps the report readable: "Expected: finite, Received: NaN"
local function describe_number(actual: number): string
	if actual ~= actual then
		return 'NaN'
	elseif actual == math.huge then
		return 'infinity'
	elseif actual == -math.huge then
		return '-infinity'
	end
	return 'finite'
end

local function finite(actual: number, message: string?)
	local state = describe_number(actual)
	if state == 'finite' then
		return
	end

	fail_comparison(message, `{state} ({actual})`, 'finite')
end

local function vector_finite(actual: Vector3, message: string?)
	for _, axis in {actual.X, actual.Y, actual.Z} do
		local state = describe_number(axis)
		if state ~= 'finite' then
			fail_comparison(message, `{state} component in {actual}`, 'a finite vector')
			return
		end
	end
end

local function contains<T>(actual: {T}, expected: T, message: string?)
	expect(actual).toContain(expected :: any)
end

local function not_contains<T>(actual: {T}, expected: T, message: string?)
	for _, value in actual do
		if value == expected then
			fail_comparison(message, `an array containing {expected}`, `no {expected}`)
			return
		end
	end
end

--order independent equality over arrays of comparable values, which for this suite is always arrays of ids
local function set_equal<T>(actual: {T}, expected: {T}, message: string?)
	local sorted_actual = table.clone(actual)
	local sorted_expected = table.clone(expected)

	table.sort(sorted_actual :: any)
	table.sort(sorted_expected :: any)

	expect(sorted_actual).toEqual(sorted_expected)
end

local function cframe_near(actual: CFrame, expected: CFrame, epsilon: number?, message: string?)
	local tolerance = epsilon or DEFAULT_EPSILON

	if actual:FuzzyEq(expected, tolerance) then
		return
	end

	fail_comparison(message, `{actual}`, `within {tolerance} of {expected}`)
end

local function errors(callback: () -> any, expected_message: string?, message: string?)
	if expected_message ~= nil then
		expect(callback).toThrow(expected_message)
	else
		expect(callback).toThrow()
	end
end

return {
	equal = equal,
	same = same,
	truthy = truthy,
	falsy = falsy,
	is_nil = is_nil,
	["nil"] = is_nil,
	non_nil = non_nil,
	near = near,
	vector_near = vector_near,
	finite = finite,
	vector_finite = vector_finite,
	contains = contains,
	not_contains = not_contains,
	set_equal = set_equal,
	cframe_near = cframe_near,
	errors = errors,
}