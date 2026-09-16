---
title: Temporal Tree Addon
description: Broad phase over where objects have been.
---

:::note
This addon is for **rewind**, not for continuous collision detection. CCD looks forward, at where things intend to move this step, and wants its bounds in your ordinary dynamic tree: compute each object's swept box for the step, the union of `bolt.shape_aabb` at its start and intended end, and keep it there with `tree:insert_bounds` and `tree:set_bounds`. Querying that tree with your own swept box yields exactly the pairs whose motions can cross during the step. This is how physics engines handle it, swept or predicted bounds live in the one broad phase tree, and a history structure like this addon exists only for looking backward.
:::

Like the visualizer this is an addon rather than part of the core. How long a window you keep, how often you sample it, and how far back you are willing to rewind are decisions about your game, not about collision detection. You can grab it [here](https://github.com/unityjaeger/Bolt/blob/main/addons/temporal_tree.luau), and as with the visualizer it assumes `bolt` sits under `ReplicatedStorage`.

```luau
local temporal = require(path.to.temporal_tree)

local tracker = temporal.new({
    window = 0.25,
    rate = 60,
    buckets = 4,
    aabb_padding = 0.1,
})
```

| Field | Description |
|---|---|
| `window` | How far back the tree remembers, in whatever unit your timestamps use. |
| `rate` | Expected snapshots per unit of window. Together with `window` this sizes the ring buffer. |
| `buckets` | How many slots the window is cut into, default `4`. See [Buckets](#buckets). |
| `aabb_padding` | Forwarded to the underlying dynamic tree. |

## Recording
```luau
tracker:track(id: number, shape: Shape)
tracker:snapshot(id: number, cf: CFrame, timestamp: number)
tracker:reset(id: number)
tracker:untrack(id: number)
tracker:clear()
```

`track` registers an object. Nothing reaches the tree until its first `snapshot`, since there is no history to bound before then, so a tracked object that has never been sampled is not returned by any queryy.

`snapshot` records where the object was at that moment. Timestamps must not go backwards.

`reset` forgets an object's history without untracking it. Call it on a teleport or a respawn: interpolating across one would sweep the reconstruction through everything between the two places, so the record starts over from the next snapshot instead.

`untrack` drops the object, its proxy and its history. `clear` does that for everything.

## Querying, then resolving
```luau
tracker.tree
tracker:pose_at(id: number, timestamp: number): (CFrame?, boolean)
```

The tree is a plain Bolt `DynamicTree`, so every query you already know works on it. What it returns is a filter: these are the objects that were somewhere in your query region at *some* point in the window, not the ones that were there at the moment you care about.

`pose_at` gives the pose interpolated between the two samples bracketing the timestamp, and you run the narrow phase against that pose yourself, with whichever of `gjk`, `mpr` or `dispatch` you were going to use anyway.

```luau
local candidates = tracker.tree:query_shape(shot_cf, shot_shape)

for _, id in candidates do
    local pose = tracker:pose_at(id, fired_at)
    if pose and bolt.dispatch.gjk.intersects(shot_cf, shot_shape, pose, shapes[id], 1e-4) then
        --hit, against where this object actually was
    end
end
```

The second return says whether the timestamp fell inside what is still held. `false` means the answer was clamped to the nearest end, which is what a rewind reaching further back than the window looks like. `nil` means nothing has been recorded for that object at all, either because it was never tracked or because it has not been sampled yet.

## Buckets
A union cannot be shrunk. Retiring the oldest samples out of one means rebuilding it from everything still held, which is work proportional to the whole window on every snapshot.

Splitting the window into slots avoids that. Each slot accumulates its own union until its period passes, then the whole slot is dropped and reused, and the object's bound is the union of whichever slots are still live. That is a walk over the slots rather than over the window.

The cost is that the bound covers up to one slot more history than the window strictly asks for. More buckets means a tighter bound and slightly more work per snapshot, fewer means the opposite. Four is a reasonable default.

## Limitations
- Timestamps must not go backwards.
- The reconstruction is an interpolation of samples, so it is only as faithful as the snapshot rate.
- A teleport is interpolated like any other step unless you call `reset`, and the reconstruction then sweeps across the map.
- Bounds are conservative, never tight. That costs rejected candidates, which is the right direction to be wrong in for a broad phase, but it does mean a fast tumbling object will be offered as a candidate more often than it is really hit.