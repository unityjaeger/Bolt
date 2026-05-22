---
title: MPR
description: MPR Explanation
---

# What is MPR?
Minkowski Portal Refinement is comparable to GJK, as it also relies on support functions and also is designed for convex objects. Unlike GJK however, MPR does not provide the shortest distance between separated objects. However in return MPR can be used to extract collision information from an intersection, namely a hit point, the penetration depth and the minimum translation vector: A normal that when scaled by the penetration depth can be used to depenetrate two intersecting objects.

In Bolt specifically, MPR performs both an intersection test and the collision information extraction. This process is faster than checking with GJK in cases where intersections happen relatively frequently compared to misses.

# Usage
As MPR does not provide the shortest distance, only intersection tests can be done with MPR.
```luau
bolt.mpr.intersects(
    cframe_a: CFrame,
    shape_a: Shape,
    cframe_b: CFrame,
    shape_b: Shape,
    in_tolerance: number
): (boolean, Vector3, number?, Vector3?)
```

This function will give you a boolean to indicate whether or not an intersection has happened, the minimum translation vector, penetration depth and intersection point in that order.

The minimum translation vector will always be returned, and it can be used to quickly check if the two objects are still separated to dramatically speed up intersection tests in cases where objects generally dont move a lot inbetween calls.

The function to use for this check is
```luau
bolt.mpr.is_separated(
    cframe_a: CFrame,
    shape_a: Shape,
    cframe_b: CFrame,
    shape_b: Shape,
    cached_normal: Vector3 --previously returned MTV
): boolean
```