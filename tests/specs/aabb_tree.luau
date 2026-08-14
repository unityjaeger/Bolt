--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	local box = bolt.create_box(Vector3.new(2, 2, 2))

	t.test("aabb tree/dynamic/fresh empty operations", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 0.5})
		t.set_equal(tree:query_aabb(Vector3.zero, Vector3.zero), {})
		t.set_equal(tree:query_shape(CFrame.identity, box), {})
		t.set_equal(tree:query_ray(Vector3.zero, Vector3.xAxis), {})
		t.set_equal(tree:query_shapecast(box, CFrame.identity, Vector3.xAxis), {})
		t.equal(tree:full_rebuild(), 0)
		t.equal(tree:partial_rebuild(), 0)
		t.falsy(tree:should_rebuild())
	end)

	t.test("aabb tree/static/fresh empty operations", function()
		local tree = bolt.aabb_tree.new_static()
		t.set_equal(tree:query_aabb(Vector3.zero, Vector3.zero), {})
		t.set_equal(tree:query_shape(CFrame.identity, box), {})
		t.set_equal(tree:query_ray(Vector3.zero, Vector3.xAxis), {})
		t.set_equal(tree:query_shapecast(box, CFrame.identity, Vector3.xAxis), {})
		t.equal(tree:full_rebuild(), 0)
	end)

	t.test("aabb tree/dynamic/last removal resets rebuild state", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 0.25})
		tree:insert(1, CFrame.identity, box)
		t.equal(tree:full_rebuild(), 1)
		t.non_nil(tree.base_cost_ratio)

		tree:remove(1)
		t.equal(tree.proxy_count, 0)
		t.is_nil(tree.base_cost_ratio)
		t.falsy(tree:should_rebuild())
		t.equal(tree:full_rebuild(), 0)
		t.equal(tree:partial_rebuild(), 0)

		tree:insert(2, CFrame.new(3, 0, 0), box)
		t.contains(tree:query_shape(CFrame.new(3, 0, 0), box), 2)
	end)

	t.test("aabb tree/static/last removal can rebuild empty", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:insert(2, CFrame.new(4, 0, 0), box)
		t.equal(tree:full_rebuild(), 2)
		tree:remove(1)
		tree:remove(2)
		t.equal(tree:full_rebuild(), 0)
		t.set_equal(tree:query_shape(CFrame.identity, box), {})
	end)

	t.test("aabb tree/dynamic/duplicate IDs error and unknown removal is harmless", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 0})
		tree:insert(7, CFrame.identity, box)
		t.errors(function()
			tree:insert(7, CFrame.identity, box)
		end, "id already registered")
		tree:remove(999)
		t.contains(tree:query_shape(CFrame.identity, box), 7)
	end)

	t.test("aabb tree/static/exact AABB contact is included", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:full_rebuild()

		local point = Vector3.new(1, 0, 0)
		t.contains(tree:query_aabb(point, point), 1)
		t.contains(tree:query_shape(CFrame.new(2, 0, 0), box), 1)
	end)

	t.test("aabb tree/static/ray endpoint is included", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:full_rebuild()

		t.contains(tree:query_ray(Vector3.new(-3, 0, 0), Vector3.new(2, 0, 0)), 1)
		t.not_contains(tree:query_ray(
			Vector3.new(-3, 0, 0),
			Vector3.new(2 - helpers.DELTA, 0, 0)
		), 1)
	end)

	t.test("aabb tree/static/parallel boundary ray avoids NaN rejection", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:full_rebuild()

		t.contains(tree:query_ray(Vector3.new(-3, 1, 0), Vector3.new(2, 0, 0)), 1)
		t.not_contains(tree:query_ray(
			Vector3.new(-3, 1 + helpers.DELTA, 0),
			Vector3.new(6, 0, 0)
		), 1)
	end)

	t.test("aabb tree/static/zero direction acts as a point query", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:full_rebuild()

		t.contains(tree:query_ray(Vector3.zero, Vector3.zero), 1)
		t.not_contains(tree:query_ray(Vector3.new(3, 0, 0), Vector3.zero), 1)
	end)

	t.test("aabb tree/dynamic/resize preserves padding", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 1})
		tree:insert(1, CFrame.identity, bolt.create_sphere(1))
		tree:resize(1, bolt.create_sphere(0.5))

		local inside_padding = Vector3.new(1.25, 0, 0)
		local outside_padding = Vector3.new(1.75, 0, 0)
		t.contains(tree:query_aabb(inside_padding, inside_padding), 1)
		t.not_contains(tree:query_aabb(outside_padding, outside_padding), 1)
	end)

	t.test("aabb tree/dynamic/move within and beyond padding", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 1})
		local sphere = bolt.create_sphere(0.5)
		tree:insert(1, CFrame.identity, sphere)

		tree:move(1, CFrame.new(0.5, 0, 0))
		t.contains(tree:query_shape(CFrame.new(0.5, 0, 0), sphere), 1)

		tree:move(1, CFrame.new(4, 0, 0))
		t.not_contains(tree:query_aabb(Vector3.zero, Vector3.zero), 1)
		t.contains(tree:query_shape(CFrame.new(4, 0, 0), sphere), 1)
	end)

	t.test("aabb tree/dynamic/clear resets all observable state", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 0.5})
		tree:insert(1, CFrame.identity, box)
		tree:insert(2, CFrame.new(4, 0, 0), box)
		tree:full_rebuild()
		tree:clear()

		t.set_equal(tree:query_shape(CFrame.identity, box), {})
		t.equal(tree:full_rebuild(), 0)
		t.equal(tree:partial_rebuild(), 0)
		t.falsy(tree:should_rebuild())
	end)

	t.test("aabb tree/dynamic/non-empty rebuild preserves every ID", function()
		local tree = bolt.aabb_tree.new({aabb_padding = 0.25})
		local expected = {}

		for id = 1, 12 do
			tree:insert(id, CFrame.new(id * 3, id % 3, 0), box)
			table.insert(expected, id)
		end

		t.equal(tree:full_rebuild(), 12)
		t.set_equal(
			tree:query_aabb(Vector3.new(-10, -10, -10), Vector3.new(50, 10, 10)),
			expected
		)

		local rebuilt = tree:partial_rebuild()
		t.truthy(rebuilt > 0 and rebuilt <= 12)
		t.set_equal(
			tree:query_aabb(Vector3.new(-10, -10, -10), Vector3.new(50, 10, 10)),
			expected
		)
	end)

	t.test("aabb tree/dynamic/random mutations preserve state and candidates", function()
		local seed = 0xAABB
		local random = Random.new(seed)
		local tree = bolt.aabb_tree.new({aabb_padding = 0.25})
		local mutation_shapes = {
			bolt.create_box(Vector3.new(1.5, 2, 2.5)),
			bolt.create_sphere(0.75),
			bolt.create_ellipsoid(Vector3.new(1.5, 2.5, 3)),
			bolt.create_capsule(0.5, 2),
			bolt.create_cylinder(0.75, 2.5),
			bolt.create_wedge(Vector3.new(2, 2.5, 1.5)),
			bolt.create_corner_wedge(Vector3.new(2, 2.5, 1.5)),
		}
		local records: {[number]: {cf: CFrame, shape: any}} = {}
		local active_ids: {number} = {}
		local next_id = 1

		local function random_shape(): any
			return mutation_shapes[random:NextInteger(1, #mutation_shapes)]
		end

		local function assert_state(step: number)
			local message = `seed {seed}, step {step}`
			t.equal(tree.proxy_count, #active_ids, message)
			t.set_equal(
				tree:query_aabb(-Vector3.one * 50, Vector3.one * 50),
				active_ids,
				message
			)

			for _, id in active_ids do
				local record = records[id]
				t.contains(tree:query_shape(record.cf, record.shape), id, message)
			end
		end

		for step = 1, 180 do
			local operation = random:NextNumber()
			if #active_ids == 0 or operation < 0.3 then
				local id = next_id
				next_id += 1
				local record = {
					cf = helpers.random_cframe(random, 12),
					shape = random_shape(),
				}
				records[id] = record
				table.insert(active_ids, id)
				tree:insert(id, record.cf, record.shape)
			elseif operation < 0.55 then
				local id = active_ids[random:NextInteger(1, #active_ids)]
				local record = records[id]
				record.cf = helpers.random_cframe(random, 12)
				tree:move(id, record.cf)
			elseif operation < 0.7 then
				local id = active_ids[random:NextInteger(1, #active_ids)]
				local record = records[id]
				record.shape = random_shape()
				tree:resize(id, record.shape)
			elseif operation < 0.82 then
				local active_index = random:NextInteger(1, #active_ids)
				local id = active_ids[active_index]
				tree:remove(id)
				records[id] = nil
				table.remove(active_ids, active_index)
			elseif operation < 0.9 then
				tree:full_rebuild()
			elseif operation < 0.97 then
				tree:partial_rebuild()
			else
				tree:clear()
				table.clear(records)
				table.clear(active_ids)
			end

			assert_state(step)

			if #active_ids > 0 and step % 12 == 0 then
				local query_shape = random_shape()
				local query_cf = helpers.random_cframe(random, 14)
				local shape_candidates = tree:query_shape(query_cf, query_shape)
				local ray_origin = helpers.random_cframe(random, 16).Position
				local ray_direction = Vector3.new(
					random:NextNumber(-16, 16),
					random:NextNumber(-16, 16),
					random:NextNumber(-16, 16)
				)
				local ray_candidates = tree:query_ray(ray_origin, ray_direction)
				local cast_candidates = tree:query_shapecast(query_shape, query_cf, ray_direction)
				local message = `seed {seed}, step {step}`

				for _, id in active_ids do
					local record = records[id]
					if bolt.gjk.intersects(query_cf, query_shape, record.cf, record.shape, 0) then
						t.contains(shape_candidates, id, `shape false negative: {message}, id {id}`)
					end
					if bolt.gjk.raycast(ray_origin, ray_direction, record.cf, record.shape, 0) ~= nil then
						t.contains(ray_candidates, id, `ray false negative: {message}, id {id}`)
					end
					if bolt.gjk.shapecast_simple(
						query_cf,
						ray_direction,
						query_shape,
						record.cf,
						record.shape,
						0
					) then
						t.contains(cast_candidates, id, `cast false negative: {message}, id {id}`)
					end
				end
			end
		end

		while #active_ids > 0 do
			local id = table.remove(active_ids)
			tree:remove(id)
		end
		t.equal(tree.proxy_count, 0)
		t.falsy(tree:should_rebuild())
	end)

	local shapes = {
		{name = "box", shape = box},
		{name = "sphere", shape = bolt.create_sphere(1)},
		{name = "ellipsoid", shape = bolt.create_ellipsoid(Vector3.new(2, 3, 4))},
		{name = "capsule", shape = bolt.create_capsule(0.5, 2)},
		{name = "cylinder", shape = bolt.create_cylinder(1, 2)},
		{name = "wedge", shape = bolt.create_wedge(Vector3.new(2, 2, 2))},
		{name = "corner_wedge", shape = bolt.create_corner_wedge(Vector3.new(2, 2, 2))},
	}

	for index, entry in shapes do
		local shape_entry = entry
		local id = index
		local cf = CFrame.new(index * 5, 0.25, -0.5) * CFrame.fromOrientation(0.2 * index, -0.15 * index, 0.1 * index)

		t.test(`aabb tree/conservative/{shape_entry.name}/shape query`, function()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(id, cf, shape_entry.shape)
			tree:full_rebuild()
			t.contains(tree:query_shape(cf, shape_entry.shape), id)
		end)

		t.test(`aabb tree/conservative/{shape_entry.name}/zero cast`, function()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(id, cf, shape_entry.shape)
			tree:full_rebuild()

			local ray_point = bolt.gjk.raycast(cf.Position, Vector3.zero, cf, shape_entry.shape, 0)
			t.non_nil(ray_point)
			t.contains(tree:query_ray(cf.Position, Vector3.zero), id)

			local sphere = bolt.create_sphere(0.1)
			local shapecast_hit = bolt.gjk.shapecast_simple(
				CFrame.new(cf.Position),
				Vector3.zero,
				sphere,
				cf,
				shape_entry.shape,
				0
			)
			t.truthy(shapecast_hit)
			t.contains(tree:query_shapecast(sphere, CFrame.new(cf.Position), Vector3.zero), id)
		end)
	end

	--regression: the slab test folds its per axis results with math.max/math.min, which start from
	--their first argument and skip anything failing the comparison
	
	--a ray parallel to an axis produces a NaN there, and with the 0/1 constants used last that NaN was only skipped when it
	--landed in y or z, an x aligned graze silently returned no candidates
	t.test("aabb tree/ray/grazes a face on every axis", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:full_rebuild()

		--box spans -1..1, so each ray runs exactly along one boundary plane
		t.contains(tree:query_ray(Vector3.new(-3, 1, 0), Vector3.new(2, 0, 0)), 1, "y on boundary, moving along x")
		t.contains(tree:query_ray(Vector3.new(-3, 0, 1), Vector3.new(2, 0, 0)), 1, "z on boundary, moving along x")
		t.contains(tree:query_ray(Vector3.new(1, -3, 0), Vector3.new(0, 2, 0)), 1, "x on boundary, moving along y")
		t.contains(tree:query_ray(Vector3.new(1, 0, -3), Vector3.new(0, 0, 2)), 1, "x on boundary, moving along z")
		t.contains(tree:query_ray(Vector3.new(0, 1, -3), Vector3.new(0, 0, 2)), 1, "y on boundary, moving along z")

		--just outside the same planes must still miss
		local delta = helpers.DELTA
		t.not_contains(tree:query_ray(Vector3.new(-3, 1 + delta, 0), Vector3.new(6, 0, 0)), 1)
		t.not_contains(tree:query_ray(Vector3.new(1 + delta, -3, 0), Vector3.new(0, 6, 0)), 1)
		t.not_contains(tree:query_ray(Vector3.new(1 + delta, 0, -3), Vector3.new(0, 0, 6)), 1)
	end)

	t.test("aabb tree/shapecast/grazes a face on every axis", function()
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, CFrame.identity, box)
		tree:full_rebuild()

		--the cast box is 2x2x2 as well, so a center offset of exactly 2 puts the faces in contact
		t.contains(tree:query_shapecast(box, CFrame.new(2, -5, 0), Vector3.new(0, 10, 0)), 1, "x faces touching, sweeping y")
		t.contains(tree:query_shapecast(box, CFrame.new(2, 0, -5), Vector3.new(0, 0, 10)), 1, "x faces touching, sweeping z")
		t.contains(tree:query_shapecast(box, CFrame.new(-5, 2, 0), Vector3.new(10, 0, 0)), 1, "y faces touching, sweeping x")
		t.contains(tree:query_shapecast(box, CFrame.new(-5, 0, 2), Vector3.new(10, 0, 0)), 1, "z faces touching, sweeping x")

		t.not_contains(tree:query_shapecast(box, CFrame.new(2 + 0.01, -5, 0), Vector3.new(0, 10, 0)), 1)
		t.not_contains(tree:query_shapecast(box, CFrame.new(-5, 2 + 0.01, 0), Vector3.new(10, 0, 0)), 1)
	end)

	local function make_row_tree(count: number, spacing: number): any
		local tree = bolt.aabb_tree.new_static()
		for i = 1, count do
			tree:insert(i, CFrame.new((i - 1) * spacing, 0, 0), box)
		end
		tree:full_rebuild()
		return tree
	end

	t.test("aabb tree/query_ray_closest/returns the nearest proxy", function()
		local tree = make_row_tree(8, 6)

		--narrow phase reports the proxy's own center distance along the ray, so proxy 1 is nearest
		local calls = 0
		local id, fraction = tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), function(candidate: number): number?
			calls += 1
			return (10 + (candidate - 1) * 6) / 60
		end)

		t.equal(id, 1)
		t.near(t.non_nil(fraction), 10 / 60, 1e-6)
		--pruning must actually happen: a full scan would touch all eight
		t.truthy(calls < 8, `narrow phase ran {calls} times, expected fewer than 8`)
	end)

	t.test("aabb tree/query_ray_closest/matches a full scan of query_ray", function()
		local random = Random.new(90210)
		local tree = bolt.aabb_tree.new({aabb_padding = 0.5})
		local placements = {}
		for i = 1, 60 do
			local cf = CFrame.new(random:NextNumber(-25, 25), random:NextNumber(-25, 25), random:NextNumber(-25, 25))
			placements[i] = cf
			tree:insert(i, cf, box)
		end

		for _ = 1, 40 do
			local origin = Vector3.new(random:NextNumber(-30, 30), random:NextNumber(-30, 30), random:NextNumber(-30, 30))
			local direction = Vector3.new(random:NextNumber(-40, 40), random:NextNumber(-40, 40), random:NextNumber(-40, 40))

			local function narrow_phase(id: number): number?
				local point, distance = bolt.gjk.raycast(origin, direction, placements[id], box, 0)
				return if point and distance then distance / direction.Magnitude else nil
			end

			--brute force over every candidate the unpruned query returns
			local expected_id, expected_fraction = nil, math.huge
			for _, id in tree:query_ray(origin, direction) do
				local fraction = narrow_phase(id)
				if fraction and fraction < expected_fraction then
					expected_id = id
					expected_fraction = fraction
				end
			end

			local got_id, got_fraction = tree:query_ray_closest(origin, direction, narrow_phase)
			if expected_id == nil then
				t.is_nil(got_id)
			else
				t.near(t.non_nil(got_fraction), expected_fraction, 1e-6)
			end
		end
	end)

	t.test("aabb tree/query_ray_closest/handles misses and rejections", function()
		local tree = make_row_tree(4, 6)

		t.is_nil(tree:query_ray_closest(Vector3.new(0, 50, 0), Vector3.new(0, 0, 10), function()
			return 0
		end))

		--a narrow phase that rejects every candidate is a miss even though AABBs overlap
		t.is_nil(tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), function()
			return nil
		end))

		--zero direction behaves as a point query
		local id = tree:query_ray_closest(Vector3.zero, Vector3.zero, function()
			return 0
		end)
		t.equal(id, 1)

		t.is_nil(bolt.aabb_tree.new_static():query_ray_closest(Vector3.zero, Vector3.xAxis, function()
			return 0
		end))
	end)

	t.test("aabb tree/query_ray_closest/max_fraction caps the search", function()
		local tree = make_row_tree(8, 6)

		local function narrow_phase(candidate: number): number?
			return (10 + (candidate - 1) * 6) / 60
		end

		--proxy 1 sits at fraction 10/60, so a cap below that must reject everything
		t.is_nil(tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), narrow_phase, 0.1))

		local id = tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), narrow_phase, 0.2)
		t.equal(id, 1)
	end)

	t.test("aabb tree/query_shapecast_closest/returns the nearest proxy", function()
		local tree = make_row_tree(8, 6)
		local sphere = bolt.create_sphere(0.5)

		local calls = 0
		local id, fraction = tree:query_shapecast_closest(sphere, CFrame.new(-10, 0, 0), Vector3.new(60, 0, 0), function(candidate: number): number?
			calls += 1
			return (10 + (candidate - 1) * 6) / 60
		end)

		t.equal(id, 1)
		t.near(t.non_nil(fraction), 10 / 60, 1e-6)
		t.truthy(calls < 8, `narrow phase ran {calls} times, expected fewer than 8`)
	end)

	t.test("aabb tree/query_shapecast_closest/matches a full scan of query_shapecast", function()
		local random = Random.new(1337)
		local sphere = bolt.create_sphere(0.75)
		local tree = bolt.aabb_tree.new({aabb_padding = 0.5})
		local placements = {}
		for i = 1, 50 do
			local cf = CFrame.new(random:NextNumber(-20, 20), random:NextNumber(-20, 20), random:NextNumber(-20, 20))
			placements[i] = cf
			tree:insert(i, cf, box)
		end

		for _ = 1, 40 do
			local start = CFrame.new(random:NextNumber(-25, 25), random:NextNumber(-25, 25), random:NextNumber(-25, 25))
			local direction = Vector3.new(random:NextNumber(-30, 30), random:NextNumber(-30, 30), random:NextNumber(-30, 30))

			local function narrow_phase(id: number): number?
				local hit, distance = bolt.gjk.shapecast_simple(start, direction, sphere, placements[id], box, 0)
				return if hit and distance then distance / direction.Magnitude else nil
			end

			local expected_id, expected_fraction = nil, math.huge
			for _, id in tree:query_shapecast(sphere, start, direction) do
				local fraction = narrow_phase(id)
				if fraction and fraction < expected_fraction then
					expected_id = id
					expected_fraction = fraction
				end
			end

			local got_id, got_fraction = tree:query_shapecast_closest(sphere, start, direction, narrow_phase)
			if expected_id == nil then
				t.is_nil(got_id)
			else
				t.near(t.non_nil(got_fraction), expected_fraction, 1e-6)
			end
		end
	end)

	t.test("aabb tree/query_shapecast_closest/handles misses, rejections and caps", function()
		local tree = make_row_tree(6, 6)
		local sphere = bolt.create_sphere(0.5)

		t.is_nil(tree:query_shapecast_closest(sphere, CFrame.new(0, 50, 0), Vector3.new(0, 0, 10), function()
			return 0
		end))
		t.is_nil(tree:query_shapecast_closest(sphere, CFrame.new(-10, 0, 0), Vector3.new(60, 0, 0), function()
			return nil
		end))

		--a stationary cast overlapping a proxy still resolves
		local id = tree:query_shapecast_closest(sphere, CFrame.identity, Vector3.zero, function()
			return 0
		end)
		t.equal(id, 1)

		t.is_nil(tree:query_shapecast_closest(sphere, CFrame.new(-10, 0, 0), Vector3.new(60, 0, 0), function(candidate: number): number?
			return (10 + (candidate - 1) * 6) / 60
		end, 0.1))
	end)

	t.test("aabb tree/query_ray_closest/survives queries made from the narrow phase", function()
		local tree = bolt.aabb_tree.new_static()
		for i = 1, 40 do
			tree:insert(i, CFrame.new((i - 1) * 5, 0, 0), box)
		end
		tree:full_rebuild()

		local origin = Vector3.new(-10, 0, 0)
		local direction = Vector3.new(300, 0, 0)
		local function fraction_of(candidate: number): number
			return (10 + (candidate - 1) * 5) / 300
		end

		local flat_id, flat_fraction = tree:query_ray_closest(origin, direction, fraction_of)

		local depth = 0
		local deepest = 0
		local function nested(candidate: number): number?
			depth += 1
			deepest = math.max(deepest, depth)

			tree:query_aabb(Vector3.new(-100, -5, -5), Vector3.new(300, 5, 5))
			tree:query_aabb_any(Vector3.new(-100, -5, -5), Vector3.new(300, 5, 5), function()
				return false
			end)
			if depth < 3 then
				tree:query_ray_closest(origin, direction, nested)
			end
			tree:query_shapecast(box, CFrame.new(-10, 0, 0), direction)

			depth -= 1
			return fraction_of(candidate)
		end

		local nested_id, nested_fraction = tree:query_ray_closest(origin, direction, nested)

		t.equal(nested_id, flat_id)
		t.near(t.non_nil(nested_fraction), t.non_nil(flat_fraction), 1e-9)
		t.equal(deepest, 3, "the nested queries did not actually run")
	end)

	t.test("aabb tree/query_any/stops at the first accepted candidate", function()
		local tree = bolt.aabb_tree.new_static()
		for i = 1, 12 do
			tree:insert(i, CFrame.identity, box)
		end
		tree:full_rebuild()

		--every proxy overlaps, so accepting the first one must end the traversal immediately
		local calls = 0
		local hit = tree:query_aabb_any(Vector3.zero, Vector3.zero, function()
			calls += 1
			return true
		end)
		t.truthy(hit)
		t.equal(calls, 1)

		--rejecting everything has to visit them all and report false
		calls = 0
		t.falsy(tree:query_aabb_any(Vector3.zero, Vector3.zero, function()
			calls += 1
			return false
		end))
		t.equal(calls, 12)
	end)

	t.test("aabb tree/query_any/agrees with the collecting queries", function()
		local random = Random.new(4242)
		local tree = bolt.aabb_tree.new({aabb_padding = 0.25})
		for i = 1, 40 do
			tree:insert(i, CFrame.new(random:NextNumber(-15, 15), random:NextNumber(-15, 15), random:NextNumber(-15, 15)), box)
		end

		for _ = 1, 50 do
			local center = Vector3.new(random:NextNumber(-18, 18), random:NextNumber(-18, 18), random:NextNumber(-18, 18))
			local half = Vector3.one * random:NextNumber(0.5, 4)

			local collected = tree:query_aabb(center - half, center + half)
			local any = tree:query_aabb_any(center - half, center + half, function()
				return true
			end)
			t.equal(any, #collected > 0)

			local shape_collected = tree:query_shape(CFrame.new(center), box)
			local shape_any = tree:query_shape_any(CFrame.new(center), box, function()
				return true
			end)
			t.equal(shape_any, #shape_collected > 0)
		end
	end)

	t.test("aabb tree/query_any/empty tree reports no hit", function()
		local dynamic = bolt.aabb_tree.new({aabb_padding = 0})
		t.falsy(dynamic:query_aabb_any(Vector3.zero, Vector3.zero, function()
			return true
		end))
		t.falsy(dynamic:query_shape_any(CFrame.identity, box, function()
			return true
		end))
		t.falsy(bolt.aabb_tree.new_static():query_aabb_any(Vector3.zero, Vector3.zero, function()
			return true
		end))
	end)

	t.test("aabb tree/shapecast/uses rotated wedge AABB center", function()
		local tree = bolt.aabb_tree.new_static()
		local target = bolt.create_box(Vector3.new(2, 2, 2))
		local query = bolt.create_wedge(Vector3.new(2, 3, 4))
		local start = CFrame.new(-5, 0, 0) * CFrame.fromOrientation(0.35, 0.6, 0.2)
		local direction = Vector3.new(10, 0, 0)

		tree:insert(1, CFrame.identity, target)
		tree:full_rebuild()

		local hit = bolt.gjk.shapecast_simple(start, direction, query, CFrame.identity, target, 0)
		t.truthy(hit)
		t.contains(tree:query_shapecast(query, start, direction), 1)
	end)
end