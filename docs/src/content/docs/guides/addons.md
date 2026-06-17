---
title: Debug Addon
description: Debug Addon Explanation
---

Bolt includes a simple wireframe visualizer addon for debugging collision queries. It can be used to visualize shapes, rays, arrows, and the results of collision functions.

The visualizer is immediate-mode: it clears itself every frame, so anything you want to keep visible must be drawn again every frame.

By default, the addon assumes that `bolt` is located under `ReplicatedStorage`. If your project uses a different location, update the `require` path at the top of the visualizer module.

## Components
The visualizer exposes shape components for each Bolt shape.

```luau
visualizer.components.box(cframe: CFrame, shape: bolt.BoxShape)
visualizer.components.sphere(cframe: CFrame, shape: bolt.SphereShape)
visualizer.components.cylinder(cframe: CFrame, shape: bolt.CylinderShape)
visualizer.components.capsule(cframe: CFrame, shape: bolt.CapsuleShape)
visualizer.components.ellipsoid(cframe: CFrame, shape: bolt.EllipsoidShape)
visualizer.components.wedge(cframe: CFrame, shape: bolt.WedgeShape)
visualizer.components.corner_wedge(cframe: CFrame, shape: bolt.CornerWedgeShape)
```

There are also utility components for rays and arrows:
```luau
visualizer.components.ray(from: Vector3, to: Vector3)
```
```luau
visualizer.components.arrow(from: Vector3, to: Vector3, head_length: number, head_radius: number)
```

For generic shape drawing, use:
```luau
visualizer.draw_component(cframe: CFrame, shape: bolt.Shape)
```
This automatically selects the right component for a shape.

## Intersections

There are three visualizers for intersections: one for GJK and special-cased functions, one for SAT, and one for MPR.

All intersection visualizers draw `shape_a` green when an intersection occurs and red when no intersection occurs.

For GJK and special-cased collisions, use:
```luau
visualizer.primitive_primitive(
    cframe_a: CFrame,
    shape_a: bolt.Shape,
    cframe_b: CFrame,
    shape_b: bolt.Shape,
    hit: boolean
)
```

For SAT use:
```luau
visualizer.sat_intersects(
    cframe_a: CFrame,
    shape_a: bolt.Shape,
    cframe_b: CFrame,
    shape_b: bolt.Shape,
    hit: boolean,
    mtv: Vector3?,
    depth: number?
)
```

This will additionally draw an arrow from `shape_b` towards `shape_a` based on `mtv` multiplied by `depth` when an intersection occurs.

For MPR use:
```luau
visualizer.mpr_intersects(
    cframe_a: CFrame,
    shape_a: bolt.Shape,
    cframe_b: CFrame,
    shape_b: bolt.Shape,
    hit: boolean,
    mtv: Vector3,
    depth: number?,
    point_a: Vector3?,
    point_b: Vector3?
)
```

It will behave the same as SAT, but also draw `point_a` and `point_b`.

:::note
`point_a` and `point_b` may coincide and be the same point depending on the shape.
:::

## Raycasting

Both GJK and the special-cased ray functions use the same ray visualizer.

```luau
visualizer.raycast_primitive(
    ray_origin: Vector3, 
    ray_direction: Vector3,
    cframe: CFrame,
    shape: bolt.Shape,
    point: Vector3?,
    distance: number?,
    normal: Vector3?
)
```

If no hit occurred, this draws a red ray from `ray_origin` to `ray_origin + ray_direction`. If a hit occurred, this draws a green ray from `ray_origin` to `ray_origin + ray_direction.Unit * distance`.

On a successful hit, the hit point and normal will also be drawn.

## Shapecasting

There is a visualizer for both shapecast methods.

```luau
visualizer.gjk_shapecast_simple(
    cframe_a: CFrame,
    direction: Vector3,
    shape_a: bolt.Shape,
    cframe_b: CFrame,
    shape_b: bolt.Shape,
    hit: boolean,
    distance: number?
)
```

This draws `shape_a` at the start pose and again at the cast endpoint. If the cast hits, the endpoint shape is drawn at the hit distance and colored green. If the cast misses, it is drawn at the full cast distance and colored red.

A ray will also be drawn between these two shapes, mirroring how raycast works.

```luau
visualizer.gjk_shapecast(
    cframe_a: CFrame,
    direction: Vector3,
    shape_a: bolt.Shape,
    cframe_b: CFrame,
    shape_b: bolt.Shape,
    point: Vector3?,
    distance: number?,
    normal: Vector3?
)
```

This works the same as `gjk_shapecast_simple`, except that it will also draw the hit point and normal if the cast was successful.

## Styling
You can influence the color, thickness and transparency of the next drawn element by calling:
```luau
visualizer.next_color(color: Color3)
visualizer.next_transparency(transparency: number)
visualizer.next_thickness(thickness: number)
```

This affects only the visualizer call that directly follows.

Example:
```luau
visualizer.next_color(Color3.new(1, 0, 0))
visualizer.next_thickness(3)
visualizer.components.box(cframe, shape)

--back to default color and thickness
visualizer.components.box(cframe + Vector3.new(0, 5, 0), shape)
```

:::note
`visualizer.next_color`, `visualizer.next_transparency`, and `visualizer.next_thickness` only affect basic components. Higher-level visualizers define their own colors for the elements they draw.
:::

## Limitations
- Mesh visualization of any kind is not supported