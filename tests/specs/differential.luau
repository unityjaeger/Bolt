--!strict

local helpers = require(script.Parent.Parent.helpers)

local SEED = 10000

return function(t: any, bolt: any)
	local box = bolt.create_box(Vector3.new(2, 1.5, 2.5))
	local sphere = bolt.create_sphere(0.9)
	local capsule = bolt.create_capsule(0.6, 2.2)

	local primitive_pairs = {
		{
			name = "box_box",
			shape_a = box,
			shape_b = box,
			special = bolt.collision.box_box,
		},
		{
			name = "box_sphere",
			shape_a = box,
			shape_b = sphere,
			special = bolt.collision.box_sphere,
		},
		{
			name = "box_capsule",
			shape_a = box,
			shape_b = capsule,
			special = bolt.collision.box_capsule,
		},
		{
			name = "sphere_sphere",
			shape_a = sphere,
			shape_b = sphere,
			special = bolt.collision.sphere_sphere,
		},
		{
			name = "sphere_capsule",
			shape_a = sphere,
			shape_b = capsule,
			special = bolt.collision.sphere_capsule,
		},
		{
			name = "capsule_capsule",
			shape_a = capsule,
			shape_b = capsule,
			special = bolt.collision.capsule_capsule,
		},
	}

	t.test("differential/random special collisions agree with GJK", function()
		local random = Random.new(SEED)

		for _, pair in primitive_pairs do
			for iteration = 1, 75 do
				local cf_a = helpers.random_cframe(random, 2.5)
				local cf_b = helpers.random_cframe(random, 2.5)
				local expected = pair.special(cf_a, pair.shape_a, cf_b, pair.shape_b)
				local actual = bolt.gjk.intersects(cf_a, pair.shape_a, cf_b, pair.shape_b, 0)
				t.equal(
					actual,
					expected,
					`seed {SEED}, pair {pair.name}, iteration {iteration}, A {cf_a}, B {cf_b}`
				)
			end
		end
	end)

	t.test("differential/random box SAT agrees with special collision", function()
		local random = Random.new(SEED + 1)

		for iteration = 1, 250 do
			local cf_a = helpers.random_cframe(random, 2.5)
			local cf_b = helpers.random_cframe(random, 2.5)
			local expected = bolt.collision.box_box(cf_a, box, cf_b, box)
			local actual = bolt.sat.box_box(cf_a, box, cf_b, box)
			t.equal(
				actual,
				expected,
				`seed {SEED + 1}, iteration {iteration}, A {cf_a}, B {cf_b}`
			)
		end
	end)

	t.test("differential/random SAT pairs agree with reference queries", function()
		local random = Random.new(SEED + 5)
		local sat_box = bolt.create_box(Vector3.new(2, 1.5, 2.5))
		local wedge = bolt.create_wedge(Vector3.new(2, 1.5, 2.5))
		local corner = bolt.create_corner_wedge(Vector3.new(2, 1.5, 2.5))
		local sat_pairs = {
			{
				name = "box_box",
				collide = bolt.sat.box_box,
				reference = bolt.collision.box_box,
				a = sat_box,
				b = sat_box,
			},
			{name = "box_wedge", collide = bolt.sat.box_wedge, a = sat_box, b = wedge},
			{name = "wedge_wedge", collide = bolt.sat.wedge_wedge, a = wedge, b = wedge},
			{
				name = "wedge_corner_wedge",
				collide = bolt.sat.wedge_corner_wedge,
				a = wedge,
				b = corner,
			},
			{
				name = "box_corner_wedge",
				collide = bolt.sat.box_corner_wedge,
				a = sat_box,
				b = corner,
			},
			{
				name = "corner_wedge_corner_wedge",
				collide = bolt.sat.corner_wedge_corner_wedge,
				a = corner,
				b = corner,
			},
		}

		for _, pair in sat_pairs do
			for iteration = 1, 60 do
				local cf_a = helpers.random_cframe(random, 2.5)
				local cf_b = helpers.random_cframe(random, 2.5)
				local actual = pair.collide(cf_a, pair.a, cf_b, pair.b)
				local gjk_hit = bolt.gjk.intersects(cf_a, pair.a, cf_b, pair.b, 0)

				if actual ~= gjk_hit then
					--static GJK deliberately accepts separations below its relative machine-precision floor
					--adjudicate disagreements with the analytic OBB query where available and MPR for other hulls
					local reference_hit = if pair.reference ~= nil
						then pair.reference(cf_a, pair.a, cf_b, pair.b)
						else bolt.mpr.intersects(cf_a, pair.a, cf_b, pair.b, 0)
					t.equal(
						actual,
						reference_hit,
						`seed {SEED + 5}, pair {pair.name}, iteration {iteration}, GJK {gjk_hit}, A {cf_a}, B {cf_b}`
					)
				end
			end
		end
	end)

	t.test("differential/random MPR agrees with analytic sphere collision", function()
		local random = Random.new(SEED + 2)

		for iteration = 1, 100 do
			local cf_a = CFrame.new(
				random:NextNumber(-3, 3),
				random:NextNumber(-3, 3),
				random:NextNumber(-3, 3)
			)
			local cf_b = CFrame.new(
				random:NextNumber(-3, 3),
				random:NextNumber(-3, 3),
				random:NextNumber(-3, 3)
			)
			local expected = bolt.collision.sphere_sphere(cf_a, sphere, cf_b, sphere)
			local actual = bolt.mpr.intersects(cf_a, sphere, cf_b, sphere, 1e-6)
			t.equal(
				actual,
				expected,
				`seed {SEED + 2}, iteration {iteration}, A {cf_a.Position}, B {cf_b.Position}`
			)
		end
	end)

	t.test("differential/random full and simple shapecasts agree", function()
		local random = Random.new(SEED + 3)
		local shapes = {box, sphere, capsule}

		for iteration = 1, 150 do
			local shape_a = shapes[random:NextInteger(1, #shapes)]
			local shape_b = shapes[random:NextInteger(1, #shapes)]
			local cf_a = helpers.random_cframe(random, 4)
			local cf_b = helpers.random_cframe(random, 4)
			local direction = Vector3.new(
				random:NextNumber(-5, 5),
				random:NextNumber(-5, 5),
				random:NextNumber(-5, 5)
			)

			local simple_hit, simple_distance = bolt.gjk.shapecast_simple(
				cf_a,
				direction,
				shape_a,
				cf_b,
				shape_b,
				0
			)
			local point, distance, normal = bolt.gjk.shapecast(
				cf_a,
				direction,
				shape_a,
				cf_b,
				shape_b,
				0
			)
			local full_hit = point ~= nil

			t.equal(
				full_hit,
				simple_hit,
				`seed {SEED + 3}, iteration {iteration}, A {cf_a}, B {cf_b}, direction {direction}`
			)

			if simple_hit then
				t.near(
					t.non_nil(distance),
					t.non_nil(simple_distance),
					1e-4,
					`seed {SEED + 3}, iteration {iteration}`
				)
				t.vector_finite(t.non_nil(point))
				t.vector_finite(t.non_nil(normal))
			else
				t.is_nil(distance)
				t.is_nil(normal)
			end
		end
	end)

	t.test("differential/random special rays agree with GJK", function()
		local random = Random.new(SEED + 6)
		local ray_shapes = {
			{name = "box", shape = box, cast = bolt.raycast.box},
			{name = "sphere", shape = sphere, cast = bolt.raycast.sphere},
			{name = "capsule", shape = capsule, cast = bolt.raycast.capsule},
		}

		for _, entry in ray_shapes do
			for iteration = 1, 125 do
				local cf = helpers.random_cframe(random, 3)
				local origin = Vector3.new(
					random:NextNumber(-6, 6),
					random:NextNumber(-6, 6),
					random:NextNumber(-6, 6)
				)
				local direction = Vector3.new(
					random:NextNumber(-8, 8),
					random:NextNumber(-8, 8),
					random:NextNumber(-8, 8)
				)

				local special_point, special_distance = entry.cast(origin, direction, cf, entry.shape)
				local gjk_point, gjk_distance = bolt.gjk.raycast(origin, direction, cf, entry.shape, 0)
				local special_hit = special_point ~= nil
				local gjk_hit = gjk_point ~= nil
				local message =
					`seed {SEED + 6}, shape {entry.name}, iteration {iteration}, cf {cf}, origin {origin}, direction {direction}`

				t.equal(gjk_hit, special_hit, message)
				if special_hit then
					t.near(t.non_nil(gjk_distance), t.non_nil(special_distance), 1e-4, message)
				else
					t.is_nil(gjk_distance, message)
					t.is_nil(special_distance, message)
				end
			end
		end
	end)

	t.test("differential/random broad phase has no false negatives", function()
		local random = Random.new(SEED + 4)
		local target_shapes = {
			bolt.create_box(Vector3.new(2, 3, 1.5)),
			bolt.create_sphere(1),
			bolt.create_ellipsoid(Vector3.new(2, 3, 4)),
			bolt.create_capsule(0.6, 2),
			bolt.create_cylinder(1, 2),
			bolt.create_wedge(Vector3.new(2, 2, 2)),
			bolt.create_corner_wedge(Vector3.new(2, 2, 2)),
		}
		local records = {}
		local tree = bolt.aabb_tree.new_static()

		for id, target_shape in target_shapes do
			local cf = helpers.random_cframe(random, 5)
			records[id] = {shape = target_shape, cf = cf}
			tree:insert(id, cf, target_shape)
		end
		tree:full_rebuild()

		for iteration = 1, 75 do
			local query_shape = primitive_pairs[random:NextInteger(1, #primitive_pairs)].shape_a
			local query_cf = helpers.random_cframe(random, 6)
			local shape_candidates = tree:query_shape(query_cf, query_shape)

			local ray_origin = Vector3.new(
				random:NextNumber(-8, 8),
				random:NextNumber(-8, 8),
				random:NextNumber(-8, 8)
			)
			local ray_direction = Vector3.new(
				random:NextNumber(-10, 10),
				random:NextNumber(-10, 10),
				random:NextNumber(-10, 10)
			)
			local ray_candidates = tree:query_ray(ray_origin, ray_direction)
			local cast_candidates = tree:query_shapecast(query_shape, query_cf, ray_direction)

			for id, record in records do
				if bolt.gjk.intersects(query_cf, query_shape, record.cf, record.shape, 0) then
					t.contains(
						shape_candidates,
						id,
						`shape query false negative: seed {SEED + 4}, iteration {iteration}, id {id}`
					)
				end

				local ray_point = bolt.gjk.raycast(
					ray_origin,
					ray_direction,
					record.cf,
					record.shape,
					0
				)
				if ray_point ~= nil then
					t.contains(
						ray_candidates,
						id,
						`ray query false negative: seed {SEED + 4}, iteration {iteration}, id {id}`
					)
				end

				local cast_hit = bolt.gjk.shapecast_simple(
					query_cf,
					ray_direction,
					query_shape,
					record.cf,
					record.shape,
					0
				)
				if cast_hit then
					t.contains(
						cast_candidates,
						id,
						`shapecast query false negative: seed {SEED + 4}, iteration {iteration}, id {id}`
					)
				end
			end
		end
	end)
end