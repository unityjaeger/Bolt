# Bolt

Collision library for simple intersection tests, does not deliver contact information for collisions. (will be expanded later)

## Features
Fully cross-supported primitive shapes: boxes, spheres, capsules and rays each have special-cased implementations for every pairing (box-box, box-sphere, box-ray, sphere-sphere, etc.).

For unsupported shape combinations, GJK (ported from [Jolt](https://github.com/jrouwe/JoltPhysics)) covers all other combinations, with native support functions for boxes, spheres, capsules, cylinders, wedges, corner wedges and convex meshes.

GJK also offers raycasting as well as shapecasting, although there are some pitfalls to watch out for that will be mentioned where relevant.

## Getting Started
The library functions all operate on a cframe (for consistency) and a shape table for a given object, the shape table holds information like radius for spheres, half extents for boxes, etc.

There are functions for every supported shape, as well as a function for getting the shape table from a BasePart.
> [!IMPORTANT]
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
bolt.create_corner_wedge(size: Vector3): CornerWedgeShape
```
```lua
bolt.create_mesh(part: MeshPart): MeshShape
```

## Conventions
All cast functions expect direction to be a non-unit vector with the length baked in.

All cast functions detect collisions when the cast starts inside of the object it is checking against.
Checking for these is different for the special-cased ray functions and the GJK cast function, more info about that can be found in the corresponding sections.

All GJK functions expect inputs to be in object space, see each section to see how to calculate this.

All GJK functions have an in_tolerance parameter, this describes the minimum distance between the two shapes before they count as colliding.
Typically you want to keep this small, unless you are working with really large objects, for most applications a value like 0.001 is good.

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
All combinations not covered by the above special-cased functions will have to be done through GJK.

```lua
bolt.gjk.intersects(transform_b_in_a: CFrame, shape_a: types.Shape, shape_b: types.Shape, in_tolerance: number): boolean
```

> [!NOTE]
> transform_b_in_a can be calculated with:
> ```lua
> local transform_b_in_a = cf_a:ToObjectSpace(cf_b)
> ```

## Raycasting
For all cast functions, The first return value is the hit point, the second return value is the distance and third return value is the normal.

### special-cased
The fourth return value dictates whether or not the hit comes from inside the shape itself.

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
Shapes not supported above will have to be done through GJK.

```lua
bolt.gjk.raycast(ray_origin: Vector3, ray_direction: Vector3, in_tolerance: number, shape: Shape): (Vector3?, number?, Vector3?)
```

The raycasting function for GJK functions a bit different from the special-cased one when it comes to rays that start inside of the shape.

When the ray starts inside of the shape, the distance will be 0, the normal will have a length of 0 and the hit point will be the ray origin itself, so if you want to check if a ray started inside of a shape, just check if the distance is equal to 0.

> [!Note]
> ray_origin and ray_direction can be calculated with:
> ```lua
> ray_origin = shape_cf:PointToObjectSpace(ray_origin)
> ray_direction = shape_cf:VectorToObjectSpace(ray_direction)
> ```

## Shapecasting
Shapecasting is only supported through GJK, there are 2 functions for shapecasting.

> [!NOTE]
> start and direction can be calculated with:
> ```lua
> --assuming start is the cframe of shape_a
> start = cframe_b:ToObjectSpace(start)
> direction = cframe_b:VectorToObjectSpace(direction)
> ```

```lua
bolt.gjk.shapecast_simple(start: CFrame, direction: Vector3, in_tolerance: number, shape_a: Shape, shape_b: Shape): (boolean, number?)
```

This function should be used if you don't need the hit point and normal.

The first return value indicates whether or not a hit occured, while the second return value is the distance.

```lua
bolt.gjk.shapecast(start: CFrame, direction: Vector3, in_tolerance: number, convex_radius_a: number, shape_a: Shape, convex_radius_b: number, shape_b: Shape): (Vector3?, number?, Vector3?)
```

For both functions, when the distance is 0, the shapes started out already overlapping.
For shapecast specifically, when the distance is 0, the nromal will haev an unuseable directon that you should ignore, and the hit point will be a point inside of shape_a.

convex_radius_a and convex_radius_b are used to pad shape_a and shape_b, this leads to improved numerical robustness and performance, however the larger the convex radii the larger the rounding on the shape, which is mostly noticable around corners and edges.

A sensible default for the convex radii would depend on the size of the shape, but something like 0.05 works well in practice.

> [!CAUTION]
> The normal around edges/corners can be different from what you would expect (e.g. not orthogonal to a box face) due to the convex radii, even with a summed convex radius of 0, this will still happen because of the way GJK works.

## Dynamic AABB Tree
soon
