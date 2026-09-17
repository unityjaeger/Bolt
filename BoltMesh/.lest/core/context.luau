--!strict
--- Per-test context shared between the runner and the matchers that emit
--- protocol events (currently just `toMatchSnapshot`). The runner sets it
--- around each executing test body; matchers read it. Kept in its own module
--- so `expect` stays a pure function of the value under test.
---
--- The framework never prints — a snapshot matcher reports a *fact* (the
--- serialized value) through this emitter and the host decides pass/fail.

local context = {}

export type TestContext = {
	--- The emitter supplied to `Lest.run`; snapshot events flow through it.
	emit: (event: { [string]: any }) -> (),
	--- Describe nesting of the running test, for the event `path` and key.
	path: { string },
	--- The running test's name, for the event `name` and key.
	name: string,
	--- Per-test 1-based counter so repeated `toMatchSnapshot()` calls in one
	--- test derive distinct keys.
	count: number,
}

local active: TestContext? = nil

--- Opens the context for a test the runner is about to execute.
function context.begin (emit: (event: { [string]: any }) -> (), path: { string }, name: string)
	active = { emit = emit, path = path, name = name, count = 0 }
end

--- Closes the context once the test (and its each-hooks) have finished.
function context.clear ()
	active = nil
end

--- The context for the running test, or nil when no test is executing.
function context.current (): TestContext?
	return active
end

--- Reinstates a previously captured context (or clears it, when nil). Nested
--- runs — `Lest.capture` from inside a running test — clear the context once per
--- inner test, which would otherwise leave the *enclosing* test contextless and
--- make any later `toMatchSnapshot` fail as if no test were running. Restoring
--- the same table keeps that test's snapshot counter intact.
function context.restore (saved: TestContext?)
	active = saved
end

return context
