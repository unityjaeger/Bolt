---
title: Introduction
description: Introduction to the library.
---

# Installation
You can download Bolt through either wally or the .rbxm in the [latest release](https://github.com/unityjaeger/Bolt/releases/latest)
```
bolt = "unityjaeger/bolt@0.5.0"
```

# Features
Dynamic/Static AABB tree for broad phase culling, with support for shape, AABB, ray, and shapecast queries.

Fully cross-supported primitive shapes: boxes, spheres, capsules and rays each have special-cased implementations for every pairing (box-box, box-sphere, box-ray, sphere-sphere, etc.).

Raycasts and shapecasts as well as intersection tests through GJK, with support for boxes, spheres, capsules, cylinders, wedges, corner wedges and convex meshes.

Collision information through SAT and MPR, for all shapes that GJK also supports.

Mesh support for all GJK and MPR functions through convex hulls.

# Example Use Cases
- Custom character controller using collide and slide
- Swept melee hitboxes using capsules
- Quickly finding all entities inside of a certain region through the AABB tree
- ...and more

# Conventions
All casting functions expect the ray direction to already be scaled by the cast length.

All GJK functions and the MPR `intersects` function take in an `in_tolerance` value, this describes the minimum distance between two objects before they count as colliding. Typically you want this small, unless you are working with really large objects. For most operations a sensible value can be anywhere between `1e-3` and `1e-4`. For MPR the tolerance is capped to `1e-6` as lower tolerances don't yield any better results, however for the vast majority of use cases you are gonna be fine with a tolerance of `1e-3` or `1e-4`.

There are quite a few things to note with meshes, which will be talked about in the `Meshes` section.