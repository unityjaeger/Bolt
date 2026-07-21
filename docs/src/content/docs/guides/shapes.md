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

Shapecasts use the exact supplied shape geometry. Shapes do not receive convex radius padding.

Mesh size applies component-wise, non-uniform scaling to hull vertices and hull offsets.

```luau
bolt.resize_mesh(mesh: MeshShape, size: Vector3)
```
A resize method is specifically only needed for meshes as there is more work needed than a single value change for meshes. `resize_mesh` updates every hull's scale and rebuilds the mesh's local AABB tree with the scaled hull offsets.

:::note
Capsules and cylinders both use the same alignment as cylinders in roblox, so cframe.RightVector is the axis, while size.X is the height and size.Y/2 is the radius.
:::