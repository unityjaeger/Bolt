--!strict

local Lest = require('@lest')
local describe, it = Lest.describe, Lest.it

local bolt = require('../../src')
local check = require('../check')
local helpers = require('../helpers')

local box = bolt.create_box(Vector3.new(2, 2, 2))

describe('aabb tree', function ()
	describe('dynamic', function ()
		it('fresh empty operations', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0.5})
			check.set_equal(tree:query_aabb(Vector3.zero, Vector3.zero), {})
			check.set_equal(tree:query_shape(CFrame.identity, box), {})
			check.set_equal(tree:query_ray(Vector3.zero, Vector3.xAxis), {})
			check.set_equal(tree:query_shapecast(box, CFrame.identity, Vector3.xAxis), {})
			check.equal(tree:full_rebuild(), 0)
			check.equal(tree:partial_rebuild(), 0)
			check.falsy(tree:should_rebuild())
		end)
	end)

	describe('static', function ()
		it('fresh empty operations', function ()
			local tree = bolt.aabb_tree.new_static()
			check.set_equal(tree:query_aabb(Vector3.zero, Vector3.zero), {})
			check.set_equal(tree:query_shape(CFrame.identity, box), {})
			check.set_equal(tree:query_ray(Vector3.zero, Vector3.xAxis), {})
			check.set_equal(tree:query_shapecast(box, CFrame.identity, Vector3.xAxis), {})
			check.equal(tree:full_rebuild(), 0)
		end)
	end)

	describe('dynamic', function ()
		it('last removal resets rebuild state', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0.25})
			tree:insert(1, CFrame.identity, box)
			check.equal(tree:full_rebuild(), 1)
			check.non_nil(tree.base_cost_ratio)

			tree:remove(1)
			check.equal(tree.proxy_count, 0)
			check.is_nil(tree.base_cost_ratio)
			check.falsy(tree:should_rebuild())
			check.equal(tree:full_rebuild(), 0)
			check.equal(tree:partial_rebuild(), 0)

			tree:insert(2, CFrame.new(3, 0, 0), box)
			check.contains(tree:query_shape(CFrame.new(3, 0, 0), box), 2)
		end)
	end)

	describe('static', function ()
		it('last removal can rebuild empty', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:insert(2, CFrame.new(4, 0, 0), box)
			check.equal(tree:full_rebuild(), 2)
			tree:remove(1)
			tree:remove(2)
			check.equal(tree:full_rebuild(), 0)
			check.set_equal(tree:query_shape(CFrame.identity, box), {})
		end)
	end)

	describe('dynamic', function ()
		it('duplicate IDs error and unknown removal is harmless', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert(7, CFrame.identity, box)
			check.errors(function()
				tree:insert(7, CFrame.identity, box)
			end, "id already registered")
			tree:remove(999)
			check.contains(tree:query_shape(CFrame.identity, box), 7)
		end)
	end)

	describe('static', function ()
		it('exact AABB contact is included', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:full_rebuild()

			local point = Vector3.new(1, 0, 0)
			check.contains(tree:query_aabb(point, point), 1)
			check.contains(tree:query_shape(CFrame.new(2, 0, 0), box), 1)
		end)


		it('ray endpoint is included', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:full_rebuild()

			check.contains(tree:query_ray(Vector3.new(-3, 0, 0), Vector3.new(2, 0, 0)), 1)
			check.not_contains(tree:query_ray(
				Vector3.new(-3, 0, 0),
				Vector3.new(2 - helpers.DELTA, 0, 0)
			), 1)
		end)


		it('parallel boundary ray avoids NaN rejection', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:full_rebuild()

			check.contains(tree:query_ray(Vector3.new(-3, 1, 0), Vector3.new(2, 0, 0)), 1)
			check.not_contains(tree:query_ray(
				Vector3.new(-3, 1 + helpers.DELTA, 0),
				Vector3.new(6, 0, 0)
			), 1)
		end)


		it('zero direction acts as a point query', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:full_rebuild()

			check.contains(tree:query_ray(Vector3.zero, Vector3.zero), 1)
			check.not_contains(tree:query_ray(Vector3.new(3, 0, 0), Vector3.zero), 1)
		end)
	end)

	describe('dynamic', function ()
		it('resize preserves padding', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 1})
			tree:insert(1, CFrame.identity, bolt.create_sphere(1))
			tree:resize(1, bolt.create_sphere(0.5))

			local inside_padding = Vector3.new(1.25, 0, 0)
			local outside_padding = Vector3.new(1.75, 0, 0)
			check.contains(tree:query_aabb(inside_padding, inside_padding), 1)
			check.not_contains(tree:query_aabb(outside_padding, outside_padding), 1)
		end)


		it('move within and beyond padding', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 1})
			local sphere = bolt.create_sphere(0.5)
			tree:insert(1, CFrame.identity, sphere)

			tree:move(1, CFrame.new(0.5, 0, 0))
			check.contains(tree:query_shape(CFrame.new(0.5, 0, 0), sphere), 1)

			tree:move(1, CFrame.new(4, 0, 0))
			check.not_contains(tree:query_aabb(Vector3.zero, Vector3.zero), 1)
			check.contains(tree:query_shape(CFrame.new(4, 0, 0), sphere), 1)
		end)


		it('clear resets all observable state', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0.5})
			tree:insert(1, CFrame.identity, box)
			tree:insert(2, CFrame.new(4, 0, 0), box)
			tree:full_rebuild()
			tree:clear()

			check.set_equal(tree:query_shape(CFrame.identity, box), {})
			check.equal(tree:full_rebuild(), 0)
			check.equal(tree:partial_rebuild(), 0)
			check.falsy(tree:should_rebuild())
		end)


		it('non-empty rebuild preserves every ID', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0.25})
			local expected = {}

			for id = 1, 12 do
				tree:insert(id, CFrame.new(id * 3, id % 3, 0), box)
				table.insert(expected, id)
			end

			check.equal(tree:full_rebuild(), 12)
			check.set_equal(
				tree:query_aabb(Vector3.new(-10, -10, -10), Vector3.new(50, 10, 10)),
				expected
			)

			local rebuilt = tree:partial_rebuild()
			check.truthy(rebuilt > 0 and rebuilt <= 12)
			check.set_equal(
				tree:query_aabb(Vector3.new(-10, -10, -10), Vector3.new(50, 10, 10)),
				expected
			)
		end)


		it('random mutations preserve state and candidates', function ()
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
				check.equal(tree.proxy_count, #active_ids, message)
				check.set_equal(
					tree:query_aabb(-Vector3.one * 50, Vector3.one * 50),
					active_ids,
					message
				)

				for _, id in active_ids do
					local record = records[id]
					check.contains(tree:query_shape(record.cf, record.shape), id, message)
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
							check.contains(shape_candidates, id, `shape false negative: {message}, id {id}`)
						end
						if bolt.gjk.raycast(ray_origin, ray_direction, record.cf, record.shape, 0) ~= nil then
							check.contains(ray_candidates, id, `ray false negative: {message}, id {id}`)
						end
						if bolt.gjk.shapecast_simple(
							query_cf,
							ray_direction,
							query_shape,
							record.cf,
							record.shape,
							0
						) then
							check.contains(cast_candidates, id, `cast false negative: {message}, id {id}`)
						end
					end
				end
			end

			while #active_ids > 0 do
				local id = table.remove(active_ids)
				tree:remove(id)
			end
			check.equal(tree.proxy_count, 0)
			check.falsy(tree:should_rebuild())
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

			it(`conservative {shape_entry.name} shape query`, function ()
				local tree = bolt.aabb_tree.new_static()
				tree:insert(id, cf, shape_entry.shape)
				tree:full_rebuild()
				check.contains(tree:query_shape(cf, shape_entry.shape), id)
			end)

			it(`conservative {shape_entry.name} zero cast`, function ()
				local tree = bolt.aabb_tree.new_static()
				tree:insert(id, cf, shape_entry.shape)
				tree:full_rebuild()

				local ray_point = bolt.gjk.raycast(cf.Position, Vector3.zero, cf, shape_entry.shape, 0)
				check.non_nil(ray_point)
				check.contains(tree:query_ray(cf.Position, Vector3.zero), id)

				local sphere = bolt.create_sphere(0.1)
				local shapecast_hit = bolt.gjk.shapecast_simple(
					CFrame.new(cf.Position),
					Vector3.zero,
					sphere,
					cf,
					shape_entry.shape,
					0
				)
				check.truthy(shapecast_hit)
				check.contains(tree:query_shapecast(sphere, CFrame.new(cf.Position), Vector3.zero), id)
			end)
		end

		--regression: the slab test folds its per axis results with math.max/math.min, which start from
		--their first argument and skip anything failing the comparison

		--a ray parallel to an axis produces a NaN there, and with the 0/1 constants used last that NaN was only skipped when it
		--landed in y or z, an x aligned graze silently returned no candidates
	end)

	describe('ray', function ()
		it('grazes a face on every axis', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:full_rebuild()

			--box spans -1..1, so each ray runs exactly along one boundary plane
			check.contains(tree:query_ray(Vector3.new(-3, 1, 0), Vector3.new(2, 0, 0)), 1, "y on boundary, moving along x")
			check.contains(tree:query_ray(Vector3.new(-3, 0, 1), Vector3.new(2, 0, 0)), 1, "z on boundary, moving along x")
			check.contains(tree:query_ray(Vector3.new(1, -3, 0), Vector3.new(0, 2, 0)), 1, "x on boundary, moving along y")
			check.contains(tree:query_ray(Vector3.new(1, 0, -3), Vector3.new(0, 0, 2)), 1, "x on boundary, moving along z")
			check.contains(tree:query_ray(Vector3.new(0, 1, -3), Vector3.new(0, 0, 2)), 1, "y on boundary, moving along z")

			--just outside the same planes must still miss
			local delta = helpers.DELTA
			check.not_contains(tree:query_ray(Vector3.new(-3, 1 + delta, 0), Vector3.new(6, 0, 0)), 1)
			check.not_contains(tree:query_ray(Vector3.new(1 + delta, -3, 0), Vector3.new(0, 6, 0)), 1)
			check.not_contains(tree:query_ray(Vector3.new(1 + delta, 0, -3), Vector3.new(0, 0, 6)), 1)
		end)
	end)

	describe('shapecast', function ()
		it('grazes a face on every axis', function ()
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, box)
			tree:full_rebuild()

			--the cast box is 2x2x2 as well, so a center offset of exactly 2 puts the faces in contact
			check.contains(tree:query_shapecast(box, CFrame.new(2, -5, 0), Vector3.new(0, 10, 0)), 1, "x faces touching, sweeping y")
			check.contains(tree:query_shapecast(box, CFrame.new(2, 0, -5), Vector3.new(0, 0, 10)), 1, "x faces touching, sweeping z")
			check.contains(tree:query_shapecast(box, CFrame.new(-5, 2, 0), Vector3.new(10, 0, 0)), 1, "y faces touching, sweeping x")
			check.contains(tree:query_shapecast(box, CFrame.new(-5, 0, 2), Vector3.new(10, 0, 0)), 1, "z faces touching, sweeping x")

			check.not_contains(tree:query_shapecast(box, CFrame.new(2 + 0.01, -5, 0), Vector3.new(0, 10, 0)), 1)
			check.not_contains(tree:query_shapecast(box, CFrame.new(-5, 2 + 0.01, 0), Vector3.new(10, 0, 0)), 1)
		end)
	end)

	local function make_row_tree(count: number, spacing: number): any
		local tree = bolt.aabb_tree.new_static()
		for i = 1, count do
			tree:insert(i, CFrame.new((i - 1) * spacing, 0, 0), box)
		end
		tree:full_rebuild()
		return tree
	end

	describe('query_ray_closest', function ()
		it('returns the nearest proxy', function ()
			local tree = make_row_tree(8, 6)

			--narrow phase reports the proxy's own center distance along the ray, so proxy 1 is nearest
			local calls = 0
			local id, fraction = tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), function(candidate: number): number?
				calls += 1
				return (10 + (candidate - 1) * 6) / 60
			end)

			check.equal(id, 1)
			check.near(check.non_nil(fraction), 10 / 60, 1e-6)
			--pruning must actually happen: a full scan would touch all eight
			check.truthy(calls < 8, `narrow phase ran {calls} times, expected fewer than 8`)
		end)


		it('matches a full scan of query_ray', function ()
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
					check.is_nil(got_id)
				else
					check.near(check.non_nil(got_fraction), expected_fraction, 1e-6)
				end
			end
		end)


		it('handles misses and rejections', function ()
			local tree = make_row_tree(4, 6)

			check.is_nil(tree:query_ray_closest(Vector3.new(0, 50, 0), Vector3.new(0, 0, 10), function()
				return 0
			end))

			--a narrow phase that rejects every candidate is a miss even though AABBs overlap
			check.is_nil(tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), function()
				return nil
			end))

			--zero direction behaves as a point query
			local id = tree:query_ray_closest(Vector3.zero, Vector3.zero, function()
				return 0
			end)
			check.equal(id, 1)

			check.is_nil(bolt.aabb_tree.new_static():query_ray_closest(Vector3.zero, Vector3.xAxis, function()
				return 0
			end))
		end)


		it('max_fraction caps the search', function ()
			local tree = make_row_tree(8, 6)

			local function narrow_phase(candidate: number): number?
				return (10 + (candidate - 1) * 6) / 60
			end

			--proxy 1 sits at fraction 10/60, so a cap below that must reject everything
			check.is_nil(tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), narrow_phase, 0.1))

			local id = tree:query_ray_closest(Vector3.new(-10, 0, 0), Vector3.new(60, 0, 0), narrow_phase, 0.2)
			check.equal(id, 1)
		end)


	end)

	describe('query_shapecast_closest', function ()
		it('returns the nearest proxy', function ()
			local tree = make_row_tree(8, 6)
			local sphere = bolt.create_sphere(0.5)

			local calls = 0
			local id, fraction = tree:query_shapecast_closest(sphere, CFrame.new(-10, 0, 0), Vector3.new(60, 0, 0), function(candidate: number): number?
				calls += 1
				return (10 + (candidate - 1) * 6) / 60
			end)

			check.equal(id, 1)
			check.near(check.non_nil(fraction), 10 / 60, 1e-6)
			check.truthy(calls < 8, `narrow phase ran {calls} times, expected fewer than 8`)
		end)


		it('matches a full scan of query_shapecast', function ()
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
					check.is_nil(got_id)
				else
					check.near(check.non_nil(got_fraction), expected_fraction, 1e-6)
				end
			end
		end)


		it('handles misses, rejections and caps', function ()
			local tree = make_row_tree(6, 6)
			local sphere = bolt.create_sphere(0.5)

			check.is_nil(tree:query_shapecast_closest(sphere, CFrame.new(0, 50, 0), Vector3.new(0, 0, 10), function()
				return 0
			end))
			check.is_nil(tree:query_shapecast_closest(sphere, CFrame.new(-10, 0, 0), Vector3.new(60, 0, 0), function()
				return nil
			end))

			--a stationary cast overlapping a proxy still resolves
			local id = tree:query_shapecast_closest(sphere, CFrame.identity, Vector3.zero, function()
				return 0
			end)
			check.equal(id, 1)

			check.is_nil(tree:query_shapecast_closest(sphere, CFrame.new(-10, 0, 0), Vector3.new(60, 0, 0), function(candidate: number): number?
				return (10 + (candidate - 1) * 6) / 60
			end, 0.1))
		end)
	end)

	describe('query_ray_closest', function ()
		it('survives queries made from the narrow phase', function ()
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

			check.equal(nested_id, flat_id)
			check.near(check.non_nil(nested_fraction), check.non_nil(flat_fraction), 1e-9)
			check.equal(deepest, 3, "the nested queries did not actually run")
		end)
	end)

	describe('query_any', function ()
		it('stops at the first accepted candidate', function ()
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
			check.truthy(hit)
			check.equal(calls, 1)

			--rejecting everything has to visit them all and report false
			calls = 0
			check.falsy(tree:query_aabb_any(Vector3.zero, Vector3.zero, function()
				calls += 1
				return false
			end))
			check.equal(calls, 12)
		end)


		it('agrees with the collecting queries', function ()
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
				check.equal(any, #collected > 0)

				local shape_collected = tree:query_shape(CFrame.new(center), box)
				local shape_any = tree:query_shape_any(CFrame.new(center), box, function()
					return true
				end)
				check.equal(shape_any, #shape_collected > 0)
			end
		end)


		it('empty tree reports no hit', function ()
			local dynamic = bolt.aabb_tree.new({aabb_padding = 0})
			check.falsy(dynamic:query_aabb_any(Vector3.zero, Vector3.zero, function()
				return true
			end))
			check.falsy(dynamic:query_shape_any(CFrame.identity, box, function()
				return true
			end))
			check.falsy(bolt.aabb_tree.new_static():query_aabb_any(Vector3.zero, Vector3.zero, function()
				return true
			end))
		end)
	end)

	describe('shapecast', function ()
		it('uses rotated wedge AABB center', function ()
			local tree = bolt.aabb_tree.new_static()
			local target = bolt.create_box(Vector3.new(2, 2, 2))
			local query = bolt.create_wedge(Vector3.new(2, 3, 4))
			local start = CFrame.new(-5, 0, 0) * CFrame.fromOrientation(0.35, 0.6, 0.2)
			local direction = Vector3.new(10, 0, 0)

			tree:insert(1, CFrame.identity, target)
			tree:full_rebuild()

			local hit = bolt.gjk.shapecast_simple(start, direction, query, CFrame.identity, target, 0)
			check.truthy(hit)
			check.contains(tree:query_shapecast(query, start, direction), 1)
		end)
	end)

	describe('bounds', function ()
		it('insert_bounds registers a leaf with no shape behind it', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert_bounds(1, Vector3.new(-2, -2, -2), Vector3.new(2, 2, 2))

			local inside = Vector3.new(1.5, 0, 0)
			local outside = Vector3.new(3.5, 0, 0)
			check.contains(tree:query_aabb(inside, inside), 1)
			check.not_contains(tree:query_aabb(outside, outside), 1)

			tree:remove(1)
			check.not_contains(tree:query_aabb(inside, inside), 1)
		end)


		it('move and resize leave a bounds leaf alone', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert_bounds(1, Vector3.new(-2, -2, -2), Vector3.new(2, 2, 2))

			local home = Vector3.new(1.5, 0, 0)
			local far = Vector3.new(50, 0, 0)

			tree:move(1, CFrame.new(50, 0, 0))
			check.contains(tree:query_aabb(home, home), 1)
			check.not_contains(tree:query_aabb(far, far), 1)

			tree:resize(1, bolt.create_box(Vector3.new(40, 40, 40)))
			check.contains(tree:query_aabb(home, home), 1)
			check.not_contains(tree:query_aabb(Vector3.new(15, 0, 0), Vector3.new(15, 0, 0)), 1)
		end)


		it('set_bounds is the update path', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert_bounds(1, Vector3.new(-2, -2, -2), Vector3.new(2, 2, 2))

			tree:set_bounds(1, Vector3.new(8, -1, -1), Vector3.new(12, 1, 1))

			check.not_contains(tree:query_aabb(Vector3.new(1.5, 0, 0), Vector3.new(1.5, 0, 0)), 1)
			check.contains(tree:query_aabb(Vector3.new(10, 0, 0), Vector3.new(10, 0, 0)), 1)
		end)


		--alloc only writes the shape placeholder on a fresh index, a recycled one still holds the last
		--leaf's payload. if insert_bounds leant on that placeholder instead of writing it, this proxy
		--would inherit a shape and move would happily relocate it
		it('a bounds leaf on a recycled index still ignores move', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert(1, CFrame.identity, bolt.create_box(Vector3.new(2, 2, 2)))
			tree:remove(1)

			tree:insert_bounds(2, Vector3.new(-1, -1, -1), Vector3.new(1, 1, 1))
			tree:move(2, CFrame.new(70, 0, 0))

			check.contains(tree:query_aabb(Vector3.zero, Vector3.zero), 2)
			check.not_contains(tree:query_aabb(Vector3.new(70, 0, 0), Vector3.new(70, 0, 0)), 2)
		end)


		it('shape leaves still move and resize alongside them', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert(1, CFrame.identity, bolt.create_box(Vector3.new(2, 2, 2)))
			tree:insert_bounds(2, Vector3.new(20, -1, -1), Vector3.new(22, 1, 1))

			tree:move(1, CFrame.new(6, 0, 0))
			check.contains(tree:query_aabb(Vector3.new(6, 0, 0), Vector3.new(6, 0, 0)), 1)
			check.not_contains(tree:query_aabb(Vector3.zero, Vector3.zero), 1)

			tree:resize(1, bolt.create_box(Vector3.new(10, 10, 10)))
			check.contains(tree:query_aabb(Vector3.new(2, 0, 0), Vector3.new(2, 0, 0)), 1)

			check.contains(tree:query_aabb(Vector3.new(21, 0, 0), Vector3.new(21, 0, 0)), 2)
		end)


		it('padding absorbs a small set_bounds', function ()
			local tree = bolt.aabb_tree.new({aabb_padding = 1})
			tree:insert_bounds(1, Vector3.new(-1, -1, -1), Vector3.new(1, 1, 1))

			local leaf = tree.leaf_map[1]
			local before = tree.aabb_min[leaf]

			--still inside the padded box, so the tree should not be touched
			tree:set_bounds(1, Vector3.new(-1.2, -1, -1), Vector3.new(1.2, 1, 1))
			check.equal(tree.aabb_min[leaf], before)

			--past it, so the leaf has to be reinserted
			tree:set_bounds(1, Vector3.new(-5, -1, -1), Vector3.new(5, 1, 1))
			check.truthy(tree.aabb_min[leaf] ~= before)
			check.contains(tree:query_aabb(Vector3.new(4.5, 0, 0), Vector3.new(4.5, 0, 0)), 1)
		end)
	end)
end)

return nil