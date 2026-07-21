--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	t.test("invariants/rotated box contact boundary agrees across narrow phases", function()
		local box_a = bolt.create_box(Vector3.new(2, 3, 4))
		local box_b = bolt.create_box(Vector3.new(1.5, 2.5, 1))
		local rotation_a = CFrame.fromOrientation(0.35, -0.5, 0.2)
		local rotation_b = CFrame.fromOrientation(-0.25, 0.4, -0.55)
		local cf_a = CFrame.new(-0.4, 0.2, 0.1) * rotation_a
		local contact_axis = cf_a.RightVector
		local half_extents_b = box_b.half_extents
		local radius_b =
			math.abs(contact_axis:Dot(rotation_b.RightVector)) * half_extents_b.X
			+ math.abs(contact_axis:Dot(rotation_b.UpVector)) * half_extents_b.Y
			+ math.abs(contact_axis:Dot(rotation_b.LookVector)) * half_extents_b.Z
		local center_distance = box_a.half_extents.X + radius_b

		local cases = {
			{name = "separated", offset = 1e-2, expected = false},
			{name = "touching", offset = 0, expected = true},
			{name = "overlapping", offset = -1e-2, expected = true},
		}

		for _, case in cases do
			local cf_b = CFrame.new(
				cf_a.Position + contact_axis * (center_distance + case.offset)
			) * rotation_b
			local special_hit = bolt.collision.box_box(cf_a, box_a, cf_b, box_b)
			local sat_hit, sat_normal, sat_depth = bolt.sat.box_box(cf_a, box_a, cf_b, box_b)
			local gjk_hit = bolt.gjk.intersects(cf_a, box_a, cf_b, box_b, 0)
			local mpr_hit = bolt.mpr.intersects(cf_a, box_a, cf_b, box_b, 1e-6)
			local message = `case {case.name}, offset {case.offset}`

			t.equal(special_hit, case.expected, `special: {message}`)
			t.equal(sat_hit, case.expected, `SAT: {message}`)
			t.equal(gjk_hit, case.expected, `GJK: {message}`)
			t.equal(mpr_hit, case.expected, `MPR: {message}`)

			if sat_hit then
				helpers.assert_unit_vector(t, t.non_nil(sat_normal), 1e-3)
				t.truthy(t.non_nil(sat_depth) >= 0)
			else
				t.is_nil(sat_normal)
				t.is_nil(sat_depth)
			end
		end
	end)

	t.test("invariants/sphere collision and casts remain stable across scales", function()
		for _, scale in {1e-2, 1, 1e3} do
			local sphere = bolt.create_sphere(scale)
			local gap = scale * 2e-2
			local touching_cf = CFrame.new(2 * scale, 0, 0)
			local separated_cf = CFrame.new(2 * scale + gap, 0, 0)
			local overlapping_cf = CFrame.new(2 * scale - gap, 0, 0)
			local message = `scale {scale}`

			t.truthy(bolt.collision.sphere_sphere(CFrame.identity, sphere, touching_cf, sphere), message)
			t.truthy(bolt.gjk.intersects(CFrame.identity, sphere, touching_cf, sphere, 0), message)
			t.truthy(bolt.mpr.intersects(CFrame.identity, sphere, touching_cf, sphere, 1e-6), message)

			t.falsy(bolt.collision.sphere_sphere(CFrame.identity, sphere, separated_cf, sphere), message)
			t.falsy(bolt.gjk.intersects(CFrame.identity, sphere, separated_cf, sphere, 0), message)
			t.falsy(bolt.mpr.intersects(CFrame.identity, sphere, separated_cf, sphere, 1e-6), message)

			t.truthy(bolt.collision.sphere_sphere(CFrame.identity, sphere, overlapping_cf, sphere), message)
			t.truthy(bolt.gjk.intersects(CFrame.identity, sphere, overlapping_cf, sphere, 0), message)
			t.truthy(bolt.mpr.intersects(CFrame.identity, sphere, overlapping_cf, sphere, 1e-6), message)

			local ray_origin = Vector3.new(-3 * scale, 0, 0)
			local ray_direction = Vector3.new(4 * scale, 0, 0)
			local _, special_distance = bolt.raycast.sphere(
				ray_origin,
				ray_direction,
				CFrame.identity,
				sphere
			)
			local _, gjk_distance = bolt.gjk.raycast(
				ray_origin,
				ray_direction,
				CFrame.identity,
				sphere,
				0
			)
			t.near(t.non_nil(special_distance) / scale, 2, 1e-3, message)
			t.near(t.non_nil(gjk_distance) / scale, 2, 1e-3, message)

			local cast_start = CFrame.new(-3 * scale, 0, 0)
			local cast_direction = Vector3.new(4 * scale, 0, 0)
			local simple_hit, simple_distance = bolt.gjk.shapecast_simple(
				cast_start,
				cast_direction,
				sphere,
				CFrame.identity,
				sphere,
				0
			)
			local point, distance, normal = bolt.gjk.shapecast(
				cast_start,
				cast_direction,
				sphere,
				CFrame.identity,
				sphere,
				0
			)
			t.truthy(simple_hit, message)
			t.non_nil(point, message)
			t.near(t.non_nil(simple_distance) / scale, 1, 1e-3, message)
			t.near(t.non_nil(distance) / scale, 1, 1e-3, message)
			helpers.assert_unit_vector(t, t.non_nil(normal), 1e-3)
		end
	end)
end