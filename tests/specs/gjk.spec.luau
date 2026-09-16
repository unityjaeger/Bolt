--!strict

local Lest = require('@lest')
local describe, it = Lest.describe, Lest.it

local bolt = require('../../src')
local check = require('../check')
local helpers = require('../helpers')

local tolerance = 0
local sphere = bolt.create_sphere(1)
local box = bolt.create_box(Vector3.new(2, 2, 2))

local supported_shapes = {
	{name = "box", shape = box},
	{name = "sphere", shape = sphere},
	{name = "ellipsoid", shape = bolt.create_ellipsoid(Vector3.new(2, 3, 4))},
	{name = "capsule", shape = bolt.create_capsule(0.5, 2)},
	{name = "cylinder", shape = bolt.create_cylinder(1, 2)},
	{name = "wedge", shape = bolt.create_wedge(Vector3.new(2, 2, 2))},
	{name = "corner_wedge", shape = bolt.create_corner_wedge(Vector3.new(2, 2, 2))},
}

for _, entry in supported_shapes do
	local shape_entry = entry

	it(`gjk intersects {shape_entry.name} self overlap`, function ()
		local hit = bolt.gjk.intersects(
			CFrame.identity,
			shape_entry.shape,
			CFrame.identity,
			shape_entry.shape,
			tolerance
		)
		check.truthy(hit)
	end)

	it(`gjk intersects {shape_entry.name} clear separation`, function ()
		local hit, separating_vector = bolt.gjk.intersects(
			CFrame.identity,
			shape_entry.shape,
			CFrame.new(20, 0, 0),
			shape_entry.shape,
			tolerance
		)
		check.falsy(hit)
		check.vector_finite(separating_vector)
	end)

	it(`gjk raycast {shape_entry.name} start overlap`, function ()
		local point, distance, normal = bolt.gjk.raycast(
			Vector3.zero,
			Vector3.xAxis,
			CFrame.identity,
			shape_entry.shape,
			tolerance
		)
		helpers.assert_start_hit(point, distance, normal, Vector3.zero)
	end)

	it(`gjk raycast {shape_entry.name} clear miss`, function ()
		helpers.assert_miss(bolt.gjk.raycast(
			Vector3.new(-10, 10, 10),
			Vector3.new(-5, 0, 0),
			CFrame.identity,
			shape_entry.shape,
			tolerance
		))
	end)
end

local function assert_shapecast_agrees(
	cf_a: CFrame,
	direction: Vector3,
	shape_a: any,
	cf_b: CFrame,
	shape_b: any,
	expected_hit: boolean,
	expected_distance: number?,
	expected_distance_epsilon: number?
)
	local simple_hit, simple_distance = bolt.gjk.shapecast_simple(
		cf_a,
		direction,
		shape_a,
		cf_b,
		shape_b,
		tolerance
	)
	local point, distance, normal = bolt.gjk.shapecast(
		cf_a,
		direction,
		shape_a,
		cf_b,
		shape_b,
		tolerance
	)

	check.equal(simple_hit, expected_hit)
	check.equal(point ~= nil, expected_hit)
	check.equal(distance ~= nil, expected_hit)
	check.equal(normal ~= nil, expected_hit)

	if expected_hit then
		local actual_simple_distance = check.non_nil(simple_distance)
		local actual_distance = check.non_nil(distance)
		check.near(actual_simple_distance, actual_distance, 1e-4)
		check.finite(actual_distance)
		check.vector_finite(check.non_nil(point))
		check.vector_finite(check.non_nil(normal))

		if expected_distance ~= nil then
			check.near(actual_distance, expected_distance, expected_distance_epsilon or 1e-4)
		end
	else
		check.is_nil(simple_distance)
	end
end

