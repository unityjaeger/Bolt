---
title: GJK
description: GJK Explanation
---

# What is GJK?
The Gilbert-Johnson-Keerthi distance algorithm is a method of determining the minimum distance between two convex sets. It does not require that the geometry data is stored in any specific format, and instead relies only on a support function. This makes it great for generalized collision detection because as long as you have a support function for a given convex object, you can run GJK on it.

The final simplex that GJK spits out, even on misses can be used as an initial guess for the next GJK call, as long as the positions in the next call are close to the positions of the previous frame. This will typically make it converge in only one or two iterations.

# Intersections
For simple intersections, use
```luau
bolt.gjk.intersects(
    cframe_a: CFrame,
    shape_a: Shape,
    cframe_b: CFrame,
    shape_b: Shape,
    in_tolerance: number,
    io_v: Vector3?
): (boolean, Vector3)
```
`io_v` is the initial guess as explained above, if not defined it will default to `Vector3.zero`.

The second return value of this function is the separating vector, which can be fed into the algorithm in the next call as the initial guess.

Exact touching counts as an intersection.

# Casts
Both shapecasting and raycasting are possible with GJK. Cast directions are finite displacement vectors, not infinite rays. Tangent contacts and contacts at the endpoint are included.

If a cast starts touching or overlapping its target, its distance is `0`. Cast functions that return a normal return `Vector3.zero` for every such `t == 0` hit, that normal must not be used.

A zero-motion cast hits when the initial shapes are considered touching or overlapping under the supplied tolerance and misses otherwise.

To raycast, use
```luau
bolt.gjk.raycast(
    ray_origin: Vector3,
    ray_direction: Vector3,
    cframe: CFrame,
    shape: Shape,
    in_tolerance: number
): (Vector3?, number?, Vector3?)
```
The return values in order are hit point, distance and hit normal. The distance is measured in world-space units along the cast, not returned as a fraction of `ray_direction`.

If the hit point is `nil`, then the other two return values will also be `nil`.

There are two ways to shapecast, `shapecast_simple` will only tell you if the cast has hit and the distance
```luau
bolt.gjk.shapecast_simple(
    cframe_a: CFrame,
    direction: Vector3,
    shape_a: Shape,
    cframe_b: CFrame,
    shape_b: Shape,
    in_tolerance: number
): (boolean, number?)
```

While regular `shapecast` will give you the hit point, distance and hit normal in that order.
```luau
bolt.gjk.shapecast(
    cframe_a: CFrame,
    direction: Vector3,
    shape_a: Shape,
    cframe_b: CFrame,
    shape_b: Shape,
    in_tolerance: number
): (Vector3?, number?, Vector3?)
```
For the return values, the same properties as with raycast return values apply.

`shapecast_simple` and `shapecast` use identical, exact shape geometry without convex radius padding. They should agree on hit status and world-space hit distance within numerical precision.

:::caution
The hit normal that `shapecast` returns will not necessarily be perpendicular to the face that the shapecast hit, this mostly happens around vertices and edges.
:::