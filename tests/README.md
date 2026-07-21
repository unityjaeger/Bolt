# Studio test suite

The tests are deterministic and require no place assets.

1. Serve `test.project.json` with Rojo.
2. Connect an empty Studio place to the project.
3. Start the server with **Run** or **Play**.

`ServerScriptService.BoltTestRunner` loads Bolt and every module under
`ReplicatedStorage.BoltTests.specs`. Results are printed to the Studio output,
and the runner throws after all cases finish if any test failed.

Randomized differential tests use fixed seeds. A failure message includes the
seed and iteration needed to reproduce the generated case.
