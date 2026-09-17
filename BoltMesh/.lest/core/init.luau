--!strict
--- Lest core: spec API and runner. Pure Luau, zero dependencies — runs
--- unmodified in the embedded VM, Lune, Lute, and (later) the engine.
---
--- The framework never prints. `run` streams protocol events (plain,
--- JSON-safe tables) to the emitter supplied by whatever host is running it.
--- A module slot for the property engine is reserved post-1.0.

-- `@self` rather than `./` because in an init module `./` refers to the
-- package's parent directory under the require-by-string RFC.
local expect = require('@self/expect')
local context = require('@self/context')

export type Emit = (event: { [string]: any }) -> ()
export type RunOptions = {
	--- Plain-substring filter against the test's full name
	--- (describe path joined with spaces, then the test name).
	nameFilter: string?,
}

-- `scopePath` is the identity of the enclosing describe blocks: one unique id
-- per `describe` *invocation*, so two same-named sibling describes never share
-- hooks or state. `path` stays the human-readable name path used for reporting.
type Test = {
	path: { string },
	scopePath: { number },
	name: string,
	fn: (() -> ())?,
	skip: boolean,
	--- Optional skip reason (`xit` only), carried on the `test_skip` event.
	reason: string?,
}

type HookKind = 'beforeAll' | 'beforeEach' | 'afterEach' | 'afterAll'

type Hook = {
	kind: HookKind,
	path: { string },
	scopePath: { number },
	seq: number,
	fn: () -> (),
}

type Failure = { [string]: any }

local PROTOCOL_VERSION = 1

local registry: { Test } = {}
local hooks: { Hook } = {}
local pathStack: { string } = {}
-- Parallel to `pathStack`: a unique id per live `describe`, pushed on entry.
local scopeStack: { number } = {}
-- Monotonic; never reused within a run, so same-named describes stay distinct.
local nextScopeId = 0
-- Registration order of hooks, used as the stable tie-breaker when sorting
-- each-hooks by nesting depth.
local nextHookSeq = 0
-- Full names (describe path joined with the test name) already registered in
-- this file. Two tests sharing one full name would silently collide on
-- snapshot keys and be indistinguishable to reports and `-t` filtering, so a
-- duplicate is a collection-time error instead.
local registeredFullNames: { [string]: boolean } = {}
-- True while `Lest.run` is executing. The runner snapshots the registry up
-- front but used to scan hooks live, so a `describe`/`it`/hook called mid-run
-- (from inside a test body) either silently vanished or silently attached at
-- root for later tests. Registration APIs now check this flag and raise a hard
-- error instead (Jest parity).
local running = false

local Lest = {}

Lest.protocolVersion = PROTOCOL_VERSION
Lest.expect = expect

local function assertNotRunning (api: string)
	if running then
		error(
			`{api}(...) cannot be called while the run is in progress — register every test and hook before the run starts`,
			0
		)
	end
end

--- Unwraps a caught error for the collection-error message, mirroring
--- `errorMessage` in expect.luau: a structured assertion (or anything else
--- carrying a `message` field) reports its real message rather than the
--- `table: 0x...` that `tostring` would produce.
local function errorText (err: any): string
	if type(err) == 'table' and (err :: any).message ~= nil then
		return tostring((err :: any).message)
	end
	return tostring(err)
end

function Lest.describe (name: string, body: () -> ())
	assertNotRunning('describe')
	nextScopeId += 1
	table.insert(pathStack, name)
	table.insert(scopeStack, nextScopeId)
	local ok, err = pcall(body)
	table.remove(scopeStack)
	table.remove(pathStack)
	if not ok then
		error(`error while collecting describe('{name}'): {errorText(err)}`, 0)
	end
end

