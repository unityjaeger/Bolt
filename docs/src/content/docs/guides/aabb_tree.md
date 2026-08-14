---
title: AABB Tree
description: AABB Tree Explanation
---

# What is an AABB Tree?
An AABB Tree (also known as a Bounding Volume Hierarchy) is a tree structure on a set of geometric objects. All these objects are wrapped in an axis-aligned bounding box as the leaf ndoes of the tree. These nodes are then grouped as small sets based on some split strategy and enclosed within other, larger bounding boxes in a recursive fashion, eventually resulting in a tree structure with a single bounding box at the top of the tree.

This tree structure helps massively in collision candidate selection, as whole subtrees which encase many smaller bounding boxes can be skipped efficiently if the bounding box of the subtree does not intersect the query region. 

In Bolt, each object in the tree is identified by a numeric identifier that you own and manage.

## Dynamic AABB Trees
Dynamic AABB trees expand on this idea by having a padded aabb for a object, when a object then moves, the tree only needs to be readjusted when the object is no longer within the padded bounding box, saving a lot of performance for dynamic scenes.

```luau
local tree = bolt.aabb_tree.new(config: Config): DynamicTree
```

Config:
| Field | Type | Description |
|---|---|---|
| aabb_padding | number | Extra padding added to every every side of the AABB.

### Inserting and removing objects
```luau
tree:insert(id: number, cf: CFrame, shape: Shape)
```
Inserts a object into the tree, `id` is your own identifier.

The AABB of the leaf node is computed from the `cf` and `shape`, then expanded by the configured `aabb_padding`

```luau
tree:remove(id: number)
```
Removes the object associated with this `id` from the tree.

### Updating objects
```luau
tree:move(id: number, cf: CFrame)
```
Updates the position and orientation of a object, use this whenever the object moves in any way.

It's fine to call this every frame as it will not trigger a reinsertion if the object is still within the bounds of the padded AABB.

```luau
tree:resize(id: number, shape: Shape)
```
Updates the actual shape information, use this when the shape information changes in any way. On a dynamic tree, the replacement AABB retains the configured `aabb_padding`.

### Querying
The `query_aabb`, `query_shape`, `query_ray` and `query_shapecast` functions return an array of `id`'s whose AABB overlap the query volume. These are only candidates. You still need to run a narrow phase check against each candidate to make sure they really are intersecting. The `_closest` and `_any` variants documented below resolve the answer during the traversal instead, and hand you a result rather than a list.

```luau
tree:query_aabb(min: Vector3, max: Vector3): {number}
```
Returns all `id`'s whose AABB overlaps the AABB defined by `min` and `max`.

```luau
tree:query_shape(cf: CFrame, shape: Shape): {number}
```
Returns all `id`'s whose AABB overlaps the AABB constructed from `cf` and `shape`.

```luau
tree:query_aabb_any(min: Vector3, max: Vector3, callback: (id: number) -> boolean): boolean
```
```luau
tree:query_shape_any(cf: CFrame, shape: Shape, callback: (id: number) -> boolean): boolean
```
Returns `true` as soon as `callback` accepts a candidate, `false` if none do.

Use these when you only need to know *whether* something overlaps, not what. Nothing is collected, and the traversal stops at the first accepted candidate, so neither the rest of the tree nor the remaining candidates cost anything. `callback` is your narrow phase and returns `true` for a real hit.

```luau
local blocked = tree:query_shape_any(cf, shape, function(id)
    local obj = objects[id]
    return bolt.gjk.intersects(cf, shape, obj.cf, obj.shape, 1e-4)
end)
```

```luau
tree:query_ray(ray_origin: Vector3, ray_direction: Vector3): {number}
```
Returns all `id`'s whose AABB is hit by the finite segment from `ray_origin` to `ray_origin + ray_direction`.

```luau
tree:query_ray_closest(
    ray_origin: Vector3,
    ray_direction: Vector3,
    narrow_phase: (id: number, max_fraction: number) -> number?,
    max_fraction: number?
): (number?, number?)
```
Returns the single closest hit along the segment, as `(id, fraction)`, or `nil` if nothing was hit.

This is the one query that does not hand you a candidate list. It walks the tree front to back and calls `narrow_phase` on each leaf it reaches, which lets it skip entire subtrees that begin further away than the closest hit found so far. `query_ray` cannot do this, because it has to return every candidate the segment touches whether or not something closer was already found.

`narrow_phase` receives the candidate's `id` and the closest fraction found so far, and returns the hit as a fraction of `ray_direction` (`0` is at `ray_origin`, `1` is at `ray_origin + ray_direction`), or `nil` for a miss. If your narrow phase gives you a distance, divide it by the length of `ray_direction`. `max_fraction` is there so you can cut your own work short, anything you return beyond it is discarded regardless.

Pruning only ever skips subtrees that cannot contain a closer hit, so you get the same answer a full scan would give. Hits at the very end of the segment count, and exact ties are broken arbitrarily.

`max_fraction` defaults to `1`, the whole segment. Passing a smaller value caps the search: anything the ray reaches later is pruned before its narrow phase runs. Use it to carry a hit you already found elsewhere into this query, so several trees (or several queries against one tree) narrow the search together instead of each starting over:

