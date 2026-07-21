---
title: MPR
description: MPR Explanation
---

# What is MPR?
Minkowski Portal Refinement is comparable to GJK, as it also relies on support functions and also is designed for convex objects. Unlike GJK however, MPR does not provide the shortest distance between separated objects. However in return MPR can be used to extract collision information from an intersection, namely a hit point, the penetration depth and the minimum translation vector: A normal that when scaled by the penetration depth can be used to depenetrate two intersecting objects.

In Bolt specifically, MPR performs both an intersection test and the collision information extraction.

MPR is great for objects that don't have flat faces with multiple contact points, it can handle the remaining shape pairs that SAT doesn't cover just fine.

# Usage
As MPR does not provide the shortest distance, only intersection tests can be done with MPR.
```luau
bolt.mpr.intersects(
    cframe_a: CFrame,
    shape_a: Shape,
    cframe_b: CFrame,
    shape_b: Shape,
    in_tolerance: number
): (boolean, Vector3, number?, Vector3?, Vector3?)
```

This function returns, in order, whether an intersection occurred, the minimum-translation direction, penetration depth, the contact point on shape A, and the contact point on shape B. The normal points from shape B toward shape A, so moving shape A by `normal * depth` separates the pair. `point_a` and `point_b` always correspond to the function arguments with the same suffix.

Swapping shapes A and B flips the normal and swaps `point_a` with `point_b`, subject to normal floating-point differences. Exact touching is a hit with a depth of `0` and a `Vector3.zero` normal, that normal must not be used.

`in_tolerance` is a world-space distance with a minimum effective value of `1e-6`. Inputs below `1e-6` are raised to that minimum.

The minimum translation vector will always be returned, and it can be used to quickly check if the two objects are still separated to dramatically speed up intersection tests in cases where objects generally don't move a lot inbetween calls.

MPR will not give you a contact manifold, you will have to implement clipping yourself if you need one.

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

`is_separated` returns `false` when the shapes are touching. Pass a usable separating normal from an earlier result, the zero normal returned for a touching contact is not suitable as `cached_normal`.