local function registerTest (api: string, name: string, fn: (() -> ())?, skip: boolean, reason: string?)
	assertNotRunning(api)
	local path = table.clone(pathStack)
	local full = if #path == 0 then name else table.concat(path, ' ') .. ' ' .. name
	if registeredFullNames[full] then
		error(
			`duplicate test name: '{full}' is already registered in this spec file`
				.. ' — rename one so reports, filters, and snapshot keys can tell them apart',
			0
		)
	end
	registeredFullNames[full] = true
	table.insert(registry, {
		path = path,
		scopePath = table.clone(scopeStack),
		name = name,
		fn = fn,
		skip = skip,
		reason = reason,
	})
end

function Lest.it (name: string, fn: () -> ())
	registerTest('it', name, fn, false, nil)
end

--- Skipped test: registered so it is reported, never executed. An optional
--- `reason` rides on the `test_skip` event for reporters to show.
function Lest.xit (name: string, fn: (() -> ())?, reason: string?)
	registerTest('xit', name, fn, true, reason)
end

local function addHook (kind: HookKind, fn: () -> ())
	assertNotRunning(kind)
	nextHookSeq += 1
	table.insert(hooks, {
		kind = kind,
		path = table.clone(pathStack),
		scopePath = table.clone(scopeStack),
		seq = nextHookSeq,
		fn = fn,
	})
end

--- Runs once before the first test in the enclosing describe block. A failure
--- here fails every test in the block.
function Lest.beforeAll (fn: () -> ())
	addHook('beforeAll', fn)
end

--- Runs before every test in the enclosing describe block, outermost first.
function Lest.beforeEach (fn: () -> ())
	addHook('beforeEach', fn)
end

--- Runs after every test in the enclosing describe block, innermost first.
function Lest.afterEach (fn: () -> ())
	addHook('afterEach', fn)
end

--- Runs once after the last test in the enclosing describe block. Multiple
--- afterAll hooks in one block run in reverse registration order (LIFO
--- teardown, mirroring both setup order and `afterEach`).
function Lest.afterAll (fn: () -> ())
	addHook('afterAll', fn)
end

--- Clears all registered tests and hooks. Hosts call this before loading
--- spec files so repeated runs against a cached module start clean.
function Lest.reset ()
	registry = {}
	hooks = {}
	pathStack = {}
	scopeStack = {}
	nextScopeId = 0
	nextHookSeq = 0
	registeredFullNames = {}
	running = false
end

--- Runs a self-contained suite in isolation: saves the current registration,
--- resets, lets `register` declare a scenario, runs it while collecting every
--- emitted event into an array, then restores the prior registration and
--- returns the events. Lets a host — or lest's own tests — exercise the runner
--- without disturbing an in-progress load.
function Lest.capture (register: () -> (), options: RunOptions?): { { [string]: any } }
	local savedRegistry, savedHooks = registry, hooks
	local savedPathStack, savedScopeStack = pathStack, scopeStack
	local savedScopeId, savedHookSeq = nextScopeId, nextHookSeq
	-- `capture` is how lest's own specs exercise the runner from *inside* a
	-- running test, so the nested registration must not trip the mid-run guard:
	-- the flag is stashed and cleared here, and restored with everything else.
	local savedFullNames, savedRunning = registeredFullNames, running
	-- The nested run clears the snapshot context after each of *its* tests. When
	-- `capture` is called from inside a running test — which is how lest's own
	-- specs use it — that would strand the enclosing test without a context and
	-- break any `toMatchSnapshot` that follows.
	local savedContext = context.current()

	registry = {}
	hooks = {}
	pathStack = {}
	scopeStack = {}
	nextScopeId = 0
	nextHookSeq = 0
	registeredFullNames = {}
	running = false

	local events: { { [string]: any } } = {}
	local ok, err = pcall(function ()
		register()
		Lest.run(function (event)
			table.insert(events, event)
		end, options)
	end)

	registry = savedRegistry
	hooks = savedHooks
	pathStack = savedPathStack
	scopeStack = savedScopeStack
	nextScopeId = savedScopeId
	nextHookSeq = savedHookSeq
	registeredFullNames = savedFullNames
	running = savedRunning
	context.restore(savedContext)

	if not ok then
		error(err, 0)
	end
	return events
