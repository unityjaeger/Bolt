--!strict
--!optimize 2

local bolt = require(game.ReplicatedStorage.bolt)

export type Config = {
	--how far back the tree remembers, in whatever unit the timestamps passed to snapshot use
	window: number,
	--expected snapshots per unit of window
	rate: number,
	--how many slots the window is cut into, see the comment on fold_buckets
	buckets: number?,
	--forwarded to the tree
	aabb_padding: number?,
}

type Tracked = {
	shape: any,
	--rotation invariant radius
	radius: number,

	--ring of poses, newest at head, wrapping at capacity
	cf: {CFrame},
	stamp: {number},
	capacity: number,
	count: number,
	head: number,

	--the previous sample's bounds
	last_min: Vector3?,
	last_max: Vector3?,

	--one union per slot, each tagged with the period it belongs to
	bucket_min: {Vector3},
	bucket_max: {Vector3},
	bucket_epoch: {number},

	--the tree proxy only exists once there is something to bound
	registered: boolean,
}

local TemporalTree = {}
TemporalTree.__index = TemporalTree

export type TemporalTree = typeof(setmetatable({} :: {
	tree: any,
	window: number,
	bucket_count: number,
	bucket_duration: number,
	capacity: number,
	tracked: {[number]: Tracked},
}, TemporalTree))

--the angle between two orientations, read off the trace of the relative rotation

--this is the geodesic distance, which is exactly how far CFrame:Lerp turns between the same two poses:
--the lerp takes the short way and this measures the short way, that is what
--makes the recovered angle exact for the trajectory pose_at reconstructs, at any real spin rate
local function delta_angle(a: CFrame, b: CFrame): number
	local trace = vector.dot(a.RightVector :: any, b.RightVector :: any)
		+ vector.dot(a.UpVector :: any, b.UpVector :: any)
		+ vector.dot(a.LookVector :: any, b.LookVector :: any)

	return math.acos(math.clamp((trace - 1) * 0.5, -1, 1))
end

--everything the shape covered while it travelled from one sample to the next

--the two AABBs cover the endpoints, and between them the centre runs along a straight line the union already contains

--a point at radius r swinging through an angle leaves its own chord by at most r * (1 - cos(angle / 2)),
--so widening by that covers every orientation it passed through on the way.

--at exactly half a turn the two orientations are antipodal and the short way is not unique
local function step_bound(
	radius: number,
	previous_cf: CFrame, previous_min: Vector3, previous_max: Vector3,
	current_cf: CFrame, current_min: Vector3, current_max: Vector3,
	angle: number
): (Vector3, Vector3)
	if angle >= math.pi then
		local a, b = previous_cf.Position, current_cf.Position
		local reach = vector.one * radius

		return vector.min(a :: any, b :: any) - reach :: any, vector.max(a :: any, b :: any) + reach :: any
	end

	local sagitta = vector.one * (radius * (1 - math.cos(angle * 0.5)))

	return vector.min(previous_min :: any, current_min :: any) - sagitta :: any,
		vector.max(previous_max :: any, current_max :: any) + sagitta :: any
end

--a union cannot be shrunk, so retiring the oldest samples out of one means rebuilding it from everything still held

--splitting the window into slots avoids that, a slot accumulates until its period passes,
--then the whole slot is dropped and reused, and the bound is the union of whichever slots are still live

--that costs a walk over the slots instead of over the window, and leaves the bound at most one slot wider than it strictly has to be
local function fold_buckets(tracked: Tracked, oldest_epoch: number): (Vector3?, Vector3?)
	local bucket_min = tracked.bucket_min
	local bucket_max = tracked.bucket_max
	local bucket_epoch = tracked.bucket_epoch

	local min: Vector3?, max: Vector3? = nil, nil

	for i = 1, #bucket_epoch do
		if bucket_epoch[i] >= oldest_epoch then
			if min == nil then
				min, max = bucket_min[i], bucket_max[i]
			else
				min = vector.min(min :: any, bucket_min[i] :: any) :: any
				max = vector.max(max :: any, bucket_max[i] :: any) :: any
			end
		end
	end

	return min, max
end

--registers an object without recording anything yet

--nothing reaches the tree until the first snapshot, since there is no history to bound before then
function TemporalTree.track(self: TemporalTree, id: number, shape: any)
	local capacity = self.capacity
	local bucket_count = self.bucket_count

	local bucket_epoch = table.create(bucket_count)
	for i = 1, bucket_count do
		bucket_epoch[i] = -math.huge
	end

	self.tracked[id] = {
		shape = shape,
		radius = bolt.circumradius(shape),
		cf = table.create(capacity),
		stamp = table.create(capacity),
		capacity = capacity,
		count = 0,
		head = 0,
		last_min = nil,
		last_max = nil,
		bucket_min = table.create(bucket_count),
		bucket_max = table.create(bucket_count),
		bucket_epoch = bucket_epoch,
		registered = false,
	}
end

--records where the object was at this moment, timestamps must not go backwards

--the rotation carried by the step is recovered from the two poses, that recovery reads the short
--way round, which is also the way pose_at interpolates

