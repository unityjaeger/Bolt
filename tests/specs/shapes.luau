--!strict

return function(t: any, bolt: any)
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