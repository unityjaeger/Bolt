--!strict

local helpers = require(script.Parent.Parent.helpers)

return function(t: any, bolt: any)
	local delta = helpers.DELTA
	local box = bolt.create_box(Vector3.new(2, 2, 2))
	local sphere = bolt.create_sphere(1)
	local capsule = bolt.create_capsule(0.5, 2)
	local identity = CFrame.identity

	local cases = {
		{
			name = "box_box",
			collides = function(offset: number)
				return bolt.collision.box_box(identity, box, CFrame.new(2 + offset, 0, 0), box)
			end,
		},
		{
			name = "box_sphere",
			collides = function(offset: number)
				return bolt.collision.box_sphere(identity, box, CFrame.new(2 + offset, 0, 0), sphere)
			end,
		},
		{
			name = "box_capsule",
			collides = function(offset: number)
				return bolt.collision.box_capsule(identity, box, CFrame.new(0, 1.5 + offset, 0), capsule)
			end,
		},
		{
			name = "sphere_sphere",
			collides = function(offset: number)
				return bolt.collision.sphere_sphere(identity, sphere, CFrame.new(2 + offset, 0, 0), sphere)
			end,
		},
		{
			name = "sphere_capsule",
			collides = function(offset: number)
				return bolt.collision.sphere_capsule(
					CFrame.new(0, 1.5 + offset, 0),
					sphere,
					identity,
					capsule
				)
			end,
		},
		{
			name = "capsule_capsule",
			collides = function(offset: number)
				return bolt.collision.capsule_capsule(identity, capsule, CFrame.new(0, 1 + offset, 0), capsule)
			end,
		},
	}

	for _, case in cases do
		local collision_case = case

		t.test(`special collision/{collision_case.name}/separated`, function()
			t.falsy(collision_case.collides(delta))
		end)

		t.test(`special collision/{collision_case.name}/touching`, function()
			t.truthy(collision_case.collides(0))
		end)

		t.test(`special collision/{collision_case.name}/overlapping`, function()
			t.truthy(collision_case.collides(-delta))
		end)
	end

	t.test("special collision/GJK agrees on all primitive contact boundaries", function()
		local boundaries = {
			{
				name = "box_box",
				shape_a = box,
				shape_b = box,
				cf_b = function(offset: number) return CFrame.new(2 + offset, 0, 0) end,
			},
			{
				name = "box_sphere",
				shape_a = box,
				shape_b = sphere,
				cf_b = function(offset: number) return CFrame.new(2 + offset, 0, 0) end,
			},
			{
				name = "box_capsule",
				shape_a = box,
				shape_b = capsule,
				cf_b = function(offset: number) return CFrame.new(0, 1.5 + offset, 0) end,
			},
			{
				name = "sphere_sphere",
				shape_a = sphere,
				shape_b = sphere,
				cf_b = function(offset: number) return CFrame.new(2 + offset, 0, 0) end,
			},
			{
				name = "sphere_capsule",
				shape_a = sphere,
				shape_b = capsule,
				cf_b = function(offset: number) return CFrame.new(0, 1.5 + offset, 0) end,
			},
			{
				name = "capsule_capsule",
				shape_a = capsule,
				shape_b = capsule,
				cf_b = function(offset: number) return CFrame.new(0, 1 + offset, 0) end,
			},
		}

		for _, boundary in boundaries do
			local separated = bolt.gjk.intersects(
				identity,
				boundary.shape_a,
				boundary.cf_b(delta),
				boundary.shape_b,
				0
			)
			local touching = bolt.gjk.intersects(
				identity,
				boundary.shape_a,
				boundary.cf_b(0),
				boundary.shape_b,
				0
			)
			local overlapping = bolt.gjk.intersects(
				identity,
				boundary.shape_a,
				boundary.cf_b(-delta),
				boundary.shape_b,
				0
			)

			t.falsy(separated, `{boundary.name} separated`)
			t.truthy(touching, `{boundary.name} touching`)
			t.truthy(overlapping, `{boundary.name} overlapping`)
		end
	end)

	t.test("special collision/box capsule/axis-aligned segment", function()
		local hit = bolt.collision.box_capsule(
			CFrame.identity,
			box,
			CFrame.new(0, 1.5, 0),
			capsule
		)
		t.truthy(hit)
	end)

	t.test("special collision/box capsule/zero-height capsule matches sphere", function()
		local point_capsule = bolt.create_capsule(0.75, 0)
		local point_sphere = bolt.create_sphere(0.75)
		local positions = {
			CFrame.new(1.75, 0, 0),
			CFrame.new(1.75 + delta, 0, 0),
			CFrame.new(1.75 - delta, 0, 0),
			CFrame.new(0, 1.75, 0),
			CFrame.new(1.4, 1.4, 0),
		}

		for _, cf in positions do
			local capsule_hit = bolt.collision.box_capsule(identity, box, cf, point_capsule)
			local sphere_hit = bolt.collision.box_sphere(identity, box, cf, point_sphere)
			t.equal(capsule_hit, sphere_hit, `mismatch at {cf}`)
		end
	end)

	t.test("special collision/box capsule/small active axis components", function()
		local axis = Vector3.new(math.sqrt(1 - 2e-8), 1e-4, -1e-4)
		local up = (Vector3.yAxis - axis * axis.Y).Unit
		local back = axis:Cross(up)
		local capsule_cf = CFrame.fromMatrix(Vector3.new(0, 3, 3), axis, up, back)

		local large_box = bolt.create_box(Vector3.new(20002, 2, 2))
		local long_capsule = bolt.create_capsule(3, 20000)

		t.truthy(bolt.collision.box_capsule(identity, large_box, capsule_cf, long_capsule))
	end)
end