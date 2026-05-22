---
title: Introduction
description: Introduction to the library.
---

# Installation
You can download Bolt through either wally or the .rbxm in the [latest release](https://github.com/unityjaeger/Bolt/releases/latest)
```
bolt = "unityjaeger/bolt@0.3.3"
```

# Features
Dynamic/Static AABB tree for broad phase culling, with support for shape, AABB, ray, and shapecast queries.

Fully cross-supported primitive shapes: boxes, spheres, capsules and rays each have special-cased implementations for every pairing (box-box, box-sphere, box-ray, sphere-sphere, etc.).

Raycasts and shapecasts as well as intersection tests through GJK, with support for boxes, spheres, capsules, cylinders, wedges, corner wedges and convex meshes.

Collision information through MPR, for all shapes that GJK also supports.

# Example Use Cases
- Custom character controller using collide and slide
- Swept melee hitboxes using capsules
- Quickly finding all entities inside of a certain region through the AABB tree
- ...and more

# Conventions
All casting functions expect the ray direction to already be scaled by the cast length.

All GJK functions and the MPR `intersects` function take in an `in_tolerance` value, this describes the minimum distance between two objects before they count as colliding. Typically you want this small, unless you are working with really large objects. For most operations a sensible value can be anywhere between `1e-3` and `1e-4`. However if you are using a function that returns information like a hit normal and you need the normal to be accurate, then use a smaller tolerance, usually `1e-5` to `1e-6` are good.