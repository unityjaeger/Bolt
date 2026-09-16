--!strict

local Lest = require('@lest')
local describe, it = Lest.describe, Lest.it

local bolt = require('../../src')
local check = require('../check')
local helpers = require('../helpers')

local delta = helpers.DELTA
local tolerance = 1e-6
local sphere = bolt.create_sphere(1)
local box = bolt.create_box(Vector3.new(2, 2, 2))
local capsule = bolt.create_capsule(0.5, 2)

local cases = {
	{
		name = "sphere_sphere",
		shape_a = sphere,
		shape_b = sphere,
		cf_a = CFrame.identity,
		cf_b = function(offset: number)
			return CFrame.new(2 + offset, 0, 0)
		end,
	},
	{
		name = "box_box",
		shape_a = box,
		shape_b = box,
		cf_a = CFrame.identity,
		cf_b = function(offset: number)
			return CFrame.new(2 + offset, 0, 0)
		end,
	},
	{
		name = "box_sphere",
		shape_a = box,
		shape_b = sphere,
		cf_a = CFrame.identity,
		cf_b = function(offset: number)
			return CFrame.new(2 + offset, 0, 0)
		end,
	},
	{
		name = "box_capsule",
		shape_a = box,
		shape_b = capsule,
		cf_a = CFrame.identity,
		cf_b = function(offset: number)
			return CFrame.new(0, 1.5 + offset, 0)
		end,
	},
	{
		name = "sphere_capsule",
		shape_a = sphere,
		shape_b = capsule,
		cf_a = CFrame.identity,
		cf_b = function(offset: number)
			return CFrame.new(0, 1.5 + offset, 0)
		end,
	},
	{
		name = "capsule_capsule",
		shape_a = capsule,
		shape_b = capsule,
		cf_a = CFrame.identity,
		cf_b = function(offset: number)
			return CFrame.new(0, 1 + offset, 0)
		end,
	},
}

for _, case in cases do
	local mpr_case = case

	it(`mpr {mpr_case.name} separated`, function ()
		local hit, normal, depth, point_a, point_b = bolt.mpr.intersects(
			mpr_case.cf_a,
			mpr_case.shape_a,
			mpr_case.cf_b(delta),
			mpr_case.shape_b,
			tolerance
		)
		check.falsy(hit)
		check.vector_finite(normal)
		check.is_nil(depth)
		check.is_nil(point_a)
		check.is_nil(point_b)
	end)

	it(`mpr {mpr_case.name} touching`, function ()
		local hit, normal, depth, point_a, point_b = bolt.mpr.intersects(
			mpr_case.cf_a,
			mpr_case.shape_a,
			mpr_case.cf_b(0),
			mpr_case.shape_b,
			tolerance
		)
		check.truthy(hit)
		check.vector_near(normal, Vector3.zero)
		check.near(check.non_nil(depth), 0, 1e-4)
		check.vector_finite(check.non_nil(point_a))
		check.vector_finite(check.non_nil(point_b))
	end)

	it(`mpr {mpr_case.name} overlapping`, function ()
		local hit, normal, depth, point_a, point_b = bolt.mpr.intersects(
			mpr_case.cf_a,
			mpr_case.shape_a,
			mpr_case.cf_b(-delta),
			mpr_case.shape_b,
			tolerance
		)
		check.truthy(hit)
		helpers.assert_unit_vector(normal, 1e-3)
		check.truthy(check.non_nil(depth) >= 0)
		check.vector_finite(check.non_nil(point_a))
		check.vector_finite(check.non_nil(point_b))
	end)
end

