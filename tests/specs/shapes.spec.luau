--!strict

local Lest = require('@lest')
local describe, it = Lest.describe, Lest.it

local bolt = require('../../src')
local check = require('../check')
local helpers = require('../helpers')

local function unit_cube_hull_info(): any
	--a 1x1x1 hull, so a creation size of n scales it to an n sided cube
	local unit = helpers.make_box_hull(Vector3.zero, Vector3.new(0.5, 0.5, 0.5))
	return {
		vertices = unit.vertices,
		adjacency = unit.adjacency,
		size = Vector3.new(1, 1, 1),
	}
end

--inflating a convex shape by m is exactly support(dir) + m * normalize(dir), so a point
--inflated by r is a sphere of radius r

--that makes this the sharpest check available, if the
--margin were applied with the wrong sign or in the wrong frame, these would diverge
describe('shapes', function ()
	describe('margin', function ()
		it('an inflated point is a sphere', function ()
			local radius = 1.7
			local inflated_point = bolt.create_box(Vector3.zero)
			inflated_point.margin = radius

			local real_sphere = bolt.create_sphere(radius)
			local target = bolt.create_box(Vector3.new(4, 4, 4))
			local random = Random.new(2024)

			for _ = 1, 120 do
				local cf = CFrame.new(random:NextNumber(-6, 6), random:NextNumber(-6, 6), random:NextNumber(-6, 6))
				local probe = CFrame.new(random:NextNumber(-6, 6), random:NextNumber(-6, 6), random:NextNumber(-6, 6))
				local direction = Vector3.new(random:NextNumber(-10, 10), random:NextNumber(-10, 10), random:NextNumber(-10, 10))

				check.equal(
					bolt.gjk.intersects(cf, inflated_point, probe, target, 1e-5),
					bolt.gjk.intersects(cf, real_sphere, probe, target, 1e-5)
				)

				local _, inflated_distance = bolt.gjk.raycast(Vector3.zero, direction, cf, inflated_point, 1e-5)
				local _, sphere_distance = bolt.gjk.raycast(Vector3.zero, direction, cf, real_sphere, 1e-5)
				check.equal(inflated_distance == nil, sphere_distance == nil)
				if inflated_distance and sphere_distance then
					check.near(inflated_distance, sphere_distance, 1e-3)
				end
			end
		end)


		it('moves the surface outward by exactly the margin', function ()
			local plain = bolt.create_box(Vector3.new(2, 2, 2))
			local origin = Vector3.new(-10, 0, 0)
			local direction = Vector3.new(20, 0, 0)

			local _, plain_distance = bolt.gjk.raycast(origin, direction, CFrame.identity, plain, 1e-5)

			for _, margin in {0.05, 0.25, 1} do
				local margined = bolt.create_box(Vector3.new(2, 2, 2))
				margined.margin = margin

				local _, margined_distance = bolt.gjk.raycast(origin, direction, CFrame.identity, margined, 1e-5)
				check.near(check.non_nil(plain_distance) - check.non_nil(margined_distance), margin, 1e-3, `margin {margin}`)
			end
		end)


		it('applies to hulls, which cannot be scaled instead', function ()
			local plain = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))
			local margined = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))
			margined.margin = 0.3

			local origin = Vector3.new(-10, 0, 0)
			local direction = Vector3.new(20, 0, 0)

			local _, plain_distance = bolt.gjk.raycast(origin, direction, CFrame.identity, plain, 1e-5)
			local _, margined_distance = bolt.gjk.raycast(origin, direction, CFrame.identity, margined, 1e-5)

			check.near(check.non_nil(plain_distance) - check.non_nil(margined_distance), 0.3, 1e-3)
		end)


		it('counts toward penetration depth', function ()
			local margined = bolt.create_box(Vector3.new(2, 2, 2))
			margined.margin = 0.2
			local plain = bolt.create_box(Vector3.new(2, 2, 2))

			--centers 2.1 apart leaves plain boxes 0.1 short of touching, the margin closes that and overlaps by 0.1
			local hit, _, depth = bolt.mpr.intersects(CFrame.identity, margined, CFrame.new(2.1, 0, 0), plain, 1e-5)
			check.truthy(hit)
			check.near(check.non_nil(depth), 0.1, 1e-3)

			check.falsy(bolt.mpr.intersects(CFrame.identity, plain, CFrame.new(2.1, 0, 0), plain, 1e-5))
		end)


		--a broad phase that does not know about the margin would filter out contacts the narrow phase
		--would then have found, which shows up as collisions that only fail at certain positions
		it('widens the tree bounds to match', function ()
			local plain = bolt.create_box(Vector3.new(2, 2, 2))
			local margined = bolt.create_box(Vector3.new(2, 2, 2))
			margined.margin = 0.5

			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, plain)
			tree:insert(2, CFrame.identity, margined)
			tree:full_rebuild()

			--past the plain box's face at 1, inside the margined one's at 1.5
			local probe = Vector3.new(1.25, 0, 0)
			check.not_contains(tree:query_aabb(probe, probe), 1)
			check.contains(tree:query_aabb(probe, probe), 2)
		end)


		--a tree reads a shape's size on insert and never again, so a margin raised afterwards leaves the
		--bounds too small and the shape stops being offered as a candidate

		--this is the documented reason a margin change needs the same resize call a mesh does
		it('raising a margin after insertion needs a tree resize', function ()
			local shape = bolt.create_box(Vector3.new(2, 2, 2))

			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert(1, CFrame.identity, shape)

			--past the raw box's face at 1, inside the margined surface at 1.5
			local probe = Vector3.new(1.25, 0, 0)
			shape.margin = 0.5
			check.not_contains(tree:query_aabb(probe, probe), 1)

			tree:resize(1, shape)
			check.contains(tree:query_aabb(probe, probe), 1)
		end)


		--a static tree has no resize, so the proxy has to go back in
		it('a static tree takes a raised margin through reinsertion', function ()
			local shape = bolt.create_box(Vector3.new(2, 2, 2))

			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, shape)
			tree:full_rebuild()

			local probe = Vector3.new(1.25, 0, 0)
			shape.margin = 0.5
			check.not_contains(tree:query_aabb(probe, probe), 1)

			tree:remove(1)
			tree:insert(1, CFrame.identity, shape)
			tree:full_rebuild()
			check.contains(tree:query_aabb(probe, probe), 1)
		end)


		--deflation is only exact on shapes a smaller constructor already covers, so a negative margin is not supported

		--what matters is that it fails in one predictable way instead of pulling the
		--broad phase and the narrow phase apart, which would show up as contacts that drop out by position
		it('a negative margin is ignored everywhere', function ()
			local plain = bolt.create_box(Vector3.new(2, 2, 2))
			local negative = bolt.create_box(Vector3.new(2, 2, 2))
			negative.margin = -0.3

			local target = bolt.create_capsule(0.4, 1.5)
			local random = Random.new(4242)

			for _ = 1, 150 do
				local cf = CFrame.new(random:NextNumber(-5, 5), random:NextNumber(-5, 5), random:NextNumber(-5, 5))
				local probe = CFrame.new(random:NextNumber(-5, 5), random:NextNumber(-5, 5), random:NextNumber(-5, 5))

				check.equal(
					bolt.gjk.intersects(cf, negative, probe, target, 1e-5),
					bolt.gjk.intersects(cf, plain, probe, target, 1e-5)
				)
				check.equal(
					(bolt.mpr.intersects(cf, negative, probe, target, 1e-5)),
					(bolt.mpr.intersects(cf, plain, probe, target, 1e-5))
				)
			end

			--and the tree keeps the same bounds it would have given the shape without one
			local tree = bolt.aabb_tree.new_static()
			tree:insert(1, CFrame.identity, plain)
			tree:insert(2, CFrame.identity, negative)
			tree:full_rebuild()

			--inside both boxes, but outside where a shrunken one would have ended
			local probe = Vector3.new(0.85, 0, 0)
			check.contains(tree:query_aabb(probe, probe), 1)
			check.contains(tree:query_aabb(probe, probe), 2)
		end)


		--the case above only pairs a negative margin with a shape that has none, 
		--where every sum stays negative and the guards skip anyway

		--a positive margin on the other shape is what tells apart
		--dropping the negative from letting it cancel part of the positive one
		it("a negative margin does not eat into the other shape's", function ()
			local target_negative = bolt.create_capsule(0.4, 1.5)
			local target_plain = bolt.create_capsule(0.4, 1.5)
			target_negative.margin = -0.5
			target_plain.margin = nil

			local margined_a = bolt.create_box(Vector3.new(2, 2, 2))
			local margined_b = bolt.create_box(Vector3.new(2, 2, 2))
			margined_a.margin = 0.5
			margined_b.margin = 0.5

			local random = Random.new(4242)

			for _ = 1, 200 do
				--kept close together so most placements land near contact, where the sign actually shows
				local cf = CFrame.new(random:NextNumber(-2.5, 2.5), random:NextNumber(-2.5, 2.5), random:NextNumber(-2.5, 2.5))
				local probe = CFrame.new(random:NextNumber(-2.5, 2.5), random:NextNumber(-2.5, 2.5), random:NextNumber(-2.5, 2.5))
				local direction = Vector3.new(random:NextNumber(-5, 5), random:NextNumber(-5, 5), random:NextNumber(-5, 5))

				--the box keeps its full 0.5 either way, the capsule's -0.5 must simply not count
				check.equal(
					bolt.gjk.intersects(cf, margined_a, probe, target_negative, 1e-4),
					bolt.gjk.intersects(cf, margined_b, probe, target_plain, 1e-4)
				)

				local _, with_negative = bolt.gjk.shapecast_simple(cf, direction, margined_a, probe, target_negative, 1e-4)
				local _, without = bolt.gjk.shapecast_simple(cf, direction, margined_b, probe, target_plain, 1e-4)
				check.equal(with_negative == nil, without == nil)
				if with_negative and without then
					check.near(with_negative, without, 1e-6)
				end

				local hit_negative, _, depth_negative = bolt.mpr.intersects(cf, margined_a, probe, target_negative, 1e-4)
				local hit_plain, _, depth_plain = bolt.mpr.intersects(cf, margined_b, probe, target_plain, 1e-4)
				check.equal(hit_negative, hit_plain)
				if depth_negative and depth_plain then
					check.near(depth_negative, depth_plain, 1e-6)
				end
			end
		end)


		--a mesh is never handed to gjk directly, its hulls are, so a margin written on the mesh has to
		--reach them or it silently does nothing while the broad phase still widens around it
		it('reaches a mesh through its hulls', function ()
			local plain = helpers.make_two_hull_mesh(bolt)
			local margined = helpers.make_two_hull_mesh(bolt)
			margined.margin = 0.4

			--straight down onto the hull centred at x = 2, whose top face sits at y = 0.5
			local origin = Vector3.new(2, 10, 0)
			local direction = Vector3.new(0, -20, 0)

			local _, plain_distance = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, plain, 1e-5)
			local _, margined_distance = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, margined, 1e-5)

			check.near(check.non_nil(plain_distance), 9.5, 1e-3)
			check.near(check.non_nil(plain_distance) - check.non_nil(margined_distance), 0.4, 1e-3)
		end)


		it('a mesh picks up a margin set after creation', function ()
			local mesh = helpers.make_two_hull_mesh(bolt)
			local origin = Vector3.new(2, 10, 0)
			local direction = Vector3.new(0, -20, 0)

			local _, before = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			mesh.margin = 0.4
			local _, after = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			mesh.margin = nil
			local _, cleared = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			check.near(check.non_nil(before) - check.non_nil(after), 0.4, 1e-3)
			check.near(check.non_nil(cleared), check.non_nil(before), 1e-3)
		end)


		--raising a margin widens the tree by the difference rather than from scratch, so a margin that
		--climbs in steps has to land in the same place as one that was set there directly
		it('a mesh margin raised in steps widens the same amount', function ()
			local mesh = helpers.make_two_hull_mesh(bolt)
			local origin = Vector3.new(2, 10, 0)
			local direction = Vector3.new(0, -20, 0)

			local _, base = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			mesh.margin = 0.4
			local _, first = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			mesh.margin = 0.9
			local _, second = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			check.near(check.non_nil(base) - check.non_nil(first), 0.4, 1e-3)
			check.near(check.non_nil(base) - check.non_nil(second), 0.9, 1e-3)

			--and the widened bounds still reach the band only the larger margin covers
			local probe = bolt.create_sphere(0.1)
			check.truthy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(2, 1.45, 0), probe, 1e-5))
			check.falsy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(2, 1.55, 0), probe, 1e-5))
		end)


		--the mesh's own tree is built from its hulls, so it has to widen with them or it culls hulls
		--whose inflated surface the query still reaches
		it('a mesh margin widens its local tree too', function ()
			local margined = helpers.make_two_hull_mesh(bolt)
			margined.margin = 0.5

			local probe = bolt.create_sphere(0.1)

			--the hull's top face is at 0.5, so with the probe's radius contact holds out to 1.1
			check.truthy(bolt.dispatch.gjk.intersects(CFrame.identity, margined, CFrame.new(2, 1.05, 0), probe, 1e-5))
			check.falsy(bolt.dispatch.gjk.intersects(CFrame.identity, margined, CFrame.new(2, 1.15, 0), probe, 1e-5))
		end)


		--those bounds only ever grow, contracting them would land a little short of where they started
		--each time the margin moved, and bounds even slightly too tight cull real contacts, while bounds
		--left wide only cost a rejected candidate, results still have to answer for the current margin
		it('lowering a mesh margin keeps the wider bounds but not the wider reach', function ()
			local mesh = helpers.make_two_hull_mesh(bolt)
			local origin = Vector3.new(2, 10, 0)
			local direction = Vector3.new(0, -20, 0)

			mesh.margin = 0.9
			local _, high = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)
			check.near(check.non_nil(high), 8.6, 1e-3)
			check.near(mesh.tree_margin, 0.9, 1e-6)

			mesh.margin = 0.2
			local _, low = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)

			--the reach follows the margin down
			check.near(check.non_nil(low), 9.3, 1e-3)
			--while the bounds stay where the larger margin left them
			check.near(mesh.tree_margin, 0.9, 1e-6)

			--and contact answers for 0.2, not for the bounds that were kept
			local probe = bolt.create_sphere(0.1)
			check.truthy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(2, 0.75, 0), probe, 1e-5))
			check.falsy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(2, 0.85, 0), probe, 1e-5))
		end)


		--resizing rebuilds the bounds from the hulls, so accumulated slack is reset
		it('resizing a mesh clears the slack a lowered margin left', function ()
			local mesh = helpers.make_two_hull_mesh(bolt)
			check.near(mesh.tree_margin, 0, 1e-6)

			local origin = Vector3.new(2, 10, 0)
			local direction = Vector3.new(0, -20, 0)

			mesh.margin = 0.9
			bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)
			mesh.margin = 0.2
			bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)
			check.near(mesh.tree_margin, 0.9, 1e-6)

			bolt.resize_mesh(mesh, Vector3.new(6, 2, 2))
			check.near(mesh.tree_margin, 0.2, 1e-6)

			--and the rebuilt bounds still cover everything the margin reaches
			local _, distance = bolt.dispatch.gjk.raycast(origin, direction, CFrame.identity, mesh, 1e-5)
			check.near(check.non_nil(distance), 9.3, 1e-3)

			local probe = bolt.create_sphere(0.1)
			check.truthy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(2, 0.75, 0), probe, 1e-5))
			check.falsy(bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(2, 0.85, 0), probe, 1e-5))
		end)
	end)

	it('circumradius contains the shape at every orientation', function ()
		local shapes = {
			bolt.create_sphere(1.3),
			bolt.create_box(Vector3.new(3, 1, 5)),
			bolt.create_ellipsoid(Vector3.new(3, 1, 5)),
			bolt.create_capsule(0.6, 4),
			bolt.create_cylinder(0.9, 3),
			bolt.create_wedge(Vector3.new(3, 2, 4)),
			bolt.create_corner_wedge(Vector3.new(3, 2, 4)),
			bolt.create_hull(unit_cube_hull_info(), Vector3.new(4, 2, 6)),
		}

		local random = Random.new(9090)
		for _, shape in shapes do
			local radius = bolt.circumradius(shape)
			local tree = bolt.aabb_tree.new({aabb_padding = 0})
			tree:insert(1, CFrame.identity, shape)

			for _ = 1, 60 do
				local cf = CFrame.Angles(
					random:NextNumber(-math.pi, math.pi),
					random:NextNumber(-math.pi, math.pi),
					random:NextNumber(-math.pi, math.pi))
				tree:move(1, cf)

				local leaf = tree.leaf_map[1]
				local min, max = tree.aabb_min[leaf], tree.aabb_max[leaf]

				--the AABB touches the shape on every face, so its furthest corner coordinate is a
				--distance the shape genuinely reaches
				local reach = math.max(
					math.abs(min.x), math.abs(max.x),
					math.abs(min.y), math.abs(max.y),
					math.abs(min.z), math.abs(max.z))

				check.truthy(reach <= radius + 1e-4)
			end
		end
	end)


	it('circumradius matches the closed form for each shape', function ()
		check.near(bolt.circumradius(bolt.create_sphere(1.3)), 1.3, 1e-5)
		check.near(bolt.circumradius(bolt.create_box(Vector3.new(3, 1, 5))), math.sqrt(1.5^2 + 0.5^2 + 2.5^2), 1e-5)
		--an ellipsoid reaches furthest along its longest axis, not toward the box corner
		check.near(bolt.circumradius(bolt.create_ellipsoid(Vector3.new(3, 1, 5))), 2.5, 1e-5)
		check.near(bolt.circumradius(bolt.create_capsule(0.6, 4)), 2.6, 1e-5)
		check.near(bolt.circumradius(bolt.create_cylinder(0.9, 3)), math.sqrt(1.5^2 + 0.9^2), 1e-5)
		check.near(bolt.circumradius(bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))), math.sqrt(3), 1e-5)
		--a composite is measured from its own tree, so its furthest corner is the far hull's, not the declared size's
		check.near(bolt.circumradius(helpers.make_two_hull_mesh(bolt)), math.sqrt(2.5^2 + 0.5^2 + 0.5^2), 1e-5)
	end)


	it('circumradius follows the margin and a resize', function ()
		local box = bolt.create_box(Vector3.new(2, 2, 2))
		check.near(bolt.circumradius(box), math.sqrt(3), 1e-5)

		box.margin = 0.7
		check.near(bolt.circumradius(box), math.sqrt(3) + 0.7, 1e-5)

		--a negative margin is ignored here exactly as it is everywhere else
		box.margin = -0.7
		check.near(bolt.circumradius(box), math.sqrt(3), 1e-5)

		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))
		bolt.resize_hull(hull, Vector3.new(4, 4, 4))
		check.near(bolt.circumradius(hull), math.sqrt(12), 1e-5)
	end)


	it('composite circumradius adds the margin once whatever the tree carries', function ()
		local mesh = helpers.make_two_hull_mesh(bolt)
		local base = math.sqrt(2.5^2 + 0.5^2 + 0.5^2)
		local probe = bolt.create_sphere(0.1)

		--before any query the tree is unmargined, so the margin comes entirely from the shape
		mesh.margin = 0.5
		check.equal(mesh.tree_margin, 0)
		check.near(bolt.circumradius(mesh), base + 0.5, 1e-5)

		--a dispatched query widens the tree by the margin, which must not be counted twice
		bolt.dispatch.gjk.intersects(CFrame.identity, mesh, CFrame.new(80, 0, 0), probe, 1e-5)
		check.near(mesh.tree_margin, 0.5, 1e-5)
		check.near(bolt.circumradius(mesh), base + 0.5, 1e-5)

		--the tree keeps its wider bounds when the margin drops, the radius follows the margin anyway
		mesh.margin = 0.2
		check.near(bolt.circumradius(mesh), base + 0.2, 1e-5)

		--a negative margin is ignored, leaving the bare geometry
		mesh.margin = -0.2
		check.near(bolt.circumradius(mesh), base, 1e-5)
	end)


	it('hull constructor scales and carries no offset', function ()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))

		--a standalone hull is placed by the cframe it is queried with, never by an offset
		check.vector_near(hull.offset, Vector3.zero)
		check.vector_near(hull.scale, Vector3.new(2, 2, 2))
		check.vector_near(hull.original_half_extents, Vector3.new(0.5, 0.5, 0.5))

		local non_uniform = bolt.create_hull(unit_cube_hull_info(), Vector3.new(4, 1, 6))
		check.vector_near(non_uniform.scale, Vector3.new(4, 1, 6))
	end)


	it('hull behaves like the equivalent box', function ()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))
		local box = bolt.create_box(Vector3.new(2, 2, 2))
		local cf = CFrame.new(3, -1, 2) * CFrame.fromOrientation(0.3, 0.7, -0.2)

		--identical bounds mean no query can ever return one of them without the other
		local tree = bolt.aabb_tree.new_static()
		tree:insert(1, cf, hull)
		tree:insert(2, cf, box)
		tree:full_rebuild()

		local random = Random.new(77)
		for _ = 1, 40 do
			local center = Vector3.new(random:NextNumber(-8, 8), random:NextNumber(-8, 8), random:NextNumber(-8, 8))
			local half = Vector3.one * random:NextNumber(0.5, 3)

			local has_hull, has_box = false, false
			for _, id in tree:query_aabb(center - half, center + half) do
				if id == 1 then
					has_hull = true
				elseif id == 2 then
					has_box = true
				end
			end
			check.equal(has_hull, has_box, "hull and box bounds disagree")
		end

		--and the narrow phase has to agree too
		local sphere = bolt.create_sphere(1)
		local probe = CFrame.new(4, -1, 2)
		check.equal(bolt.gjk.intersects(cf, hull, probe, sphere, 0), bolt.gjk.intersects(cf, box, probe, sphere, 0))

		local origin = Vector3.new(-10, -1, 2)
		local direction = Vector3.new(30, 0, 0)
		local hull_point, hull_distance = bolt.gjk.raycast(origin, direction, cf, hull, 0)
		local box_point, box_distance = bolt.gjk.raycast(origin, direction, cf, box, 0)
		check.near(check.non_nil(hull_distance), check.non_nil(box_distance), 1e-4)
		check.vector_near(check.non_nil(hull_point), check.non_nil(box_point), 1e-4)
	end)


	it('resize_hull rescales from the original size', function ()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))

		bolt.resize_hull(hull, Vector3.new(4, 4, 4))
		check.vector_near(hull.scale, Vector3.new(4, 4, 4))

		--scale is derived from the original size rather than the current one, so resizes do not
		--compound the way repeatedly multiplying the existing scale would
		bolt.resize_hull(hull, Vector3.new(2, 8, 3))
		check.vector_near(hull.scale, Vector3.new(2, 8, 3))
	end)


	it('resized hull reaches its tree through resize', function ()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))
		local tree = bolt.aabb_tree.new({aabb_padding = 0})
		tree:insert(1, CFrame.identity, hull)

		--half extent 1 while the hull is 2 wide, so this point sits outside it
		local point = Vector3.new(1.8, 0, 0)
		check.set_equal(tree:query_aabb(point, point), {})

		bolt.resize_hull(hull, Vector3.new(6, 6, 6))
		tree:resize(1, hull)
		check.set_equal(tree:query_aabb(point, point), {1})
	end)

	it('primitive constructors store expected dimensions', function ()
		local box = bolt.create_box(Vector3.new(2, 4, 6))
		local sphere = bolt.create_sphere(1.25)
		local ellipsoid = bolt.create_ellipsoid(Vector3.new(2, 4, 6))
		local capsule = bolt.create_capsule(0.75, 4)
		local cylinder = bolt.create_cylinder(1.5, 6)

		check.vector_near(box.half_extents, Vector3.new(1, 2, 3))
		check.near(sphere.radius, 1.25)
		check.vector_near(ellipsoid.half_extents, Vector3.new(1, 2, 3))
		check.near(capsule.radius, 0.75)
		check.near(capsule.half_height, 2)
		check.near(cylinder.radius, 1.5)
		check.near(cylinder.half_height, 3)
	end)


	it('wedge vertices match documented part dimensions', function ()
		local wedge = bolt.create_wedge(Vector3.new(2, 4, 6))
		check.vector_near(wedge.vertices[1], Vector3.new(1, -2, 3))
		check.vector_near(wedge.vertices[2], Vector3.new(1, -2, -3))
		check.vector_near(wedge.vertices[3], Vector3.new(1, 2, 3))
	end)


	it('corner wedge third vertex uses right minus look plus up', function ()
		local corner = bolt.create_corner_wedge(Vector3.new(2, 4, 6))
		check.vector_near(corner.vertices[3], Vector3.new(1, 2, -3))
	end)


	it('create_from_part maps Part types', function ()
		local block = Instance.new("Part")
		block.Shape = Enum.PartType.Block
		block.Size = Vector3.new(2, 4, 6)

		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(4, 4, 4)

		local ellipsoid = Instance.new("Part")
		ellipsoid.Shape = Enum.PartType.Ball
		ellipsoid.Size = Vector3.new(2, 4, 6)

		local cylinder = Instance.new("Part")
		cylinder.Shape = Enum.PartType.Cylinder
		cylinder.Size = Vector3.new(6, 4, 4)

		local wedge = Instance.new("Part")
		wedge.Shape = Enum.PartType.Wedge
		wedge.Size = Vector3.new(2, 4, 6)

		local corner_wedge = Instance.new("Part")
		corner_wedge.Shape = Enum.PartType.CornerWedge
		corner_wedge.Size = Vector3.new(2, 4, 6)

		local block_shape = bolt.create_from_part(block)
		local ball_shape = bolt.create_from_part(ball)
		local ellipsoid_shape = bolt.create_from_part(ellipsoid)
		local cylinder_shape = bolt.create_from_part(cylinder)
		local wedge_shape = bolt.create_from_part(wedge)
		local corner_wedge_shape = bolt.create_from_part(corner_wedge)

		check.equal(block_shape.type, bolt.create_box(block.Size).type)
		check.equal(ball_shape.type, bolt.create_sphere(2).type)
		check.equal(ellipsoid_shape.type, bolt.create_ellipsoid(ellipsoid.Size).type)
		check.equal(cylinder_shape.type, bolt.create_cylinder(2, 6).type)
		check.equal(wedge_shape.type, bolt.create_wedge(wedge.Size).type)
		check.equal(corner_wedge_shape.type, bolt.create_corner_wedge(corner_wedge.Size).type)

		block:Destroy()
		ball:Destroy()
		ellipsoid:Destroy()
		cylinder:Destroy()
		wedge:Destroy()
		corner_wedge:Destroy()
	end)


	it('create_from_part rejects wedge BaseParts', function ()
		local wedge = Instance.new("WedgePart")
		wedge.Size = Vector3.new(2, 4, 6)

		check.errors(function()
			bolt.create_from_part(wedge)
		end, "got unsupported instance type WedgePart")

		wedge:Destroy()
	end)


	it('create_from_part rejects corner-wedge BaseParts', function ()
		local corner = Instance.new("CornerWedgePart")
		corner.Size = Vector3.new(2, 4, 6)

		check.errors(function()
			bolt.create_from_part(corner)
		end, "got unsupported instance type CornerWedgePart")

		corner:Destroy()
	end)


	it('create_from_part rejects inconsistent cylinders and meshes', function ()
		local cylinder = Instance.new("Part")
		cylinder.Shape = Enum.PartType.Cylinder
		cylinder.Size = Vector3.new(4, 2, 3)

		local mesh = Instance.new("MeshPart")

		check.errors(function()
			bolt.create_from_part(cylinder)
		end, "cylinder does not have a consistent radius")
		check.errors(function()
			bolt.create_from_part(mesh)
		end, "meshes and unions cannot be created from parts")

		cylinder:Destroy()
		mesh:Destroy()
	end)
end)

return nil