--!strict

local Lest = require('@lest')
local describe, it = Lest.describe, Lest.it

local bolt = require('../../src')
local check = require('../check')
local helpers = require('../helpers')

describe('mesh', function ()
	it('synthetic hulls are independently queryable', function ()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.1)

		local left = mesh.local_tree:query_shape(CFrame.new(-2, 0, 0), probe)
		local right = mesh.local_tree:query_shape(CFrame.new(2, 0, 0), probe)
		check.set_equal(left, {1})
		check.set_equal(right, {2})
	end)


	it('non-uniform creation scale affects hull offsets and bounds', function ()
		local mesh = helpers.make_two_hull_mesh(bolt, Vector3.new(12, 2, 4))
		local probe = bolt.create_sphere(0.1)

		check.vector_near((mesh.children[1].shape :: any).scale, Vector3.new(2, 1, 2))
		check.set_equal(mesh.local_tree:query_shape(CFrame.new(-4, 0, 0), probe), {1})
		check.set_equal(mesh.local_tree:query_shape(CFrame.new(4, 0, 0), probe), {2})
		check.set_equal(mesh.local_tree:query_shape(CFrame.new(-2, 0, 0), probe), {})
	end)


	it('resize updates scale offsets and local tree', function ()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.1)

		bolt.resize_mesh(mesh, Vector3.new(12, 4, 4))

		check.vector_near((mesh.children[1].shape :: any).scale, Vector3.new(2, 2, 2))
		--a composite has no declared size, its extent is whatever its children reach
		check.vector_near(mesh.children[2].cf.Position, Vector3.new(4, 0, 0))
		check.set_equal(mesh.local_tree:query_shape(CFrame.new(-4, 0, 0), probe), {1})
		check.set_equal(mesh.local_tree:query_shape(CFrame.new(4, 0, 0), probe), {2})
		check.set_equal(mesh.local_tree:query_shape(CFrame.new(-2, 0, 0), probe), {})
	end)


	--the margins guide tells anyone handling hulls by hand that one dispatched query brings the hulls
	--and the local tree in line, and that they agree from then on, these check that promise
	it('a synced margin reaches hulls handled by the user', function ()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local probe = bolt.create_sphere(0.1)

		mesh.margin = 0.5
		--the margin only reaches the hulls through dispatch, so one query has to happen first
		bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(80, 0, 0), probe, 1e-5)

		local function by_hand(at: CFrame): boolean
			for _, child in mesh.children do
				if bolt.gjk.intersects(child.cf, child.shape, at, probe, 1e-5) then
					return true
				end
			end
			return false
		end

		--the hull's top face is at 0.5, so with the probe and the margin contact holds out to 1.1
		check.truthy(by_hand(CFrame.new(2, 1.05, 0)))
		check.falsy(by_hand(CFrame.new(2, 1.15, 0)))
	end)


	it('a user handled local tree query matches dispatch', function ()
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
				local child = mesh.children[hull_id]
				if bolt.gjk.intersects(mesh_cf * child.cf, child.shape, other_cf, probe, 1e-4) then
					by_hand = true
				end
			end

			check.equal(by_hand, bolt.dispatch.gjk.intersects(mesh_cf, mesh, other_cf, probe, 1e-4))
		end
	end)


	it('dispatch GJK intersects scaled hull in both argument orders', function ()
		local mesh = helpers.make_two_hull_mesh(bolt, Vector3.new(12, 2, 4))
		local sphere = bolt.create_sphere(0.25)
		local sphere_cf = CFrame.new(-4, 0, 0)

		check.truthy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, sphere_cf, sphere, 0))
		check.truthy(bolt.dispatch.gjk.intersects(sphere_cf, sphere, CFrame.identity, mesh, 0))
		check.falsy(bolt.dispatch.gjk.intersects(
			CFrame.identity,
			mesh,
			CFrame.new(0, 5, 0),
			sphere,
			0
		))
	end)


	it('dispatch raycast chooses nearest hull', function ()
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

		helpers.assert_cast_hit(point, distance, normal, origin, direction, 2.5)
		check.vector_near(check.non_nil(point), Vector3.new(-2.5, 0, 0), 1e-4)
	end)


	it('dispatch full and simple shapecast choose nearest hull', function ()
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

		check.truthy(simple_hit)
		check.near(check.non_nil(simple_distance), 2, 1e-4)
		check.near(check.non_nil(distance), check.non_nil(simple_distance), 1e-4)
		check.vector_finite(check.non_nil(point))
		check.vector_finite(check.non_nil(normal))
	end)


	it('dispatch moving mesh shapecast uses the nearest hull', function ()
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

		check.truthy(simple_hit)
		check.near(check.non_nil(simple_distance), 2, 1e-4)
		check.near(check.non_nil(distance), check.non_nil(simple_distance), 1e-4)
		check.vector_finite(check.non_nil(point))
		check.vector_finite(check.non_nil(normal))
	end)


	it('dispatch transformed non-uniform mesh keeps cast distances', function ()
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
		helpers.assert_cast_hit(ray_point,
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
		check.truthy(simple_hit)
		check.near(check.non_nil(simple_distance), 4.5, 1e-3)
		check.near(check.non_nil(distance), 4.5, 1e-3)
		check.vector_finite(check.non_nil(point))
		helpers.assert_unit_vector(check.non_nil(normal), 1e-3)
	end)


	it('dispatch mesh-mesh shapecast covers both moving orders', function ()
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
		check.truthy(simple_hit_ab)
		check.near(check.non_nil(simple_distance_ab), 3, 1e-3)
		check.near(check.non_nil(distance_ab), 3, 1e-3)
		check.vector_finite(check.non_nil(point_ab))
		helpers.assert_unit_vector(check.non_nil(normal_ab), 1e-3)

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
		check.truthy(simple_hit_ba)
		check.near(check.non_nil(simple_distance_ba), 3, 1e-3)
		check.near(check.non_nil(distance_ba), 3, 1e-3)
		check.vector_finite(check.non_nil(point_ba))
		helpers.assert_unit_vector(check.non_nil(normal_ba), 1e-3)
	end)


	it('dispatch mesh-mesh GJK detects overlap and separation', function ()
		local mesh_a = helpers.make_two_hull_mesh(bolt)
		local mesh_b = helpers.make_two_hull_mesh(bolt)

		check.truthy(bolt.dispatch.gjk.intersects(
			CFrame.identity,
			mesh_a,
			CFrame.new(0, 0, 0.25),
			mesh_b,
			0
		))
		check.falsy(bolt.dispatch.gjk.intersects(
			CFrame.identity,
			mesh_a,
			CFrame.new(0, 5, 0),
			mesh_b,
			0
		))
	end)


	it('MPR primitive dispatch assigns IDs to the mesh argument', function ()
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

		check.equal(#mesh_first, 1)
		check.equal(#primitive_first, 1)

		local mesh_contact = mesh_first[1]
		local primitive_contact = primitive_first[1]
		check.equal(mesh_contact.child_a_id, 1)
		check.is_nil(mesh_contact.child_b_id)
		check.is_nil(primitive_contact.child_a_id)
		check.equal(primitive_contact.child_b_id, 1)
		check.near(mesh_contact.depth, primitive_contact.depth, 1e-4)
		check.vector_near(mesh_contact.normal, -primitive_contact.normal, 1e-4)
		check.vector_near(mesh_contact.point_a, primitive_contact.point_b, 1e-4)
		check.vector_near(mesh_contact.point_b, primitive_contact.point_a, 1e-4)
	end)


	it('MPR mesh-mesh reports actual hull pairs', function ()
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
			table.insert(pairs, helpers.pair_key(contact.child_a_id, contact.child_b_id))
			check.finite(contact.depth)
			check.vector_finite(contact.normal)
			check.vector_finite(contact.point_a)
			check.vector_finite(contact.point_b)
		end

		check.set_equal(pairs, {"1:1", "2:2"})
	end)

end)

return nil