```luau
local best_id, best_fraction = nil, 1
for _, tree in trees do
    local id, fraction = tree:query_ray_closest(origin, direction, narrow_phase, best_fraction)
    if id then
        best_id, best_fraction = id, fraction
    end
end
```

```luau
local id, fraction = tree:query_ray_closest(origin, direction, function(id)
    local obj = objects[id]
    local _, distance = bolt.dispatch.gjk.raycast(origin, direction, obj.cf, obj.shape, 1e-4)
    return if distance then distance / vector.magnitude(direction :: any) else nil
end)
```

:::tip
Prefer this over `query_ray` whenever you only care about the first thing hit. The number of candidates along a ray grows with how far it travels through the scene, so a `query_ray` closest hit loop gets steadily more expensive as the tree grows, while this stays close to `O(log n)`.
:::

```luau
tree:query_shapecast(shape: Shape, origin: CFrame, direction: Vector3): {number}
```
Returns all `id`'s whose AABB is hit while sweeping the shape's world AABB through `direction`. The sweep starts at the actual center of the AABB computed from `shape` and `origin`, which is not necessarily `origin.Position`.

```luau
tree:query_shapecast_closest(
    shape: Shape,
    origin: CFrame,
    direction: Vector3,
    narrow_phase: (id: number, max_fraction: number) -> number?,
    max_fraction: number?
): (number?, number?)
```
The sweeping counterpart to `query_ray_closest`: returns the single closest hit as `(id, fraction)`, or `nil` if nothing was hit.

It behaves exactly like `query_ray_closest`: front to back traversal, `narrow_phase` called only on leaves it actually reaches, subtrees that begin beyond the closest hit skipped, and the same optional `max_fraction` cap, with the sweep volume in place of the ray. `narrow_phase` returns the hit as a fraction of `direction`, or `nil` for a miss, and the result is the same one a full scan of `query_shapecast` would produce.

```luau
local id, fraction = tree:query_shapecast_closest(shape, cf, direction, function(id)
    local obj = objects[id]
    local hit, distance = bolt.dispatch.gjk.shapecast_simple(cf, direction, shape, obj.cf, obj.shape, 1e-4)
    return if hit and distance then distance / vector.magnitude(direction :: any) else nil
end)
```

Ray and shapecast queries include candidates touched at the segment endpoint. With a zero direction they act as point or stationary-AABB queries. A ray parallel to an AABB boundary is included when its origin lies on that boundary.

Shape bounds account for rotated ellipsoids. Hull bounds use the supplied transform and the hull's component-wise scale, so transformed and non-uniformly scaled hulls can be inserted and queried correctly.

:::tip
If you want to generalize the narrow phase check after a query, you can look at the `type` field stored in the shape table. To figure out the collision function thats needed, look at [shape_map](https://github.com/unityjaeger/Bolt/blob/main/src/shape_map.luau) for the mapping. If you are using GJK or MPR, its even easier as both already work on generalized shapes.
:::

### Rebuilds
Tree quality may degrade as you keep moving/inserting/removing objects in the tree, however this is not an issue for the majority of games or use cases.

If you see query performance getting worse and worse as time goes on, you might need to rebuild the tree ever so often.

```luau
tree:should_rebuild() -> boolean
```
This method lets you know if the tree quality has degraded enough to be worth rebuilding, you can check this periodically (like every 10 seconds).

```luau
tree:partial_rebuild() -> number
```
```luau
tree:full_rebuild() -> number
```
These methods are for rebuilding the tree, full_rebuild fully tears down the tree and reconstructs it while partial_rebuild reuses good branches to perform less work.

On an empty tree, `full_rebuild()` and `partial_rebuild()` return `0`, and `should_rebuild()` returns `false`.

For a dynamic tree you want to be using partial_rebuild mainly.

## Static AABB Trees
For geometry that never moves, Bolt provides a static variant built using binned SAH, which produces high quality trees at the cost of being slower to fully rebuild. 

Because of this it should only be built once.

```luau
bolt.aabb_tree.new_static() -> StaticTree
```
There is no configuration for static trees as they don't need padding.

The API is the same as the dynamic tree except:
- Only insert and remove are available, no move or resize
- You must call full_rebuild once after you are done inserting/removing objects
- should_rebuild and partial_rebuild are not available

A static tree is a good fit for things like level geometry or any set of objects that is fixed for the lifetime of the game.

## Usage Example
```luau
-- setup
local tree = bolt.aabb_tree.new({ aabb_padding = 1 })

-- register objects (once, or when they are created)
for id, obj in objects do
    tree:insert(id, obj.cf, obj.shape)
end

-- every frame, update moved objects
for id, obj in objects do
    tree:move(id, obj.cf)
end

-- broad + narrow phase query
local candidates = tree:query_aabb(query_min, query_max)
for _, id in candidates do
    local obj = objects[id]
    if bolt.collision.box_box(query_cf, query_shape, obj.cf, obj.shape) then
        -- confirmed hit
    end
end
```