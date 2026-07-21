---
title: Special-Cased
description: Special-Cased Explanation
---

There are special-cased functions for rays, boxes, spheres and capsules, as these are common shapes that are worth optimizing for.

# Collisions
The special-cased functions all have the same parameters and return value, one example being
```luau
bolt.collision.box_box(
    box_a_cf: CFrame,
    box_a_shape: BoxShape,
    box_b_cf: CFrame,
    box_b_shape: BoxShape
): boolean
```

Touching primitive pairs will return `true`.

The remaining functions that have been special-cased are `box_sphere`, `box_capsule`, `sphere_sphere`, `sphere_capsule` and `capsule_capsule`.

# Raycasting
All special-cased raycasting functions have the same parameters and return values: hit point, world-space distance, and hit normal.

When the ray starts on the surface or inside the object, the hit point is the ray origin, the distance is `0`, and the normal is `Vector3.zero` and must not be used.

The direction describes a finite segment, and a hit at its endpoint is included. A zero-length ray acts as a point query: it hits if its origin is on or inside the shape and misses otherwise.

One example for a special-cased raycast function is
```luau
bolt.raycast.box(
    ray_origin: Vector3,
    ray_direction: Vector3,
    box_cf: CFrame,
    box_shape: BoxShape
): (Vector3?, number?, Vector3?)
```

If the hit point is `nil`, all other return values will also be `nil`.

The other two functions are: `sphere` and `capsule`.