--an object that truly spun further between two samples is reconstructed as taking the short way, exactly as every client displayed it
function TemporalTree.snapshot(self: TemporalTree, id: number, cf: CFrame, timestamp: number)
	local tracked = self.tracked[id]
	if tracked == nil then
		return
	end

	local min, max = bolt.shape_aabb(cf, tracked.shape)

	local previous_cf = if tracked.count > 0 then tracked.cf[tracked.head] else nil
	local bound_min: Vector3, bound_max: Vector3

	if previous_cf == nil then
		--nothing to travel from yet, so the first sample bounds only itself
		bound_min, bound_max = min :: any, max :: any
	else
		local angle = delta_angle(previous_cf, cf)

		bound_min, bound_max = step_bound(
			tracked.radius,
			previous_cf, tracked.last_min :: Vector3, tracked.last_max :: Vector3,
			cf, min :: any, max :: any,
			angle
		)
	end

	--fold the step into the slot its period owns, resetting the slot when it has come back around
	local epoch = math.floor(timestamp / self.bucket_duration)
	local slot = epoch % self.bucket_count + 1

	if tracked.bucket_epoch[slot] ~= epoch then
		tracked.bucket_epoch[slot] = epoch
		tracked.bucket_min[slot] = bound_min
		tracked.bucket_max[slot] = bound_max
	else
		tracked.bucket_min[slot] = vector.min(tracked.bucket_min[slot] :: any, bound_min :: any) :: any
		tracked.bucket_max[slot] = vector.max(tracked.bucket_max[slot] :: any, bound_max :: any) :: any
	end

	--push onto the ring
	local head = tracked.head % tracked.capacity + 1
	tracked.head = head
	tracked.cf[head] = cf
	tracked.stamp[head] = timestamp

	if tracked.count < tracked.capacity then
		tracked.count += 1
	end

	tracked.last_min, tracked.last_max = min :: any, max :: any

	local total_min, total_max = fold_buckets(tracked, epoch - self.bucket_count + 1)
	if total_min == nil then
		return
	end

	if tracked.registered then
		self.tree:set_bounds(id, total_min :: Vector3, total_max :: Vector3)
	else
		self.tree:insert_bounds(id, total_min :: Vector3, total_max :: Vector3)
		tracked.registered = true
	end
end

--the ring holds the newest sample at head, so index 1 counting back is the far end of the window
local function ring_index(tracked: Tracked, i: number): number
	return (tracked.head - tracked.count + i - 1) % tracked.capacity + 1
end

--where the object was at this moment, interpolated between the two samples bracketing it
function TemporalTree.pose_at(self: TemporalTree, id: number, timestamp: number): (CFrame?, boolean)
	local tracked = self.tracked[id]
	if tracked == nil or tracked.count == 0 then
		return nil, false
	end

	local cf, stamp = tracked.cf, tracked.stamp
	local head, count = tracked.head, tracked.count

	local oldest = ring_index(tracked, 1)
	if timestamp <= stamp[oldest] then
		return cf[oldest], timestamp == stamp[oldest]
	end

	if timestamp >= stamp[head] then
		return cf[head], timestamp == stamp[head]
	end

	--walk back from the newest, since a rewind usually lands near the recent end
	for i = count, 2, -1 do
		local newer = ring_index(tracked, i)
		if stamp[newer] <= timestamp then
			continue
		end

		local older = ring_index(tracked, i - 1)
		if stamp[older] > timestamp then
			continue
		end

		local span = stamp[newer] - stamp[older]
		if span <= 0 then
			return cf[newer], true
		end

		return cf[older]:Lerp(cf[newer], (timestamp - stamp[older]) / span), true
	end

	return cf[head], true
end

--forgets an object's history without untracking it
function TemporalTree.reset(self: TemporalTree, id: number)
	local tracked = self.tracked[id]
	if tracked == nil then
		return
	end

	tracked.count = 0
	tracked.head = 0
	tracked.last_min = nil
	tracked.last_max = nil

	for i = 1, self.bucket_count do
		tracked.bucket_epoch[i] = -math.huge
	end

	if tracked.registered then
		self.tree:remove(id)
		tracked.registered = false
	end
end

--drops the object and its proxy, history and all
function TemporalTree.untrack(self: TemporalTree, id: number)
	local tracked = self.tracked[id]
	if tracked == nil then
		return
	end

	if tracked.registered then
		self.tree:remove(id)
	end

	self.tracked[id] = nil
end

function TemporalTree.clear(self: TemporalTree)
	self.tree:clear()
	table.clear(self.tracked)
end

local function new(config: Config): TemporalTree
	local window = config.window
	local rate = config.rate
	local bucket_count = config.buckets or 4

	assert(window > 0, "window must be positive")
	assert(rate > 0, "rate must be positive")
	assert(bucket_count >= 1, "there must be at least one bucket")

	--one more than the window holds, so a timestamp at the far end still has a sample either side
	local capacity = math.max(2, math.ceil(window * rate) + 1)

	return setmetatable({
		tree = bolt.aabb_tree.new({aabb_padding = config.aabb_padding or 0}),
		window = window,
		bucket_count = bucket_count,
		bucket_duration = window / bucket_count,
		capacity = capacity,
		tracked = {},
	}, TemporalTree)
end

return {
	new = new,
}