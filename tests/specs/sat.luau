--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	local delta = helpers.DELTA
	local box = bolt.create_box(Vector3.new(2, 2, 2))
	local wedge = bolt.create_wedge(Vector3.new(2, 2, 2))
	local corner_wedge = bolt.create_corner_wedge(Vector3.new(2, 2, 2))
	local identity = CFrame.identity

	local cases = {
		{name = "box_box", collide = bolt.sat.box_box, shape_a = box, shape_b = box},
		{name = "box_wedge", collide = bolt.sat.box_wedge, shape_a = box, shape_b = wedge},
		{name = "wedge_wedge", collide = bolt.sat.wedge_wedge, shape_a = wedge, shape_b = wedge},
		{
			name = "wedge_corner_wedge",
			collide = bolt.sat.wedge_corner_wedge,
			shape_a = wedge,
			shape_b = corner_wedge,
		},
		{
			name = "box_corner_wedge",
			collide = bolt.sat.box_corner_wedge,
			shape_a = box,
			shape_b = corner_wedge,
		},
		{
			name = "corner_wedge_corner_wedge",
			collide = bolt.sat.corner_wedge_corner_wedge,
			shape_a = corner_wedge,
			shape_b = corner_wedge,
		},
	}

	for _, case in cases do
		local sat_case = case

		t.test(`sat/{sat_case.name}/separated`, function()
			local hit, normal, depth = sat_case.collide(
				identity,
				sat_case.shape_a,
				CFrame.new(2 + delta, 0, 0),
				sat_case.shape_b
			)
			t.falsy(hit)
			t.is_nil(normal)
			t.is_nil(depth)
		end)

		t.test(`sat/{sat_case.name}/touching`, function()
			local hit, normal, depth = sat_case.collide(
				identity,
				sat_case.shape_a,
				CFrame.new(2, 0, 0),
				sat_case.shape_b
			)
			t.truthy(hit)
			helpers.assert_unit_vector(t, t.non_nil(normal), 1e-3)
			t.near(t.non_nil(depth), 0, 1e-4)
		end)

		t.test(`sat/{sat_case.name}/overlapping`, function()
			local cf_b = CFrame.new(2 - delta, 0, 0)
			local hit, normal, depth = sat_case.collide(
				identity,
				sat_case.shape_a,
				cf_b,
				sat_case.shape_b
			)
			t.truthy(hit)
			local hit_normal = t.non_nil(normal)
			local hit_depth = t.non_nil(depth)
			helpers.assert_unit_vector(t, hit_normal, 1e-3)
			t.truthy(hit_depth > 0)

			local separated_cf_a = CFrame.new(hit_normal * (hit_depth + delta))
			local separated = sat_case.collide(
				separated_cf_a,
				sat_case.shape_a,
				cf_b,
				sat_case.shape_b
			)
			t.falsy(separated)
		end)
	end

	t.test("sat/box_box/agrees with special and GJK for rotated boxes", function()
		local cf_a = CFrame.new(-0.25, 0.1, 0.2) * CFrame.fromOrientation(0.25, -0.4, 0.1)
		local cf_b = CFrame.new(1.1, 0.2, -0.15) * CFrame.fromOrientation(-0.2, 0.3, 0.55)
		local sat_hit = bolt.sat.box_box(cf_a, box, cf_b, box)
		local special_hit = bolt.collision.box_box(cf_a, box, cf_b, box)
		local gjk_hit = bolt.gjk.intersects(cf_a, box, cf_b, box, 0)
		t.equal(sat_hit, special_hit)
		t.equal(sat_hit, gjk_hit)
	end)

	t.test("sat/box_box/swap preserves depth and flips normal", function()
		local cf_a = CFrame.new(-0.4, 0.1, 0)
		local cf_b = CFrame.new(0.8, 0.2, 0.1) * CFrame.fromOrientation(0.1, 0.2, -0.15)
		local hit_ab, normal_ab, depth_ab = bolt.sat.box_box(cf_a, box, cf_b, box)
		local hit_ba, normal_ba, depth_ba = bolt.sat.box_box(cf_b, box, cf_a, box)

		t.truthy(hit_ab)
		t.equal(hit_ba, hit_ab)
		t.near(t.non_nil(depth_ab), t.non_nil(depth_ba), 1e-4)
		t.vector_near(t.non_nil(normal_ab), -t.non_nil(normal_ba), 1e-4)
	end)
end