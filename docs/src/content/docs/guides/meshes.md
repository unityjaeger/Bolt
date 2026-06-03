---
title: Meshes
description: Introduction to Meshes.
---

MPR and GJK only work with convevx shapes, so to work with arbitrary meshes need to be decomposed into convex hulls. So a mesh will end up consisting of multiple convex hulls that approximate the original shape while also being much more performant than if one were to use the raw geometry of the mesh.

Meshes are supported through this [Plugin](https://create.roblox.com/store/asset/114210433179837/Collision-Hulls)

This plugin will allow you to select a MeshPart or UnionOperation and export its convex decomposition exactly as roblox computes it.

After being exported, the exported mesh information will appear under `ReplicatedStorage.Collisions`. It also automatically generates the module that is necessary to decompress the information as it is stored in base64.

Heres an example of a mesh shape being created this way:
```luau
local parser = require(game.ReplicatedStorage.Collisions.CollisionParser)

local hull_data = parser.Decode("ExampleMesh")

local mesh_shape = bolt.create_mesh(hull_data, Vector3.new(5, 5, 5))
```
The second argument is the mesh size.

Meshes have to be interacted with differently as they are not a single shape that can be easily worked with under the hood, but rather a set of convex hulls.

# GJK
All already known GJK operations are possible against meshes.

If you are working with meshes, you have to go through `bolt.dispatch.gjk`.

Its also important to note that warm starting for mesh functions is not possible, as you would have to warm start against each hull and the overhead of doing so is not worth it.

All of the GJK functions will work no matter what shapes the input shapes are. The return values will also mean the same thing.

## Intersection
```luau
bolt.dispatch.gjk.intersects(
	cframe_a: CFrame, 
	shape_a: Shape, 
	cframe_b: CFrame, 
	shape_b: Shape, 
	in_tolerance: number
): boolean
```

## Casting
All casting functions will behave the same, they will choose the hull with the smallest distance until there are no more hulls to check.

### Raycast
```luau
bolt.dispatch.gjk.raycast(
	ray_origin: Vector3,
	ray_direction: Vector3,
	cframe: CFrame,
	shape: Shape,
	in_tolerance: number
): (Vector3?, number?, Vector3?)
```

### Shapecasting
```luau
bolt.dispatch.gjk.shapecast_simple(
	cframe_a: CFrame,
	direction: Vector3,
	shape_a: Shape,
	cframe_b: CFrame,
	shape_b: Shape,
	in_tolerance: number
): (boolean, number?)
```
```luau
bolt.dispatch.gjk.shapecast(
	cframe_a: CFrame,
	direction: Vector3,
	shape_a: Shape,
	cframe_b: CFrame,
	shape_b: Shape,
	in_tolerance: number
): (Vector3?, number?, Vector3?)
```

It is naturally possible to do mesh vs mesh raycasting or mesh vs mesh intersections would i would advise against this as it has to check every hull of `a` against every candidate hull of `b`, which can get expensive.

# MPR
MPR works a bit differently from the rest, as you generally don't want to run the same logic for mesh vs primitive and mesh vs mesh. So it's split into exactly these two functions:
```luau
bolt.dispatch.mpr.mesh_primitive(
	cframe_a: CFrame, 
	shape_a: Shape, 
	cframe_b: CFrame, 
	shape_b: Shape, 
	in_tolerance: number
): {{
    normal: Vector3,
    depth: number,
    point_a: Vector3,
    point_b: Vector3,
    hull_a_id: number?,
    hull_b_id: number?
}}
```
Compared to GJK, MPR will return all hulls that were intersected for further processing by the user. If `shape_a` was a mesh then `hull_b_id` will not be `nil` and if `shape_b` was a mesh then `hull_a_id` will not be `nil`.

```luau
bolt.dispatch.mpr.mesh_mesh(
    cframe_a: CFrame, 
	shape_a: Shape,
	cframe_b: CFrame, 
	shape_b: Shape, 
	in_tolerance: number
): {{
    normal: Vector3,
    depth: number,
    point_a: Vector3,
    point_b: Vector3,
    hull_a_id: number,
    hull_b_id: number
}}
```
Since both are meshes, both `hull_a_id` and `hull_b_id` will never be `nil`.

# Important Notes
It is currently not possible to calculate a contact manifold for clipping, etc. because the exported mesh information only includes vertices and adjacency for vertices.

It is much harder to get a reliable depenetration vector when working with meshes composed of convex hulls, requiring an iterative approach.