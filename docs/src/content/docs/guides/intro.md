---
title: Introduction
description: Introduction to the library.
---

# Installation
You can download Bolt through either wally or the .rbxm in the [latest release](https://github.com/unityjaeger/Bolt/releases/latest)
```
bolt = "unityjaeger/bolt@0.8.0"
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
Cast directions describe finite displacement segments. A cast starts at its supplied origin or transform and ends after the complete direction vector has been applied.

All casting functions include hits at that endpoint.

All intersection functions count exact touching contacts as collision.

All GJK functions and the MPR `intersects` function take an `in_tolerance` value. Pass a nonnegative world-space distance. GJK uses it as the contact distance, while MPR clamps it to a minimum effective value of `1e-6`. Typically you want this small unless you are working with very large objects. For most operations, a value between `1e-4` and `1e-3` is sensible.

A GJK tolerance of `0` does not disable floating-point convergence handling.

There are quite a few things to note with meshes, which will be talked about in the `Meshes` section.