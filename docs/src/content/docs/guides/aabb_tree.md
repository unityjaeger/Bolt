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
Updates the actual shape information, use this when the shape information changes in any way.

### Querying
All query functions return an array of `id`'s whose AABB overlap the query volume. These are only candidates. You still need to run a narrow phase check against each candidate to make sure they really are intersecting.

```luau
tree:query_aabb(min: Vector3, max: Vector3): {number}
```
Returns all `id`'s whose AABB overlaps the AABB defined by `min` and `max`.

```luau
tree:query_shape(cf: CFrame, shape: Shape): {number}
```
Returns all `id`'s whose AABB overlaps the AABB constructed from `cf` and `shape`.

```luau
tree:query_ray(ray_origin: Vector3, ray_direction: Vector3): {number}
```
Returns all `id`'s whose AABB is hit by the ray.

```luau
tree:query_shapecast(start: CFrame, direction: Vector3, shape: Shape): {number}
```
Returns all `id`'s whose AABB is hit by the shapecast.

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