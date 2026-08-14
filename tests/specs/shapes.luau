--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	local function unit_cube_hull_info(): any
		--a 1x1x1 hull, so a creation size of n scales it to an n sided cube
		local unit = helpers.make_box_hull(Vector3.zero, Vector3.new(0.5, 0.5, 0.5))
		return {
			vertices = unit.vertices,
			adjacency = unit.adjacency,
			size = Vector3.new(1, 1, 1),
		}
	end

	t.test("shapes/hull constructor scales and carries no offset", function()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))

		--a standalone hull is placed by the cframe it is queried with, never by an offset
		t.vector_near(hull.offset, Vector3.zero)
		t.vector_near(hull.scale, Vector3.new(2, 2, 2))
		t.vector_near(hull.original_half_extents, Vector3.new(0.5, 0.5, 0.5))

		local non_uniform = bolt.create_hull(unit_cube_hull_info(), Vector3.new(4, 1, 6))
		t.vector_near(non_uniform.scale, Vector3.new(4, 1, 6))
	end)

	t.test("shapes/hull behaves like the equivalent box", function()
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
			t.equal(has_hull, has_box, "hull and box bounds disagree")
		end

		--and the narrow phase has to agree too
		local sphere = bolt.create_sphere(1)
		local probe = CFrame.new(4, -1, 2)
		t.equal(bolt.gjk.intersects(cf, hull, probe, sphere, 0), bolt.gjk.intersects(cf, box, probe, sphere, 0))

		local origin = Vector3.new(-10, -1, 2)
		local direction = Vector3.new(30, 0, 0)
		local hull_point, hull_distance = bolt.gjk.raycast(origin, direction, cf, hull, 0)
		local box_point, box_distance = bolt.gjk.raycast(origin, direction, cf, box, 0)
		t.near(t.non_nil(hull_distance), t.non_nil(box_distance), 1e-4)
		t.vector_near(t.non_nil(hull_point), t.non_nil(box_point), 1e-4)
	end)

	t.test("shapes/resize_hull rescales from the original size", function()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))

		bolt.resize_hull(hull, Vector3.new(4, 4, 4))
		t.vector_near(hull.scale, Vector3.new(4, 4, 4))

		--scale is derived from the original size rather than the current one, so resizes do not
		--compound the way repeatedly multiplying the existing scale would
		bolt.resize_hull(hull, Vector3.new(2, 8, 3))
		t.vector_near(hull.scale, Vector3.new(2, 8, 3))
	end)

	t.test("shapes/resized hull reaches its tree through resize", function()
		local hull = bolt.create_hull(unit_cube_hull_info(), Vector3.new(2, 2, 2))
		local tree = bolt.aabb_tree.new({aabb_padding = 0})
		tree:insert(1, CFrame.identity, hull)

		--half extent 1 while the hull is 2 wide, so this point sits outside it
		local point = Vector3.new(1.8, 0, 0)
		t.set_equal(tree:query_aabb(point, point), {})

		bolt.resize_hull(hull, Vector3.new(6, 6, 6))
		tree:resize(1, hull)
		t.set_equal(tree:query_aabb(point, point), {1})
	end)
	t.test("shapes/primitive constructors store expected dimensions", function()
		local box = bolt.create_box(Vector3.new(2, 4, 6))
		local sphere = bolt.create_sphere(1.25)
		local ellipsoid = bolt.create_ellipsoid(Vector3.new(2, 4, 6))
		local capsule = bolt.create_capsule(0.75, 4)
		local cylinder = bolt.create_cylinder(1.5, 6)

		t.vector_near(box.half_extents, Vector3.new(1, 2, 3))
		t.near(sphere.radius, 1.25)
		t.vector_near(ellipsoid.half_extents, Vector3.new(1, 2, 3))
		t.near(capsule.radius, 0.75)
		t.near(capsule.half_height, 2)
		t.near(cylinder.radius, 1.5)
		t.near(cylinder.half_height, 3)
	end)

	t.test("shapes/wedge vertices match documented part dimensions", function()
		local wedge = bolt.create_wedge(Vector3.new(2, 4, 6))
		t.vector_near(wedge.vertices[1], Vector3.new(1, -2, 3))
		t.vector_near(wedge.vertices[2], Vector3.new(1, -2, -3))
		t.vector_near(wedge.vertices[3], Vector3.new(1, 2, 3))
	end)

	t.test("shapes/corner wedge third vertex uses right minus look plus up", function()
		local corner = bolt.create_corner_wedge(Vector3.new(2, 4, 6))
		t.vector_near(corner.vertices[3], Vector3.new(1, 2, -3))
	end)

	t.test("shapes/create_from_part maps Part types", function()
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

		t.equal(block_shape.type, bolt.create_box(block.Size).type)
		t.equal(ball_shape.type, bolt.create_sphere(2).type)
		t.equal(ellipsoid_shape.type, bolt.create_ellipsoid(ellipsoid.Size).type)
		t.equal(cylinder_shape.type, bolt.create_cylinder(2, 6).type)
		t.equal(wedge_shape.type, bolt.create_wedge(wedge.Size).type)
		t.equal(corner_wedge_shape.type, bolt.create_corner_wedge(corner_wedge.Size).type)

		block:Destroy()
		ball:Destroy()
		ellipsoid:Destroy()
		cylinder:Destroy()
		wedge:Destroy()
		corner_wedge:Destroy()
	end)

	t.test("shapes/create_from_part rejects wedge BaseParts", function()
		local wedge = Instance.new("WedgePart")
		wedge.Size = Vector3.new(2, 4, 6)

		t.errors(function()
			bolt.create_from_part(wedge)
		end, "got unsupported instance type WedgePart")

		wedge:Destroy()
	end)

	t.test("shapes/create_from_part rejects corner-wedge BaseParts", function()
		local corner = Instance.new("CornerWedgePart")
		corner.Size = Vector3.new(2, 4, 6)
		
		t.errors(function()
			bolt.create_from_part(corner)
		end, "got unsupported instance type CornerWedgePart")

		corner:Destroy()
	end)

	t.test("shapes/create_from_part rejects inconsistent cylinders and meshes", function()
		local cylinder = Instance.new("Part")
		cylinder.Shape = Enum.PartType.Cylinder
		cylinder.Size = Vector3.new(4, 2, 3)

		local mesh = Instance.new("MeshPart")

		t.errors(function()
			bolt.create_from_part(cylinder)
		end, "cylinder does not have a consistent radius")
		t.errors(function()
			bolt.create_from_part(mesh)
		end, "meshes and unions cannot be created from parts")

		cylinder:Destroy()
		mesh:Destroy()
	end)
end