---
title: Shapes
description: Shape Explanation
---

Bolt operates on shapes, the shape table holds information like radius for spheres, or half extents for boxes.

There are functions for every supported shape, as well as a function for getting the shape table from a Part.

```luau
bolt.create_from_part(part: Part): Shape
```

`create_from_part` accepts ordinary `Part` instances. `MeshPart`, `UnionOperation`, `WedgePart`, and `CornerWedgePart` instances are rejected. A `Part` whose `Shape` property is `Enum.PartType.Wedge` or `Enum.PartType.CornerWedge` is supported.

```luau
bolt.create_box(size: Vector3): BoxShape
```
```luau
bolt.create_sphere(radius: number): SphereShape
```
```luau
bolt.create_ellipsoid(size: Vector3): EllipsoidShape
```
```luau
bolt.create_capsule(radius: number, height: number): CapsuleShape
```
```luau
bolt.create_cylinder(radius: number, height: number): CylinderShape
```
```luau
bolt.create_wedge(size: Vector3): WedgeShape
```
```luau
bolt.create_corner_wedge(size: Vector3): CornerWedgeShape
```
```luau
bolt.create_mesh(mesh_info: {hulls: {Hull}, size: Vector3}, size: Vector3): MeshShape
```

```luau
bolt.create_hull(hull_info: {vertices: {Vector3}, adjacency: {{number}}, size: Vector3}, size: Vector3): HullShape
```
A single convex hull, usable anywhere a primitive is. `hull_info` mirrors what a mesh's hulls carry, minus the offset: a mesh positions its hulls relative to the mesh origin, while a standalone hull is placed entirely by the `CFrame` you query it with. Its `offset` is always zero.

The second argument scales it the same way mesh size does, component wise against `hull_info.size`.

`vertices` must be the vertices of a convex shape, and `adjacency[i]` must list the vertices sharing an edge with vertex `i`. The support function hill-climbs that graph, so an adjacency graph that does not connect the real hull edges can stop at a vertex that is not the true support point, which shows up as silently wrong collisions rather than an error. A fully connected graph (every vertex listing every other) is always safe if you are unsure.

Mesh size applies component wise, non-uniform scaling to hull vertices and hull offsets.

```luau
bolt.resize_mesh(mesh: MeshShape, size: Vector3)
```
A resize method is specifically only needed for meshes and hulls as there is more work needed than a single value change. `resize_mesh` updates every hull's scale and rebuilds the mesh's local AABB tree with the scaled hull offsets.

```luau
bolt.resize_hull(hull: HullShape, size: Vector3)
```
Updates a standalone hull's scale. A hull has no local tree to rebuild, so this only touches the scale, but it exists so hulls resize through the same call shape as meshes rather than by writing `scale` yourself.

:::note
Resizing does not update any AABB tree the shape is registered in. Call `tree:resize(id, shape)` afterwards, exactly as you would for a mesh.
:::

:::note
Capsules and cylinders both use the same alignment as cylinders in roblox, so cframe.RightVector is the axis, while size.X is the height and size.Y/2 is the radius.
:::

## Margins
Every shape has an optional `margin`, which inflates it by that distance in all directions, as if it were swept by a sphere of that radius.

```luau
local shape = bolt.create_box(Vector3.new(4, 4, 4))
shape.margin = 0.05
```

Nothing else changes: every query treats the inflated surface as the real one. Casts stop `margin` earlier, intersection tests report contact `margin` sooner, MPR includes it in the reported depth, and AABB trees widen their bounds to match. Shapes without a margin behave exactly as before.

:::caution
A tree reads a shape's size when the shape is inserted or resized, never afterwards, so changing a margin on a shape already registered in one leaves its bounds behind. Call `tree:resize(id, shape)` after the change, the same as you would after resizing any shape. A static tree has no `resize`, so remove the proxy, insert it again and rebuild.
:::

This is the supported way to keep clearance around a moving shape. Shrinking a shape by hand to leave room only works for a few types, a capsule inset by a constant is still a capsule but a hull is not, whereas a margin works on every shape including hulls, where no field could express it.

Because it is a true Minkowski sum, an inflated shape has rounded edges and corners, not enlarged flat ones. A box with a margin is a box with rounded edges, which is usually what you want for a collision skin.

A margin on a mesh applies to all of its hulls, and the mesh's own tree widens with them. Both happen on the first query after the margin changes, not when you assign it, so the cost lands on a query rather than on the write.

That widening only ever grows. Lowering a margin narrows what the queries report straight away, but the tree keeps the wider bounds, which costs a rejected candidate rather than a wrong answer. `resize_mesh` rebuilds the bounds from the hulls and takes that extra bit of margin back out, so a mesh whose margin drops a long way and stays there can be resized to its current size to tighten it again.

:::caution
A margin must be nonnegative. A negative value is ignored at every stage rather than shrinking the shape, so the shape behaves as if it had no margin at all instead of failing in some position dependent way.

Inflation is a Minkowski sum and is exact for every convex shape. Deflation is not its mirror image, and the reason it is not worth offering is that it would only ever be exact where it is unnecessary. Subtracting from a sphere or a capsule works because you are subtracting from a radius the shape already has, but that is the case a smaller `create_sphere` or `create_capsule` already covers. A shape with edges has no radius to subtract, so its surface does not move inward uniformly, and those are exactly the shapes no constructor argument could express.

Build the shape smaller when you need it smaller.
:::

Shapecasts otherwise use the exact supplied shape geometry.