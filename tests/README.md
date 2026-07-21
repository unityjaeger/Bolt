# Studio test suite

The tests are deterministic and require no place assets.

To run the tests, download 'tests/bolt_tests.rbxm' and run it like so:
```luau
local replicated_storage = game:GetService("ReplicatedStorage")

local bolt = require(replicated_storage.bolt)
local tests = require(replicated_storage.bolt_tests)

tests.run(bolt)
```