describe('mpr', function ()
	it('tolerance treats only the configured separation band as contact', function ()
		local within_hit, within_normal, within_depth = bolt.mpr.intersects(
			CFrame.identity,
			sphere,
			CFrame.new(2 + tolerance * 0.5, 0, 0),
			sphere,
			tolerance
		)
		check.truthy(within_hit)
		check.vector_near(within_normal, Vector3.zero)
		check.near(check.non_nil(within_depth), 0)

		local outside_hit, _, outside_depth, outside_point_a, outside_point_b = bolt.mpr.intersects(
			CFrame.identity,
			sphere,
			CFrame.new(2 + tolerance * 2, 0, 0),
			sphere,
			tolerance
		)
		check.falsy(outside_hit)
		check.is_nil(outside_depth)
		check.is_nil(outside_point_a)
		check.is_nil(outside_point_b)
	end)


	describe('sphere_sphere', function ()
		it('swap flips normal and swaps points', function ()
			local cf_a = CFrame.identity
			local cf_b = CFrame.new(1.5, 0, 0)

			local hit_ab, normal_ab, depth_ab, point_a_ab, point_b_ab = bolt.mpr.intersects(cf_a, sphere, cf_b, sphere, tolerance)
			local hit_ba, normal_ba, depth_ba, point_a_ba, point_b_ba = bolt.mpr.intersects(cf_b, sphere, cf_a, sphere, tolerance)

			check.truthy(hit_ab)
			check.truthy(hit_ba)
			check.near(check.non_nil(depth_ab), check.non_nil(depth_ba), 1e-4)
			check.vector_near(normal_ab, -normal_ba, 1e-4)
			check.vector_near(check.non_nil(point_a_ab), check.non_nil(point_b_ba), 1e-4)
			check.vector_near(check.non_nil(point_b_ab), check.non_nil(point_a_ba), 1e-4)
		end)


		local swap_sphere = bolt.create_sphere(0.75)
		local swap_cases = {
			{
				name = "box_sphere",
				shape = bolt.create_box(Vector3.new(2, 2, 2)),
				sphere_center = Vector3.new(0.15, -1.4, 0.1),
			},
			{
				name = "ellipsoid_sphere",
				shape = bolt.create_ellipsoid(Vector3.new(2, 3, 4)),
				sphere_center = Vector3.new(0.1, -2, 0.15),
			},
			{
				name = "capsule_sphere",
				shape = bolt.create_capsule(0.5, 2),
				sphere_center = Vector3.new(0.15, -1, 0.1),
			},
			{
				name = "cylinder_sphere",
				shape = bolt.create_cylinder(1, 2),
				sphere_center = Vector3.new(0.15, -1.4, 0.1),
			},
			{
				name = "wedge_sphere",
				shape = bolt.create_wedge(Vector3.new(2, 2, 2)),
				sphere_center = Vector3.new(0.15, -1.4, 0.1),
			},
			{
				name = "corner_wedge_sphere",
				shape = bolt.create_corner_wedge(Vector3.new(2, 2, 2)),
				sphere_center = Vector3.new(0.15, -1.4, 0.1),
			},
			{
				name = "hull_sphere",
				shape = helpers.make_two_hull_mesh(bolt).children[1].shape,
				sphere_center = Vector3.new(0.1, -0.9, 0.05),
			},
		}

		for _, case in swap_cases do
			local swap_case = case
			it(`{swap_case.name} swap preserves contact`, function ()
				local shape_cf = CFrame.new(-0.4, 0.25, 0.6) * CFrame.fromOrientation(0, 0.35, 0)
				local sphere_cf = CFrame.new(shape_cf:PointToWorldSpace(swap_case.sphere_center))
				local hit_ab, normal_ab, depth_ab, point_a_ab, point_b_ab = bolt.mpr.intersects(
					shape_cf,
					swap_case.shape,
					sphere_cf,
					swap_sphere,
					tolerance
				)
				local hit_ba, normal_ba, depth_ba, point_a_ba, point_b_ba = bolt.mpr.intersects(
					sphere_cf,
					swap_sphere,
					shape_cf,
					swap_case.shape,
					tolerance
				)

				check.truthy(hit_ab)
				check.equal(hit_ba, hit_ab)
				check.near(check.non_nil(depth_ab), check.non_nil(depth_ba), 1e-3)
				check.vector_near(normal_ab, -normal_ba, 1e-3)
				check.vector_near(check.non_nil(point_a_ab), check.non_nil(point_b_ba), 2e-3)
				check.vector_near(check.non_nil(point_b_ab), check.non_nil(point_a_ba), 2e-3)
			end)
		end

	end)

	describe('is_separated', function ()
		it('touching is not separated', function ()
			local hit, cached_normal = bolt.mpr.intersects(
				CFrame.identity,
				sphere,
				CFrame.new(1.5, 0, 0),
				sphere,
				tolerance
			)
			check.truthy(hit)

			check.falsy(bolt.mpr.is_separated(
				CFrame.identity,
				sphere,
				CFrame.new(2, 0, 0),
				sphere,
				cached_normal
			))
			check.falsy(bolt.mpr.is_separated(
				CFrame.identity,
				sphere,
				CFrame.new(2 - delta, 0, 0),
				sphere,
				cached_normal
			))
			check.truthy(bolt.mpr.is_separated(
				CFrame.identity,
				sphere,
				CFrame.new(2 + delta, 0, 0),
				sphere,
				cached_normal
			))
		end)

	end)

end)

return nil