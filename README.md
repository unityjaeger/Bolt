# Bolt

Collision library for simple intersection tests, does not deliver contact information for collisions.

## Features
Fully cross-supported primitive shapes: boxes, spheres, capsules and rays each have special-cased implementations for every pairing (box-box, box-sphere, box-ray, sphere-sphere, etc.).

For unsupported shape combinations, GJK (ported from [Jolt](https://github.com/jrouwe/JoltPhysics)) covers all other combinations, with native support functions for boxes, spheres, capsules, cylinders, wedges, corner wedges and convex meshes.

GJK also offers raycasting as well as shapecasting, although there are some pitfalls to watch out for that will be mentioned where relevant.

## Getting Started
The library functions all operate on a cframe (for consistency) and a shape table for a given object, the shape table holds information like radius for spheres, half extents for boxes, etc.

There are functions for every supported shape, as well as a function for getting the shape table from a BasePart.
> [!WARNING]
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
### special-cased
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
bolt.collision.capsule_capsule(capsule_a_cf: CFrame, capsule_a_shape: CapsuleShape, capsule_b_cf: CFrame, capsule_b_shape: CapsuleShape): boolean
```

### GJK
All combinations not covered by the above special-cased functions will have to be done through gjk.

```lua
bolt.gjk.intersects(transform_b_in_a: CFrame, shape_a: types.Shape, shape_b: types.Shape, in_tolerance: number): boolean
```

The gjk collision function does not follow the same scheme as the special-cased collision functions, this is because the support function works in object space for higher performance.

Additionally we have in_tolerance, which is the minimum distance between the two objects before they count as colliding, typically this is a small number, something like 0.01, but if accuraccy doesn't matter as much you can increase it for higher performance.

> [!IMPORTANT]
> transform_b_in_a can be calculated like so:
> ```lua
> local transform_b_in_a = cf_a:Inverse() * cf_b
> ```

## Raycasting
### special-cased
The first return value is the hit point, the second return value is the distance, the third return value is the hit normal, and the fourth return value dictates whether or not the hit comes from inside the shape itself.

When the hit comes from inside the shape, the normal will point inwards.

```lua
bolt.raycast.box(ray_origin: Vector3, ray_direction: Vector3, box_cf: CFrame, box_shape: BoxShape): (Vector3?, number?, Vector3?, boolean?)
```
```lua
bolt.raycast.sphere(ray_origin: Vector3, ray_direction: Vector3, sphere_cf: CFrame, sphere_shape: SphereShape): (Vector3?, number?, Vector3?, boolean?)
```
```lua
bolt.raycast.capsule(ray_origin: Vector3, ray_direction: Vector3, capsule_cf: CFrame, capsule_shape: CapsuleShape): (Vector3?, number?, Vector3?, boolean?)
```

### GJK
Shapes not supported above will have to be done through gjk.

```lua
bolt.gjk.raycast(ray_origin: Vector3, ray_direction: Vector3, tolerance: number, shape: Shape): (Vector3?, number?, Vector3?)
```

The raycasting function for gjk functions a bit different from the special-cased one when it comes to rays that start inside of the shape.

When the ray starts inside of the shape, the distance will be 0, the hit normal will have a length of 0 and the hit point will be the ray origin itself, so if you want to check if a ray started inside of a shape, just check if the distance is equal to 0.

> [!Important]
> ray_origin and ray_direction also need to be in the object space of whatever you are casting against, so they are calculated like so:
> ```lua
> ray_origin = shape_cf:PointToObjectSpace(ray_origin)
> ray_direction = shape_cf:VectorToOjbectSpace(ray_direction)
> ```

## Shapecasting
Shapecasting is only supported through gjk, there are 2 functions for shapecasting, one does not deliver any hit information and runs faster.

```lua
bolt.gjk.shapecast_simple(start: CFrame, direction: Vector3, tolerance: number, shape_a: Shape, shape_b: Shape): (boolean, number?)
```
The second return value is the distance.

If the distance is 0, the shapecast started with the 2 shapes already overlapping.

```lua
bolt.gjk.shapecast(start: CFrame, direction: Vector3, tolerance: number, convex_radius_a: number, shape_a: Shape, convex_radius_b: number, shape_b: Shape): (Vector3?, number?, Vector3?)
```
> [!IMPORTANT]
> start and direction need to be in the object space of shape_b, you can calculate them like so:
> ```lua
> --assuming start is the cframe of shape_a
> start = cframe_b:ToObjectSpace(start)
> direction = cframe_b:VectorToObjectSpace(direction)
> ```

convex_radius_a and convex_radius_b are used to pad shape_a and shape_b, this leads to improved numerical robustness and performance, however the larger the convex radii the larger the rounding on the shape, which is mostly noticable around corners and edges.

A sensible default for the convex radii would depend on the size of the shape, but something like 0.05 works well in practice.

Once again, if the distance is 0, the shapecast started with the 2 shapes already overlapping, in this case the normal will have a garbage direction that you should ignore, and the hit point will be a point inside of shape_a.

> [!CAUTION]
> The normal around edges/corners can be different from what you would expect (e.g. not orthonogonal to a box face) due to the convex radii, even with a summed convex radius of 0, this will still happen because of the way gjk works.
