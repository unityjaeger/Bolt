---
title: Shapes
description: Shape Explanation
---

Bolt operates on shapes, the shape table holds information like radius for spheres, or half extents for boxes.

There are functions for every supported shape, as well as a function for getting the shape table from a BasePart.

```luau
bolt.create_from_part(part: BasePart, convex_radius: number?): Shape
```
```luau
bolt.create_box(size: Vector3, convex_radius: number?): BoxShape
```
```luau
bolt.create_sphere(radius: number, convex_radius: number?): SphereShape
```
```luau
bolt.create_ellipsoid(size: Vector3, convex_radius: number?): EllipsoidShape
```
```luau
bolt.create_capsule(radius: number, height: number, convex_radius: number?): CapsuleShape
```
```luau
bolt.create_cylinder(radius: number, height: number, convex_radius: number?): CylinderShape
```
```luau
bolt.create_wedge(size: Vector3, convex_radius: number?): WedgeShape
```
```luau
bolt.create_corner_wedge(size: Vector3, convex_radius: number?): CornerWedgeShape
```
```luau
bolt.create_mesh(mesh_info: {hulls: {Hull}, size: Vector3}, size: Vector3, convex_radius: number?): MeshShape
```

The convex radius optional parameter is only used for GJK shapecasts, it's used to pad the two objects by a slight margin (that is removed from the resulting return values) for improved numerical robustness. The default value is `0.05`, and it should ideally be based on the scale of the object, as this padding will be noticeable on the vertices and edges of the object for shapecasts. Sticking with a small value (like the default) is generally a good idea though.

```luau
bolt.resize_mesh(mesh: MeshShape, size: Vector3)
```
A resize method is specifically only needed for meshes as there is more work needed than a single value change for meshes.

:::note
Capsules and cylinders both use the same alignment as cylinders in roblox, so cframe.RightVector is the axis, while size.X is the height and size.Y/2 is the radius.
:::