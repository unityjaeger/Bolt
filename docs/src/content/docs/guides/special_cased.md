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

This simply tells you if these two objects are intersecting or not.

The remaining functions that have been special-cased are `box_sphere`, `box_capsule`, `sphere_sphere`, `sphere_capsule` and `capsule_capsule`.

# Raycasting
All special-cased raycasting functions have the same parameters and return values, the return values being the hit point, distance, hit normal and a boolean that indicates whether or not the ray started inside of the object.

When the ray starts inside of the object, the normal will point inwards instead of outwards, while the hit point and distance are still what you would expect: A point and the distance to this point on the surface of the object.

One example for a special-cased raycast function is
```luau
bolt.raycast.box(
    ray_origin: Vector3,
    ray_direction: Vector3,
    box_cf: CFrame,
    box_shape: BoxShape
): (Vector3?, number?, Vector3?, boolean?)
```

If the hit point is `nil`, all other return values will also be `nil`.

The other two functions are: `sphere` and `capsule`.