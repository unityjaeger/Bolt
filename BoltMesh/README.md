# BoltMesh

A Roblox Studio plugin that exports the convex hulls the engine collides a `MeshPart` or `UnionOperation` with, in the form `bolt.create_mesh` requires.

## How it works

The engine has no API that hands out collision geometry, but it serializes it:
a part's `PhysicalConfigData` shared string in the output of
`SerializationService:SerializeInstancesAsync` is a CSGPHS blob holding the
hulls, exactly what the engine collides the part with. This blob always seems to
be a version 8 blob, even on very old assets, which is the only supported reader format.

An export appears under `ReplicatedStorage.Collisions.Hulls.<PartName>` as a
Folder of Base64 StringValue chunks (at most 100,000 characters each) holding
one zstd frame of the packed hulls, with the lengths and a Blake3 digest as
attributes. The fidelity used is the part's `CollisionFidelity`.

At runtime:

```luau
local parser = require(game.ReplicatedStorage.Collisions.CollisionParser)

local hull_data = parser.decode("ExampleMesh")
local mesh = bolt.create_mesh(hull_data, part.Size)
```

The hulls are expressed at the size the part had when it was exported, and
`create_mesh` scales them. The preview draws the same thing in the
part's own space and redraws it through CFrame and Size changes.

## Building

Iris comes from wally, the plugin is assembled by rojo:

```console
wally install
rojo build default.project.json -o BoltMesh.rbxm
```

Put `BoltMesh.rbxm` in your Studio plugins folder.

## Tests

The specs run in Studio through [Lest](https://github.com/lest-luau/lest) as part
of the Bolt repo's suite, in the same Studio launch as the library's own specs.
From the repo root:

```console
rojo build test-place.project.json -o test-place.rbxl
lest                    # everything
lest -t 'collision'     # only these specs
```