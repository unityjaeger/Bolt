--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
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

		t.test(`mpr/{mpr_case.name}/separated`, function()
			local hit, normal, depth, point_a, point_b = bolt.mpr.intersects(
				mpr_case.cf_a,
				mpr_case.shape_a,
				mpr_case.cf_b(delta),
				mpr_case.shape_b,
				tolerance
			)
			t.falsy(hit)
			t.vector_finite(normal)
			t.is_nil(depth)
			t.is_nil(point_a)
			t.is_nil(point_b)
		end)

		t.test(`mpr/{mpr_case.name}/touching`, function()
			local hit, normal, depth, point_a, point_b = bolt.mpr.intersects(
				mpr_case.cf_a,
				mpr_case.shape_a,
				mpr_case.cf_b(0),
				mpr_case.shape_b,
				tolerance
			)
			t.truthy(hit)
			t.vector_near(normal, Vector3.zero)
			t.near(t.non_nil(depth), 0, 1e-4)
			t.vector_finite(t.non_nil(point_a))
			t.vector_finite(t.non_nil(point_b))
		end)

		t.test(`mpr/{mpr_case.name}/overlapping`, function()
			local hit, normal, depth, point_a, point_b = bolt.mpr.intersects(
				mpr_case.cf_a,
				mpr_case.shape_a,
				mpr_case.cf_b(-delta),
				mpr_case.shape_b,
				tolerance
			)
			t.truthy(hit)
			helpers.assert_unit_vector(t, normal, 1e-3)
			t.truthy(t.non_nil(depth) >= 0)
			t.vector_finite(t.non_nil(point_a))
			t.vector_finite(t.non_nil(point_b))
		end)
	end

	t.test("mpr/tolerance treats only the configured separation band as contact", function()
		local within_hit, within_normal, within_depth = bolt.mpr.intersects(
			CFrame.identity,
			sphere,
			CFrame.new(2 + tolerance * 0.5, 0, 0),
			sphere,
			tolerance
		)
		t.truthy(within_hit)
		t.vector_near(within_normal, Vector3.zero)
		t.near(t.non_nil(within_depth), 0)

		local outside_hit, _, outside_depth, outside_point_a, outside_point_b = bolt.mpr.intersects(
			CFrame.identity,
			sphere,
			CFrame.new(2 + tolerance * 2, 0, 0),
			sphere,
			tolerance
		)
		t.falsy(outside_hit)
		t.is_nil(outside_depth)
		t.is_nil(outside_point_a)
		t.is_nil(outside_point_b)
	end)

	t.test("mpr/sphere_sphere/swap flips normal and swaps points", function()
		local cf_a = CFrame.identity
		local cf_b = CFrame.new(1.5, 0, 0)

		local hit_ab, normal_ab, depth_ab, point_a_ab, point_b_ab = bolt.mpr.intersects(cf_a, sphere, cf_b, sphere, tolerance)
		local hit_ba, normal_ba, depth_ba, point_a_ba, point_b_ba = bolt.mpr.intersects(cf_b, sphere, cf_a, sphere, tolerance)

		t.truthy(hit_ab)
		t.truthy(hit_ba)
		t.near(t.non_nil(depth_ab), t.non_nil(depth_ba), 1e-4)
		t.vector_near(normal_ab, -normal_ba, 1e-4)
		t.vector_near(t.non_nil(point_a_ab), t.non_nil(point_b_ba), 1e-4)
		t.vector_near(t.non_nil(point_b_ab), t.non_nil(point_a_ba), 1e-4)
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
			shape = helpers.make_two_hull_mesh(bolt).hulls[1],
			sphere_center = Vector3.new(0.1, -0.9, 0.05),
		},
	}

	for _, case in swap_cases do
		local swap_case = case
		t.test(`mpr/{swap_case.name}/swap preserves contact`, function()
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

			t.truthy(hit_ab)
			t.equal(hit_ba, hit_ab)
			t.near(t.non_nil(depth_ab), t.non_nil(depth_ba), 1e-3)
			t.vector_near(normal_ab, -normal_ba, 1e-3)
			t.vector_near(t.non_nil(point_a_ab), t.non_nil(point_b_ba), 2e-3)
			t.vector_near(t.non_nil(point_b_ab), t.non_nil(point_a_ba), 2e-3)
		end)
	end

	t.test("mpr/is_separated/touching is not separated", function()
		local hit, cached_normal = bolt.mpr.intersects(
			CFrame.identity,
			sphere,
			CFrame.new(1.5, 0, 0),
			sphere,
			tolerance
		)
		t.truthy(hit)

		t.falsy(bolt.mpr.is_separated(
			CFrame.identity,
			sphere,
			CFrame.new(2, 0, 0),
			sphere,
			cached_normal
		))
		t.falsy(bolt.mpr.is_separated(
			CFrame.identity,
			sphere,
			CFrame.new(2 - delta, 0, 0),
			sphere,
			cached_normal
		))
		t.truthy(bolt.mpr.is_separated(
			CFrame.identity,
			sphere,
			CFrame.new(2 + delta, 0, 0),
			sphere,
			cached_normal
		))
	end)
end