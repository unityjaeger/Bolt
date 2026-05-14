# Bolt

## Features
Fully cross-supported primitive shapes: boxes, spheres, capsules and rays each have special-cased implementations for every pairing (box-box, box-sphere, box-ray, sphere-sphere, etc.).

For unsupported shape combinations, GJK (ported from [Jolt](https://github.com/jrouwe/JoltPhysics)) covers all other combinations, with native support functions for boxes, spheres, capsules, cylinders, wedges, corner wedges and convex meshes.

GJK also offers raycasting as well as shapecasting, although there are some caveats in regards to the returned cast information that will be mentioned later.

## Getting Started
The library functions all operate on a cframe (for consistency) and a shape table for a given object, the shape table holds information like radius for spheres, half extents for boxes, etc.

There are functions for every supported shape, as well as a function for getting the shape table from a BasePart.
> [!NOTE]
> capsules and cylinders in bolt use the same alignment as cylinders in roblox, so cframe.RightVector is the axis, while size.X is the height and size.Y/2 is the radius
```lua
bolt.create_from_part(part: BasePart): Shape
```
```lua
bolt.create_box(size: Vector3): BoxShape
```
```lua
bolt.create_sphere(radius: number): SphereShape
```
```lua
bolt.create_capsule(radius: number, height: number): CapsuleShape
```
```lua
bolt.create_cylinder(radius: number, height: number): CylinderShape
```
```lua
bolt.create_wedge(size: Vector3): WedgeShape
```
```lua
bolt.create_corner_wedge(size: Vector): CornerWedgeShape
```
```lua
bolt.create_mesh(part: MeshPart): MeshShape
```

## Collision Functions
special-cased:
```lua
bolt.collision.box_box(box_a_cf: CFrame, box_a_shape: BoxShape, box_b_cf: CFrame, box_b_Shape: BoxShape): boolean
```
```lua
bolt.collision.box_sphere(box_cf: CFrame, box_shape: BoxShape, sphere_cf: CFrame, sphere_shape: SphereShape): boolean
```
```lua
bolt.collision.box_capsule(box_cf: CFrame, box_shape: BoxShape, capsule_cf: CFrame, capsule_shape: CapsuleShape): boolean
```
```lua
bolt.collision.sphere_sphere(sphere_a_cf: CFrame, sphere_a_shape: SphereShape, sphere_b_cf: CFrame, sphere_b_shape: SphereShape): boolean
```
```lua
bolt.collision.sphere_capsule(sphere_cf: CFrame, sphere_shape: SphereShape, capsule_cf: CFrame, capsule_shape: CapsuleShape): boolean
```
```lua
bolt.collision.capsule_capsule(capsule_a_cf: CFrame, capsule_a_shape: SphereShape, capsule_b_cf: CFrame, capsule_b_shape: CapsuleShape): boolean
```

gjk:
```lua
bolt.gjk.intersects(transform_b_in_a: CFrame, shape_a: types.Shape, shape_b: types.Shape, in_tolerance: number, io_v: Vector3): (boolean, Vector3)
```

## Raycasting/Shapecasting
special-cased:

first return value: hit point

second return value: distance

third return value: normal

fourth return value: inside or not
```lua
bolt.raycast.box(ray_origin: Vector3, ray_direction: Vector3, box_cf: CFrame, box_shape: BoxShape): (Vector3?, number?, Vector3?, boolean?)
```
```lua
bolt.raycast.sphere(ray_origin: Vector3, ray_direction: Vector3, sphere_cf: CFrame, sphere_shape: SphereShape): (Vector3?, number?, Vector3?, boolean?)
```
```lua
bolt.raycast.capsule(ray_origin: Vector3, ray_direction: Vector3, capsule_cf: CFrame, capsule_shape: CapsuleShape): (Vector3?, number?, Vector3?, boolean?)
```

gjk:
placeholder