end

-- Scope identity is compared on the scope-id path (unique per describe
-- invocation), never the human-readable name path — so two same-named sibling
-- describes are distinct scopes with their own hooks and beforeAll state.
local function sameScope (a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	for i, id in a do
		if b[i] ~= id then
			return false
		end
	end
	return true
end

local function isScopePrefix (prefix: { number }, path: { number }): boolean
	if #prefix > #path then
		return false
	end
	for i, id in prefix do
		if path[i] ~= id then
			return false
		end
	end
	return true
end

local function commonScopePrefixLength (a: { number }, b: { number }): number
	local length = 0
	while length < #a and length < #b and a[length + 1] == b[length + 1] do
		length += 1
	end
	return length
end

local function scopeKey (path: { number }): string
	return table.concat(path, '\0')
end

local function fullName (test: Test): string
	if #test.path == 0 then
		return test.name
	end
	return table.concat(test.path, ' ') .. ' ' .. test.name
end

local function toFailure (err: any): Failure
	if type(err) == 'table' and (err :: any).__lestAssertion == true then
		return {
			type = 'assertion',
			message = (err :: any).message,
			expected = (err :: any).expected,
			received = (err :: any).received,
		}
	end
	return {
		type = 'error',
		message = tostring(err),
		trace = debug.traceback(nil, 2),
	}
end

--- Calls a function, capturing a structured failure inside the error handler
--- because the traceback is only available before the stack unwinds.
local function protectedCall (fn: () -> ()): Failure?
	local failure: Failure? = nil
	local ok = xpcall(fn, function (err)
		failure = toFailure(err)
		return err
	end)
	-- The handler itself can raise — a thrown value with an erroring
	-- `__tostring` blows up inside `toFailure` — leaving `failure` nil for a
	-- call that genuinely failed. Inferring the outcome from `failure` alone
	-- would record that as a *pass*, so trust `ok` and synthesize a failure.
	if not ok and failure == nil then
		failure = {
			type = 'error',
			message = 'the test failed, and its error could not be described (describing it raised too)',
			trace = '',
		}
	end
	return failure
end

--- Executes every registered test, streaming events to `emit`. Returns the
--- pass/fail/skip counts (also emitted as `run_end`).
function Lest.run (emit: Emit, options: RunOptions?): (number, number, number)
	-- From here until `run_end`, registration is frozen: `assertNotRunning`
	-- turns any mid-run `describe`/`it`/hook call into a hard error.
	running = true
	local filter = options and options.nameFilter

	local tests: { Test } = {}
	for _, test in registry do
		if filter == nil or string.find(fullName(test), filter :: string, 1, true) ~= nil then
			table.insert(tests, test)
		end
	end

	-- `specCount` counts the *tests* about to run (after filtering), not spec
	-- files; the name is a wire field kept for compatibility. Hosts synthesize
	-- their own run framing, so nothing consumes it today.
	emit({ kind = 'run_start', specCount = #tests, protocolVersion = PROTOCOL_VERSION })
	local passed, failed, skipped = 0, 0, 0

	-- A scope has an executable descendant if some test with that scope-id
	-- prefix is neither skipped nor bodyless. beforeAll/afterAll fire only for
	-- such scopes, so an all-skipped describe never runs its once-hooks. The
	-- root scope is keyed by the empty string.
	local hasExecutable: { [string]: boolean } = {}
	for _, test in tests do
		if not test.skip and test.fn ~= nil then
			for depth = 0, #test.scopePath do
				local prefix = table.move(test.scopePath, 1, depth, 1, {})
				hasExecutable[scopeKey(prefix)] = true
			end
		end
	end

	-- The describe scopes currently entered, identified by scope id (not name)
	-- so same-named siblings stay distinct. `active` marks a scope whose
	-- once-hooks fire: it has an executable test and no ancestor beforeAll has
	-- already failed. beforeAll fires on entry, afterAll on exit of an active
	-- scope; a beforeAll failure is recorded per scope id and fails every test
	-- underneath it without running them.
	type OpenScope = { id: number, name: string, active: boolean }
	local openScopes: { OpenScope } = {}
	local scopeFailures: { [string]: Failure } = {}

	local function openIds (): { number }
		local ids = {}
		for _, scope in openScopes do
			table.insert(ids, scope.id)
		end
		return ids
	end

	local function openNames (): { string }
		local names = {}
		for _, scope in openScopes do
			table.insert(names, scope.name)
		end
		return names
	end

	local function hooksAt (kind: HookKind, ids: { number }): { Hook }
		local found = {}
		for _, hook in hooks do
			if hook.kind == kind and sameScope(hook.scopePath, ids) then
				table.insert(found, hook)
			end
		end
		return found
	end

	-- True when the root or any proper ancestor of `ids` recorded a beforeAll
	-- failure: descendant once-hooks must then be skipped (their tests are
	-- failed by `findScopeFailure` instead).
	local function ancestorFailed (ids: { number }): boolean
		for depth = 0, #ids - 1 do
			local prefix = table.move(ids, 1, depth, 1, {})
			if scopeFailures[scopeKey(prefix)] ~= nil then
				return true
			end
		end
		return false
	end

	local function closeScopesDownTo (depth: number)
		while #openScopes > depth do
			local scope = openScopes[#openScopes]
			if scope.active then
				-- Reverse registration order: teardown is LIFO within a scope,
				-- mirroring setup order and matching `afterEach`.
				local found = hooksAt('afterAll', openIds())
				for index = #found, 1, -1 do
					local hook = found[index]
					local failure = protectedCall(hook.fn)
					if failure ~= nil then
						failed += 1
						emit({
							kind = 'test_fail',
							path = openNames(),
							name = '(afterAll)',
							durationMs = 0,
							failure = failure,
							origin = 'afterAll',
						})
					end
				end
			end
			table.remove(openScopes)
		end
	end

	local function openScopesFor (test: Test)
		while #openScopes < #test.scopePath do
			local index = #openScopes + 1
			table.insert(openScopes, { id = test.scopePath[index], name = test.path[index], active = false })
			local ids = openIds()
			emit({ kind = 'suite_start', path = openNames() })
			-- Report the scope regardless, but only run its beforeAll when it
			-- has executable tests (fix: all-skipped scopes) and no ancestor
			-- beforeAll has failed (fix: child beforeAll after ancestor fail).
			local active = hasExecutable[scopeKey(ids)] == true and not ancestorFailed(ids)
			openScopes[#openScopes].active = active
			if active then
				for _, hook in hooksAt('beforeAll', ids) do
					local failure = protectedCall(hook.fn)
					if failure ~= nil then
						scopeFailures[scopeKey(ids)] = failure
						break
					end
				end
			end
		end
	end

	local function findScopeFailure (scopePath: { number }): Failure?
		-- The root scope first (its key is the empty string), then every
		-- describe prefix from the outside in.
		local rootFailure = scopeFailures['']
		if rootFailure ~= nil then
			return rootFailure
		end
		for depth = 1, #scopePath do
			local prefix = table.move(scopePath, 1, depth, 1, {})
			local failure = scopeFailures[scopeKey(prefix)]
			if failure ~= nil then
				return failure
			end
		end
		return nil
	end

	-- Each-hooks are ordered by nesting depth, not registration order, so a
	-- `beforeEach` declared after a nested `describe` still runs outermost
	-- first. beforeEach: shallow-to-deep; afterEach: deep-to-shallow. Ties at
	-- the same depth keep registration order (`seq`), reversed for afterEach.
	local function eachHooks (kind: HookKind, scopePath: { number }): { Hook }
		local found = {}
		for _, hook in hooks do
			if hook.kind == kind and isScopePrefix(hook.scopePath, scopePath) then
				table.insert(found, hook)
			end
		end
		local ascending = kind == 'beforeEach'
		table.sort(found, function (a: Hook, b: Hook): boolean
			if #a.scopePath ~= #b.scopePath then
				if ascending then
					return #a.scopePath < #b.scopePath
				end
				return #a.scopePath > #b.scopePath
			end
			if ascending then
				return a.seq < b.seq
			end
			return a.seq > b.seq
		end)
		return found
	end

	-- Top-level hooks (registered outside any describe) wrap the whole run;
	-- they belong to the root scope, which named-scope entry never visits.
	if #tests > 0 and hasExecutable[''] == true then
		for _, hook in hooksAt('beforeAll', {}) do
			local failure = protectedCall(hook.fn)
			if failure ~= nil then
				scopeFailures[''] = failure
				break
			end
		end
	end

	for _, test in tests do
		closeScopesDownTo(commonScopePrefixLength(openIds(), test.scopePath))
		openScopesFor(test)

		emit({ kind = 'test_start', path = test.path, name = test.name })

		if test.skip or test.fn == nil then
			skipped += 1
			-- `reason` is nil unless `xit` was given one; a nil field simply
			-- stays off the wire (`test_skip.reason` is optional).
			emit({ kind = 'test_skip', path = test.path, name = test.name, reason = test.reason })
			continue
		end

		local scopeFailure = findScopeFailure(test.scopePath)
		if scopeFailure ~= nil then
			failed += 1
			emit({
				kind = 'test_fail',
				path = test.path,
				name = test.name,
				durationMs = 0,
				failure = scopeFailure,
				origin = 'beforeAll',
			})
			continue
		end

		local started = os.clock()
		local failure: Failure? = nil
		-- The hook a failure came from, carried on the event as `origin` so a
		-- reporter can say "setup broke" — a reader otherwise has to notice
		-- that the failing line sits outside the test body. Stays nil (off
		-- the wire) when the test body itself failed.
		local failedIn: string? = nil

		-- Snapshot matchers reach the emitter and this test's identity through
		-- the shared context for the duration of the test and its each-hooks.
		context.begin(emit, test.path, test.name)

		-- beforeEach outermost-first; the first failure aborts the chain and
		-- the test body.
		for _, hook in eachHooks('beforeEach', test.scopePath) do
			failure = protectedCall(hook.fn)
			if failure ~= nil then
				failedIn = 'beforeEach'
				break
			end
		end

		if failure == nil then
			failure = protectedCall(test.fn :: () -> ())
		end

		-- afterEach always runs, innermost-first; its failure only surfaces
		-- when the test itself passed.
		for _, hook in eachHooks('afterEach', test.scopePath) do
			local afterFailure = protectedCall(hook.fn)
			if failure == nil and afterFailure ~= nil then
				failure = afterFailure
				failedIn = 'afterEach'
			end
		end

		context.clear()

		local durationMs = (os.clock() - started) * 1000

		if failure == nil then
			passed += 1
			emit({
				kind = 'test_pass',
				path = test.path,
				name = test.name,
				durationMs = durationMs,
			})
		else
			failed += 1
			emit({
				kind = 'test_fail',
				path = test.path,
				name = test.name,
				durationMs = durationMs,
				failure = failure,
				origin = failedIn,
			})
		end
	end

	closeScopesDownTo(0)

	if #tests > 0 and hasExecutable[''] == true then
		-- Reverse registration order, exactly as in `closeScopesDownTo`: LIFO
		-- teardown within a scope, the root scope included.
		local rootAfterAll = hooksAt('afterAll', {})
		for index = #rootAfterAll, 1, -1 do
			local hook = rootAfterAll[index]
			local failure = protectedCall(hook.fn)
			if failure ~= nil then
				failed += 1
				emit({
					kind = 'test_fail',
					path = {},
					name = '(afterAll)',
					durationMs = 0,
					failure = failure,
					origin = 'afterAll',
				})
			end
		end
	end

	running = false
	emit({ kind = 'run_end', passed = passed, failed = failed, skipped = skipped })
	return passed, failed, skipped
end

return Lest
