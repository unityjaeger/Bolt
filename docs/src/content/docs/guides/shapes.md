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

Shapecasts use the exact supplied shape geometry. Shapes do not receive convex radius padding.

Mesh size applies component-wise, non-uniform scaling to hull vertices and hull offsets.

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