describe('gjk', function ()
	describe('intersects', function ()
		it('warm-started separation stays separated', function ()
			local cf_a = CFrame.identity
			local cf_b = CFrame.new(3, 0.25, 0)
			local hit, separating_vector = bolt.gjk.intersects(cf_a, box, cf_b, box, tolerance)
			check.falsy(hit)

			local warm_hit, warm_vector = bolt.gjk.intersects(
				cf_a,
				box,
				cf_b,
				box,
				tolerance,
				separating_vector
			)
			check.falsy(warm_hit)
			check.vector_finite(warm_vector)
		end)
	end)

	describe('shapecast', function ()
		it('ordinary hit', function ()
			assert_shapecast_agrees(
				CFrame.new(-3, 0, 0),
				Vector3.new(2, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				true,
				1
			)
		end)


		it('endpoint is included', function ()
			assert_shapecast_agrees(
				CFrame.new(-3, 0, 0),
				Vector3.new(1, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				true,
				1
			)
		end)


		it('beyond endpoint misses', function ()
			assert_shapecast_agrees(
				CFrame.new(-3, 0, 0),
				Vector3.new(1 - helpers.DELTA, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				false,
				nil
			)
		end)


		it('start touching', function ()
			assert_shapecast_agrees(
				CFrame.new(-2, 0, 0),
				Vector3.new(1, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				true,
				0
			)
		end)


		it('start overlapping with zero motion', function ()
			assert_shapecast_agrees(
				CFrame.new(-1.5, 0, 0),
				Vector3.zero,
				sphere,
				CFrame.identity,
				sphere,
				true,
				0
			)
		end)


		it('zero motion while separated misses', function ()
			assert_shapecast_agrees(
				CFrame.new(-3, 0, 0),
				Vector3.zero,
				sphere,
				CFrame.identity,
				sphere,
				false,
				nil
			)
		end)


		it('moving away misses', function ()
			assert_shapecast_agrees(
				CFrame.new(-3, 0, 0),
				Vector3.new(-2, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				false,
				nil
			)
		end)


		it('tangent contact', function ()
			assert_shapecast_agrees(
				CFrame.new(-3, 2, 0),
				Vector3.new(6, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				true,
				3,
				5e-4
			)
		end)


		it('swap motion preserves distance', function ()
			local hit_ab, distance_ab = bolt.gjk.shapecast_simple(
				CFrame.new(-3, 0, 0),
				Vector3.new(4, 0, 0),
				sphere,
				CFrame.identity,
				sphere,
				tolerance
			)
			local hit_ba, distance_ba = bolt.gjk.shapecast_simple(
				CFrame.identity,
				Vector3.new(-4, 0, 0),
				sphere,
				CFrame.new(-3, 0, 0),
				sphere,
				tolerance
			)

			check.truthy(hit_ab)
			check.equal(hit_ba, hit_ab)
			check.near(check.non_nil(distance_ab), check.non_nil(distance_ba), 1e-4)
		end)


		for _, target in supported_shapes do
			local target_entry = target

			it(`{target_entry.name} initial overlap agrees`, function ()
				assert_shapecast_agrees(
					CFrame.identity,
					Vector3.zero,
					sphere,
					CFrame.identity,
					target_entry.shape,
					true,
					0
				)
			end)

			it(`{target_entry.name} moving away agrees`, function ()
				assert_shapecast_agrees(
					CFrame.new(-10, 0, 0),
					Vector3.new(-2, 0, 0),
					sphere,
					CFrame.identity,
					target_entry.shape,
					false,
					nil
				)
			end)
		end

		local moving_targets = {
			{name = "box", shape = box, interior = Vector3.zero},
			{name = "sphere", shape = sphere, interior = Vector3.zero},
			{
				name = "ellipsoid",
				shape = bolt.create_ellipsoid(Vector3.new(2, 3, 4)),
				interior = Vector3.zero,
			},
			{name = "capsule", shape = bolt.create_capsule(0.5, 2), interior = Vector3.zero},
			{name = "cylinder", shape = bolt.create_cylinder(1, 2), interior = Vector3.zero},
			{
				name = "wedge",
				shape = bolt.create_wedge(Vector3.new(2, 2, 2)),
				interior = Vector3.new(0, -0.25, 0.25),
			},
			{
				name = "corner_wedge",
				shape = bolt.create_corner_wedge(Vector3.new(2, 2, 2)),
				interior = Vector3.new(0.2, -0.6, -0.2),
			},
			{
				name = "hull",
				shape = helpers.make_two_hull_mesh(bolt).children[1].shape,
				interior = Vector3.zero,
			},
		}
		local target_cf = CFrame.new(1.25, -0.5, 2) * CFrame.fromOrientation(0.2, -0.4, 0.3)

		for _, target in moving_targets do
			local target_entry = target
			local local_origin = target_entry.interior - Vector3.xAxis * 6
			local ray_origin = target_cf:PointToWorldSpace(local_origin)
			local ray_direction = target_cf:VectorToWorldSpace(Vector3.xAxis * 12)

			it(`raycast {target_entry.name} moving hit and returned endpoint`, function ()
				local point, distance, normal = bolt.gjk.raycast(
					ray_origin,
					ray_direction,
					target_cf,
					target_entry.shape,
					0
				)
				helpers.assert_cast_hit(point, distance, normal, ray_origin, ray_direction, nil)
				helpers.assert_unit_vector(check.non_nil(normal), 1e-3)

				local endpoint_direction = check.non_nil(point) - ray_origin
				local endpoint_point, endpoint_distance, endpoint_normal = bolt.gjk.raycast(
					ray_origin,
					endpoint_direction,
					target_cf,
					target_entry.shape,
					0
				)
				helpers.assert_cast_hit(endpoint_point,
					endpoint_distance,
					endpoint_normal,
					ray_origin,
					endpoint_direction,
					endpoint_direction.Magnitude
				)
			end)

			it(`{target_entry.name} moving hit brackets contact`, function ()
				local cast_shape = bolt.create_sphere(0.15)
				local start = CFrame.new(ray_origin)
				local simple_hit, simple_distance = bolt.gjk.shapecast_simple(
					start,
					ray_direction,
					cast_shape,
					target_cf,
					target_entry.shape,
					0
				)
				local point, distance, normal = bolt.gjk.shapecast(
					start,
					ray_direction,
					cast_shape,
					target_cf,
					target_entry.shape,
					0
				)

				check.truthy(simple_hit)
				check.non_nil(point)
				local simple_hit_distance = check.non_nil(simple_distance)
				check.near(check.non_nil(distance), simple_hit_distance, 1e-3)
				helpers.assert_unit_vector(check.non_nil(normal), 1e-3)

				local hit_distance = check.non_nil(distance)
				local direction_unit = ray_direction.Unit
				local bracket = 5e-3
				check.truthy(hit_distance > bracket)
				check.truthy(hit_distance < ray_direction.Magnitude - bracket)
				local before = CFrame.new(ray_origin + direction_unit * (hit_distance - bracket))
				local after = CFrame.new(ray_origin + direction_unit * (hit_distance + bracket))
				check.falsy(bolt.gjk.intersects(before, cast_shape, target_cf, target_entry.shape, 0))
				check.truthy(bolt.gjk.intersects(after, cast_shape, target_cf, target_entry.shape, 0))

				local endpoint_direction = direction_unit * simple_hit_distance
				local endpoint_hit, endpoint_distance = bolt.gjk.shapecast_simple(
					start,
					endpoint_direction,
					cast_shape,
					target_cf,
					target_entry.shape,
					0
				)
				check.truthy(endpoint_hit)
				check.near(check.non_nil(endpoint_distance), simple_hit_distance, 1e-3)
			end)
		end
	end)

end)

return nil