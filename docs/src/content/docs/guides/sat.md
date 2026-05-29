---
title: SAT
description: SAT Explanation
---

# What is SAT?
The seperating axis theorem states that if you can draw a single line (an axis) that seperates two objects so their projections do not overlap, then the objects are not colliding.

This algorithm is mainly used when the objects have a low number of faces, as it requires a bunch of extra effort and processing power to support objects which aren't composed flat planes.

It provides very accurate collision information for the shapes it supports, so SAT should be used when possible.

Bolt supports boxes, wedges and corner wedges through SAT.

# Usage
Similar to the special-cased functions, the parameters and return values are always the same for the SAT functions.
```luau
box_box(
    cframe_a: CFrame,
    shape_a: BoxShape,
    cframe_b: CFrame,
    shape_b: BoxShape
): (boolean, Vector3?, number?)
```

SAT will not give you an intersection point, if you need the contact manifold for physics simulation you will have to implement clipping yourself.

The first return value indicates whether or not an intersection has occured, the second return value is the minimum translation vector and the third return value is the penetration depth.

The rest of the SAT functions are `box_wedge`, `wedge_wedge`, `wedge_corner_wedge`, `box_corner_wedge`, `corner_wedge_corner_wedge`. 