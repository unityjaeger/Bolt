---
title: Meshes
description: Introduction to Meshes.
---

MPR and GJK only work with convex shapes, so arbitrary meshes need to be decomposed into convex hulls. A mesh therefore consists of multiple convex hulls that approximate the original shape while also being much more performant than using its raw geometry.

Meshes are supported through this [Plugin](https://create.roblox.com/store/asset/114210433179837/Collision-Hulls)

The plugin lets you select a `MeshPart` or union and export the convex hulls the engine itself collides it with, at the part's own `CollisionFidelity`. The hulls are read out of the part's own serialized collision data, so they match what the physics engine simulates against.

Before exporting, the plugin can draw the hulls over the selected part. They follow the part through `CFrame` and `Size` changes.

An export appears under `ReplicatedStorage.Collisions.Hulls` as a folder named after the part, holding the hull data as zstd compressed, chunked `StringValue`s. The `CollisionParser` module that reads it back is placed next to it.

Heres an example of a mesh shape being created this way:
```luau
local parser = require(game.ReplicatedStorage.Collisions.CollisionParser)

local hull_data = parser.decode("ExampleMesh")

local mesh_shape = bolt.create_mesh(hull_data, mesh_part.Size)
```
The second argument is the mesh size. The hulls are expressed at the size the part had when it was exported, and `create_mesh` applies component-wise, non-uniform scale to every hull's vertices and offset from there, so passing the part's current size puts them where the engine has them. The mesh `CFrame` then transforms those scaled hulls into world space. Calling `resize_mesh` updates the hull scales and rebuilds the mesh's local AABB tree with the new offsets.

Every decoded hull also carries `triangles`, three 1-based vertex indices per face, flat. `create_mesh` does not need them, but they are what a contact manifold would be clipped against, so they are kept for whoever may need them.

Meshes have to be interacted with differently as they are not a single shape that can be easily worked with under the hood, but rather a set of convex hulls.

## Single hulls
If your geometry is already convex, a mesh is unnecessary overhead: it would carry a local AABB tree and a dispatch path built for choosing between hulls, for one hull. `bolt.create_hull` builds a lone hull instead, which behaves like any other primitive.

```luau
local hull_shape = bolt.create_hull({
    vertices = vertices,
    adjacency = adjacency,
    size = Vector3.new(2, 2, 2),
}, Vector3.new(4, 4, 4))
```
It takes the same `vertices` and `adjacency` a mesh hull carries, but no offset, since a standalone hull is positioned entirely by the `CFrame` you query it with. Unlike a mesh it goes through the ordinary `bolt.gjk` and `bolt.mpr` functions rather than `bolt.dispatch`, and it can be inserted into an AABB tree directly.

Use `bolt.resize_hull(hull, size)` to rescale one.

## Handling the hulls yourself
Nothing stops you from skipping `bolt.dispatch` and walking a mesh's hulls directly. A hull is an ordinary shape, positioned by its offset scaled the same way its vertices are:

```luau
for _, child in composite.children do
    if bolt.gjk.intersects(composite_cf * child.cf, child.shape, other_cf, other_shape, 1e-4) then
        --hit this child
    end
end
```

To cull with the mesh's own tree instead of testing every hull, query it in mesh space:

```luau
local in_composite = composite_cf:ToObjectSpace(other_cf)

for _, child_id in composite.local_tree:query_shape(in_composite, other_shape) do
    local child = composite.children[child_id]
    --...
end
```

What you take on by doing this is the handling a margin needs. A mesh is never handed to GJK or MPR, its hulls are, so `mesh.margin` has to reach them before it means anything, and the tree's bounds have to grow with them or the tree culls hulls whose inflated surface you would still have reached. Dispatch does both, on the first query after the margin changes. Nothing else does.

That leaves three things to watch for:

Setting `mesh.margin` and then only ever working with the hulls yourself does nothing at all. The hulls keep whatever margin they already had, which for a fresh mesh is none.

Setting `hull.margin` on each hull yourself fixes the narrow phase but not `mesh.local_tree`, which was built from unmargined hulls and will cull candidates you expected to reach. `bolt.resize_mesh(mesh, size)` rebuilds those bounds from the hulls as they are now, so passing the mesh's current size is the way to bring them back in line.

Don't mix the two. Dispatch treats `mesh.margin` as the source of truth, so a single dispatched query overwrites every `hull.margin` set by hand with it, silently clearing them if `mesh.margin` is `nil`.

The simple route, if you want both, is to set `mesh.margin` and let one dispatched query sync it before you start working with hulls by hand. After that the hulls and the tree will match, and `mesh.tree_margin` tells you how much of the margin those bounds already include. Bear in mind it only ever grows, as described in the margins section of the Shapes guide.

For a more proper approach, base whatever code you are writing on what is already being done in dispatch.

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

Mesh-mesh intersections and both forms of mesh-mesh shapecast are supported, although they can be expensive because every hull of shape A must be checked against candidate hulls from shape B. Raycasting accepts a ray and one target shape, so "mesh-mesh raycasting" is not a two-shape operation, a mesh can simply be used as the raycast target.

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
    child_a_id: number?,
    child_b_id: number?
}}
```
Compared to GJK, MPR returns all intersected children for further processing. IDs follow argument order: if `shape_a` is the composite, `child_a_id` identifies its child, if `shape_b` is the composite, `child_b_id` identifies its child. The ID for a primitive argument is `nil`.

Normals and contact points also retain function argument order when the mesh is shape A: the normal points from shape B toward shape A, `point_a` belongs to the mesh hull, and `point_b` belongs to the primitive.

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
    child_a_id: number,
    child_b_id: number
}}
```
Since both are meshes, both `child_a_id` and `child_b_id` will never be `nil`.

# Important Notes
Bolt does not currently calculate a contact manifold for clipping, etc. against meshes. The exported hulls carry their triangles, so the face information a manifold needs is there, but nothing in the library does anything with it yet.

It is much harder to get a reliable depenetration vector when working with meshes composed of convex hulls, requiring an iterative approach.