--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	t.test("mesh/synthetic hulls are independently queryable", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.1)

		local left = mesh.local_tree:query_shape(CFrame.new(-2, 0, 0), probe)
		local right = mesh.local_tree:query_shape(CFrame.new(2, 0, 0), probe)
		t.set_equal(left, {1})
		t.set_equal(right, {2})
	end)

	t.test("mesh/non-uniform creation scale affects hull offsets and bounds", function()
		local mesh = helpers.make_two_hull_mesh(bolt, Vector3.new(12, 2, 4))
		local probe = bolt.create_sphere(0.1)

		t.vector_near(mesh.hulls[1].scale, Vector3.new(2, 1, 2))
		t.set_equal(mesh.local_tree:query_shape(CFrame.new(-4, 0, 0), probe), {1})
		t.set_equal(mesh.local_tree:query_shape(CFrame.new(4, 0, 0), probe), {2})
		t.set_equal(mesh.local_tree:query_shape(CFrame.new(-2, 0, 0), probe), {})
	end)

	t.test("mesh/resize updates scale offsets and local tree", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.1)

		bolt.resize_mesh(mesh, Vector3.new(12, 4, 4))

		t.vector_near(mesh.hulls[1].scale, Vector3.new(2, 2, 2))
		t.vector_near(mesh.half_extents, Vector3.new(6, 2, 2))
		t.set_equal(mesh.local_tree:query_shape(CFrame.new(-4, 0, 0), probe), {1})
		t.set_equal(mesh.local_tree:query_shape(CFrame.new(4, 0, 0), probe), {2})
		t.set_equal(mesh.local_tree:query_shape(CFrame.new(-2, 0, 0), probe), {})
	end)

	--the margins guide tells anyone handling hulls by hand that one dispatched query brings the hulls
	--and the local tree in line, and that they agree from then on, these check that promise
	t.test("mesh/a synced margin reaches hulls handled by the user", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.1)

		mesh.margin = 0.5
		--the margin only reaches the hulls through dispatch, so one query has to happen first
		bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(80, 0, 0), probe, 1e-5)

		local function by_hand(at: CFrame): boolean
			for _, hull in mesh.hulls do
				local hull_cf = CFrame.new(hull.offset * hull.scale)
				if bolt.gjk.intersects(hull_cf, hull, at, probe, 1e-5) then
					return true
				end
			end
			return false
		end

		--the hull's top face is at 0.5, so with the probe and the margin contact holds out to 1.1
		t.truthy(by_hand(CFrame.new(2, 1.05, 0)))
		t.falsy(by_hand(CFrame.new(2, 1.15, 0)))
	end)

	t.test("mesh/a user handled local tree query matches dispatch", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.3)
		local mesh_cf = CFrame.new(1, 2, -3) * CFrame.Angles(0.4, 0.9, -0.2)

		mesh.margin = 0.5
		bolt.dispatch.gjk.intersects(mesh_cf, mesh, CFrame.new(80, 0, 0), probe, 1e-4)

		local random = Random.new(606)
		for _ = 1, 250 do
			local other_cf = mesh_cf * CFrame.new(random:NextNumber(-5, 5), random:NextNumber(-2, 2), random:NextNumber(-2, 2))

			--the same culling loop the meshes guide shows
			local in_mesh = mesh_cf:ToObjectSpace(other_cf)
			local by_hand = false
			for _, hull_id in mesh.local_tree:query_shape(in_mesh, probe) do
				local hull = mesh.hulls[hull_id]
				local hull_cf = mesh_cf * CFrame.new(hull.offset * hull.scale)
				if bolt.gjk.intersects(hull_cf, hull, other_cf, probe, 1e-4) then
					by_hand = true
				end
			end

			t.equal(by_hand, bolt.dispatch.gjk.intersects(mesh_cf, mesh, other_cf, probe, 1e-4))
		end
	end)

	t.test("mesh/dispatch GJK intersects scaled hull in both argument orders", function()
		local mesh = helpers.make_two_hull_mesh(bolt, Vector3.new(12, 2, 4))
		local sphere = bolt.create_sphere(0.25)
		local sphere_cf = CFrame.new(-4, 0, 0)

		t.truthy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, sphere_cf, sphere, 0))
		t.truthy(bolt.dispatch.gjk.intersects(sphere_cf, sphere, CFrame.identity, mesh, 0))
		t.falsy(bolt.dispatch.gjk.intersects(
			CFrame.identity,
			mesh,
			CFrame.new(0, 5, 0),
			sphere,
			0
		))
	end)

	t.test("mesh/dispatch raycast chooses nearest hull", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local origin = Vector3.new(-5, 0, 0)
		local direction = Vector3.new(10, 0, 0)
		local point, distance, normal = bolt.dispatch.gjk.raycast(
			origin,
			direction,
			CFrame.identity,
			mesh,
			0
		)

		helpers.assert_cast_hit(t, point, distance, normal, origin, direction, 2.5)
		t.vector_near(t.non_nil(point), Vector3.new(-2.5, 0, 0), 1e-4)
	end)

	t.test("mesh/dispatch full and simple shapecast choose nearest hull", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local sphere = bolt.create_sphere(0.5)
		local start = CFrame.new(-5, 0, 0)
		local direction = Vector3.new(10, 0, 0)

		local simple_hit, simple_distance = bolt.dispatch.gjk.shapecast_simple(
			start,
			direction,
			sphere,
			CFrame.identity,
			mesh,
			0
		)
		local point, distance, normal = bolt.dispatch.gjk.shapecast(
			start,
			direction,
			sphere,
			CFrame.identity,
			mesh,
			0
		)

		t.truthy(simple_hit)
		t.near(t.non_nil(simple_distance), 2, 1e-4)
		t.near(t.non_nil(distance), t.non_nil(simple_distance), 1e-4)
		t.vector_finite(t.non_nil(point))
		t.vector_finite(t.non_nil(normal))
	end)

	t.test("mesh/dispatch moving mesh shapecast uses the nearest hull", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local sphere = bolt.create_sphere(0.5)
		local target_cf = CFrame.new(5, 0, 0)
		local direction = Vector3.new(4, 0, 0)

		local simple_hit, simple_distance = bolt.dispatch.gjk.shapecast_simple(
			CFrame.identity,
			direction,
			mesh,
			target_cf,
			sphere,
			0
		)
		local point, distance, normal = bolt.dispatch.gjk.shapecast(
			CFrame.identity,
			direction,
			mesh,
			target_cf,
			sphere,
			0
		)

		t.truthy(simple_hit)
		t.near(t.non_nil(simple_distance), 2, 1e-4)
		t.near(t.non_nil(distance), t.non_nil(simple_distance), 1e-4)
		t.vector_finite(t.non_nil(point))
		t.vector_finite(t.non_nil(normal))
	end)

	t.test("mesh/dispatch transformed non-uniform mesh keeps cast distances", function()
		local mesh = helpers.make_two_hull_mesh(bolt, Vector3.new(12, 4, 2))
		local mesh_cf = CFrame.new(3, 1, -2) * CFrame.fromOrientation(0.2, 0.5, -0.3)
		local local_origin = Vector3.new(-10, 0, 0)
		local ray_origin = mesh_cf:PointToWorldSpace(local_origin)
		local direction = mesh_cf:VectorToWorldSpace(Vector3.new(20, 0, 0))

		local ray_point, ray_distance, ray_normal = bolt.dispatch.gjk.raycast(
			ray_origin,
			direction,
			mesh_cf,
			mesh,
			0
		)
		helpers.assert_cast_hit(
			t,
			ray_point,
			ray_distance,
			ray_normal,
			ray_origin,
			direction,
			5
		)

		local sphere = bolt.create_sphere(0.5)
		local start = CFrame.new(ray_origin)
		local simple_hit, simple_distance = bolt.dispatch.gjk.shapecast_simple(
			start,
			direction,
			sphere,
			mesh_cf,
			mesh,
			0
		)
		local point, distance, normal = bolt.dispatch.gjk.shapecast(
			start,
			direction,
			sphere,
			mesh_cf,
			mesh,
			0
		)
		t.truthy(simple_hit)
		t.near(t.non_nil(simple_distance), 4.5, 1e-3)
		t.near(t.non_nil(distance), 4.5, 1e-3)
		t.vector_finite(t.non_nil(point))
		helpers.assert_unit_vector(t, t.non_nil(normal), 1e-3)
	end)

	t.test("mesh/dispatch mesh-mesh shapecast covers both moving orders", function()
		local mesh_a = helpers.make_two_hull_mesh(bolt)
		local mesh_b = helpers.make_two_hull_mesh(bolt)
		local cf_a = CFrame.new(-8, 0, 0)
		local cf_b = CFrame.identity

		local simple_hit_ab, simple_distance_ab = bolt.dispatch.gjk.shapecast_simple(
			cf_a,
			Vector3.new(10, 0, 0),
			mesh_a,
			cf_b,
			mesh_b,
			0
		)
		local point_ab, distance_ab, normal_ab = bolt.dispatch.gjk.shapecast(
			cf_a,
			Vector3.new(10, 0, 0),
			mesh_a,
			cf_b,
			mesh_b,
			0
		)
		t.truthy(simple_hit_ab)
		t.near(t.non_nil(simple_distance_ab), 3, 1e-3)
		t.near(t.non_nil(distance_ab), 3, 1e-3)
		t.vector_finite(t.non_nil(point_ab))
		helpers.assert_unit_vector(t, t.non_nil(normal_ab), 1e-3)

		local simple_hit_ba, simple_distance_ba = bolt.dispatch.gjk.shapecast_simple(
			cf_b,
			Vector3.new(-10, 0, 0),
			mesh_b,
			cf_a,
			mesh_a,
			0
		)
		local point_ba, distance_ba, normal_ba = bolt.dispatch.gjk.shapecast(
			cf_b,
			Vector3.new(-10, 0, 0),
			mesh_b,
			cf_a,
			mesh_a,
			0
		)
		t.truthy(simple_hit_ba)
		t.near(t.non_nil(simple_distance_ba), 3, 1e-3)
		t.near(t.non_nil(distance_ba), 3, 1e-3)
		t.vector_finite(t.non_nil(point_ba))
		helpers.assert_unit_vector(t, t.non_nil(normal_ba), 1e-3)
	end)

	t.test("mesh/dispatch mesh-mesh GJK detects overlap and separation", function()
		local mesh_a = helpers.make_two_hull_mesh(bolt)
		local mesh_b = helpers.make_two_hull_mesh(bolt)

		t.truthy(bolt.dispatch.gjk.intersects(
			CFrame.identity,
			mesh_a,
			CFrame.new(0, 0, 0.25),
			mesh_b,
			0
		))
		t.falsy(bolt.dispatch.gjk.intersects(
			CFrame.identity,
			mesh_a,
			CFrame.new(0, 5, 0),
			mesh_b,
			0
		))
	end)

	t.test("mesh/MPR primitive dispatch assigns IDs to the mesh argument", function()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local sphere = bolt.create_sphere(0.75)
		--keep the overlap off-center so the minimum-penetration normal is unique
		--a concentric sphere and box can legitimately choose different, equally valid normals when the arguments are swapped
		local sphere_cf = CFrame.new(-2.4, 0, 0)

		local mesh_first = bolt.dispatch.mpr.mesh_primitive(
			CFrame.identity,
			mesh,
			sphere_cf,
			sphere,
			1e-6
		)
		local primitive_first = bolt.dispatch.mpr.mesh_primitive(
			sphere_cf,
			sphere,
			CFrame.identity,
			mesh,
			1e-6
		)

		t.equal(#mesh_first, 1)
		t.equal(#primitive_first, 1)

		local mesh_contact = mesh_first[1]
		local primitive_contact = primitive_first[1]
		t.equal(mesh_contact.hull_a_id, 1)
		t.is_nil(mesh_contact.hull_b_id)
		t.is_nil(primitive_contact.hull_a_id)
		t.equal(primitive_contact.hull_b_id, 1)
		t.near(mesh_contact.depth, primitive_contact.depth, 1e-4)
		t.vector_near(mesh_contact.normal, -primitive_contact.normal, 1e-4)
		t.vector_near(mesh_contact.point_a, primitive_contact.point_b, 1e-4)
		t.vector_near(mesh_contact.point_b, primitive_contact.point_a, 1e-4)
	end)

	t.test("mesh/MPR mesh-mesh reports actual hull pairs", function()
		local mesh_a = helpers.make_two_hull_mesh(bolt)
		local mesh_b = helpers.make_two_hull_mesh(bolt)
		local contacts = bolt.dispatch.mpr.mesh_mesh(
			CFrame.identity,
			mesh_a,
			CFrame.new(0, 0, 0.25),
			mesh_b,
			1e-6
		)

		local pairs = {}
		for _, contact in contacts do
			table.insert(pairs, helpers.pair_key(contact.hull_a_id, contact.hull_b_id))
			t.finite(contact.depth)
			t.vector_finite(contact.normal)
			t.vector_finite(contact.point_a)
			t.vector_finite(contact.point_b)
		end

		t.set_equal(pairs, {"1:1", "2:2"})
	end)
end