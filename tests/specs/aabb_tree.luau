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