--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	local delta = helpers.DELTA

	local cases = {
		{
			name = "sphere",
			shape = bolt.create_sphere(1),
			cf = CFrame.identity,
			origin = Vector3.new(-3, 0, 0),
			direction = Vector3.new(4, 0, 0),
			endpoint_direction = Vector3.new(2, 0, 0),
			short_direction = Vector3.new(2 - delta, 0, 0),
			expected_distance = 2,
			expected_point = Vector3.new(-1, 0, 0),
			expected_normal = Vector3.new(-1, 0, 0),
			inside = Vector3.zero,
			surface = Vector3.new(1, 0, 0),
			miss_origin = Vector3.new(-3, 3, 0),
			miss_direction = Vector3.new(6, 0, 0),
			tangent_origin = Vector3.new(-2, 1, 0),
			tangent_direction = Vector3.new(4, 0, 0),
			tangent_distance = 2,
			special = bolt.raycast.sphere,
		},
		{
			name = "box",
			shape = bolt.create_box(Vector3.new(2, 2, 2)),
			cf = CFrame.identity,
			origin = Vector3.new(-3, 0, 0),
			direction = Vector3.new(4, 0, 0),
			endpoint_direction = Vector3.new(2, 0, 0),
			short_direction = Vector3.new(2 - delta, 0, 0),
			expected_distance = 2,
			expected_point = Vector3.new(-1, 0, 0),
			expected_normal = Vector3.new(-1, 0, 0),
			inside = Vector3.zero,
			surface = Vector3.new(1, 0, 0),
			miss_origin = Vector3.new(-3, 3, 0),
			miss_direction = Vector3.new(6, 0, 0),
			tangent_origin = Vector3.new(-3, 1, 0),
			tangent_direction = Vector3.new(4, 0, 0),
			tangent_distance = 2,
			special = bolt.raycast.box,
		},
		{
			name = "capsule",
			shape = bolt.create_capsule(0.5, 2),
			cf = CFrame.identity,
			origin = Vector3.new(0, -2, 0),
			direction = Vector3.new(0, 3, 0),
			endpoint_direction = Vector3.new(0, 1.5, 0),
			short_direction = Vector3.new(0, 1.5 - delta, 0),
			expected_distance = 1.5,
			expected_point = Vector3.new(0, -0.5, 0),
			expected_normal = Vector3.new(0, -1, 0),
			inside = Vector3.zero,
			surface = Vector3.new(0, 0.5, 0),
			miss_origin = Vector3.new(0, -2, 2),
			miss_direction = Vector3.new(0, 4, 0),
			tangent_origin = Vector3.new(-2, 0.5, 0),
			tangent_direction = Vector3.new(4, 0, 0),
			tangent_distance = 1,
			special = bolt.raycast.capsule,
		},
	}

	for _, case in cases do
		local ray_case = case

		t.test(`raycast/{ray_case.name}/ordinary hit`, function()
			local point, distance, normal = ray_case.special(
				ray_case.origin,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_cast_hit(
				t,
				point,
				distance,
				normal,
				ray_case.origin,
				ray_case.direction,
				ray_case.expected_distance
			)
			t.vector_near(t.non_nil(point), ray_case.expected_point)
			t.vector_near(t.non_nil(normal), ray_case.expected_normal)
			helpers.assert_unit_vector(t, t.non_nil(normal))
		end)

		t.test(`raycast/{ray_case.name}/matches GJK`, function()
			local special_point, special_distance, special_normal = ray_case.special(
				ray_case.origin,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape
			)
			local gjk_point, gjk_distance, gjk_normal = bolt.gjk.raycast(
				ray_case.origin,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape,
				0
			)

			t.vector_near(t.non_nil(gjk_point), t.non_nil(special_point))
			t.near(t.non_nil(gjk_distance), t.non_nil(special_distance))
			t.vector_near(t.non_nil(gjk_normal), t.non_nil(special_normal), 1e-4)
		end)

		t.test(`raycast/{ray_case.name}/endpoint is included`, function()
			local point, distance, normal = ray_case.special(
				ray_case.origin,
				ray_case.endpoint_direction,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_cast_hit(
				t,
				point,
				distance,
				normal,
				ray_case.origin,
				ray_case.endpoint_direction,
				ray_case.expected_distance
			)

			local gjk_point, gjk_distance, gjk_normal = bolt.gjk.raycast(
				ray_case.origin,
				ray_case.endpoint_direction,
				ray_case.cf,
				ray_case.shape,
				0
			)
			helpers.assert_cast_hit(
				t,
				gjk_point,
				gjk_distance,
				gjk_normal,
				ray_case.origin,
				ray_case.endpoint_direction,
				ray_case.expected_distance
			)
		end)

		t.test(`raycast/{ray_case.name}/beyond endpoint misses`, function()
			helpers.assert_miss(t, ray_case.special(
				ray_case.origin,
				ray_case.short_direction,
				ray_case.cf,
				ray_case.shape
			))
			helpers.assert_miss(t, bolt.gjk.raycast(
				ray_case.origin,
				ray_case.short_direction,
				ray_case.cf,
				ray_case.shape,
				0
			))
		end)

		t.test(`raycast/{ray_case.name}/inside starts at zero`, function()
			local point, distance, normal = ray_case.special(
				ray_case.inside,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_start_hit(t, point, distance, normal, ray_case.inside)

			local gjk_point, gjk_distance, gjk_normal = bolt.gjk.raycast(
				ray_case.inside,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape,
				0
			)
			helpers.assert_start_hit(t, gjk_point, gjk_distance, gjk_normal, ray_case.inside)
		end)

		t.test(`raycast/{ray_case.name}/surface starts at zero`, function()
			local inward_point, inward_distance, inward_normal = ray_case.special(
				ray_case.surface,
				-ray_case.direction,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_start_hit(t, inward_point, inward_distance, inward_normal, ray_case.surface)

			local outward_point, outward_distance, outward_normal = ray_case.special(
				ray_case.surface,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_start_hit(t, outward_point, outward_distance, outward_normal, ray_case.surface)

			local zero_point, zero_distance, zero_normal = ray_case.special(
				ray_case.surface,
				Vector3.zero,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_start_hit(t, zero_point, zero_distance, zero_normal, ray_case.surface)

			local gjk_inward_point, gjk_inward_distance, gjk_inward_normal = bolt.gjk.raycast(
				ray_case.surface,
				-ray_case.direction,
				ray_case.cf,
				ray_case.shape,
				0
			)
			helpers.assert_start_hit(
				t,
				gjk_inward_point,
				gjk_inward_distance,
				gjk_inward_normal,
				ray_case.surface
			)

			local gjk_outward_point, gjk_outward_distance, gjk_outward_normal = bolt.gjk.raycast(
				ray_case.surface,
				ray_case.direction,
				ray_case.cf,
				ray_case.shape,
				0
			)
			helpers.assert_start_hit(
				t,
				gjk_outward_point,
				gjk_outward_distance,
				gjk_outward_normal,
				ray_case.surface
			)

			local gjk_zero_point, gjk_zero_distance, gjk_zero_normal = bolt.gjk.raycast(
				ray_case.surface,
				Vector3.zero,
				ray_case.cf,
				ray_case.shape,
				0
			)
			helpers.assert_start_hit(
				t,
				gjk_zero_point,
				gjk_zero_distance,
				gjk_zero_normal,
				ray_case.surface
			)
		end)

		t.test(`raycast/{ray_case.name}/zero direction outside misses`, function()
			helpers.assert_miss(t, ray_case.special(
				ray_case.origin,
				Vector3.zero,
				ray_case.cf,
				ray_case.shape
			))
			helpers.assert_miss(t, bolt.gjk.raycast(
				ray_case.origin,
				Vector3.zero,
				ray_case.cf,
				ray_case.shape,
				0
			))
		end)

		t.test(`raycast/{ray_case.name}/tangent hit`, function()
			local point, distance, normal = ray_case.special(
				ray_case.tangent_origin,
				ray_case.tangent_direction,
				ray_case.cf,
				ray_case.shape
			)
			helpers.assert_cast_hit(
				t,
				point,
				distance,
				normal,
				ray_case.tangent_origin,
				ray_case.tangent_direction,
				ray_case.tangent_distance
			)
		end)

		t.test(`raycast/{ray_case.name}/clear miss`, function()
			helpers.assert_miss(t, ray_case.special(
				ray_case.miss_origin,
				ray_case.miss_direction,
				ray_case.cf,
				ray_case.shape
			))
		end)
	end

	t.test("raycast/rotated box matches GJK", function()
		local shape = bolt.create_box(Vector3.new(2, 4, 2))
		local cf = CFrame.Angles(0, 0, math.pi / 2)
		local origin = Vector3.new(-4, 0, 0)
		local direction = Vector3.new(6, 0, 0)
		local _, special_distance = bolt.raycast.box(origin, direction, cf, shape)
		local _, gjk_distance = bolt.gjk.raycast(origin, direction, cf, shape, 0)
		t.near(t.non_nil(special_distance), 2)
		t.near(t.non_nil(gjk_distance), t.non_nil(special_distance))
	end)

	t.test("raycast/rotated capsule matches GJK", function()
		local shape = bolt.create_capsule(0.5, 2)
		local cf = CFrame.Angles(0, 0, math.pi / 2)
		local origin = Vector3.new(-2, 0, 0)
		local direction = Vector3.new(4, 0, 0)
		local _, special_distance = bolt.raycast.capsule(origin, direction, cf, shape)
		local _, gjk_distance = bolt.gjk.raycast(origin, direction, cf, shape, 0)
		t.near(t.non_nil(special_distance), 1.5)
		t.near(t.non_nil(gjk_distance), t.non_nil(special_distance))
	end)

	t.test("raycast/capsule/parallel ray just outside radius misses", function()
		local shape = bolt.create_capsule(0.5, 2)
		local origin = Vector3.new(-3, 0.5 + delta, 0)
		local direction = Vector3.new(6, 0, 0)

		helpers.assert_miss(t, bolt.raycast.capsule(origin, direction, CFrame.identity, shape))
		helpers.assert_miss(t, bolt.gjk.raycast(origin, direction, CFrame.identity, shape, 0))
	end)

	t.test("raycast/capsule/infinite cylinder hit beyond cap misses", function()
		local shape = bolt.create_capsule(0.5, 2)
		local origin = Vector3.new(2, -2, 0)
		local direction = Vector3.new(0, 4, 0)

		helpers.assert_miss(t, bolt.raycast.capsule(origin, direction, CFrame.identity, shape))
		helpers.assert_miss(t, bolt.gjk.raycast(origin, direction, CFrame.identity, shape, 0))
	end)
end