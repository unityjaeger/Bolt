# Test suite

The specs run under [Lest](https://github.com/lest-luau/lest) on the studio backend.

## Running

Build the test place once (and again whenever `src` changes):

```console
rojo build test-place.project.json -o test-place.rbxl
```

Then:

```console
lest                      # the whole suite
lest -t 'margin'          # only tests whose full name contains "margin"
```

`lest.toml` points the studio backend at `test-place.rbxl` and maps `src` into
`ReplicatedStorage.bolt` through `test-place.project.json`.

## Layout

| Path | What it is |
| --- | --- |
| `tests/specs/*.spec.luau` | The specs, one file per subsystem |
| `tests/check.luau` | Domain assertions on top of `expect` |
| `tests/helpers.luau` | Shared fixtures and cast assertions |

## Assertions

`tests/check.luau` carries `near`, `vector_near`, `set_equal`, `cframe_near` and similar, built on Lest's `expect`.
It exists because Lest's `toBeCloseTo` takes a precision exponent instead, which cannot express a
tolerance like `5e-3`, and compares with a strict `<` where these compare inclusively.

Everything else uses Lest's matchers directly.