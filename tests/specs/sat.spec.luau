--!strict

local Lest = require('@lest')
local describe, it = Lest.describe, Lest.it

local bolt = require('../../src')
local check = require('../check')
local helpers = require('../helpers')

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

	it(`sat {sat_case.name} separated`, function ()
		local hit, normal, depth = sat_case.collide(
			identity,
			sat_case.shape_a,
			CFrame.new(2 + delta, 0, 0),
			sat_case.shape_b
		)
		check.falsy(hit)
		check.is_nil(normal)
		check.is_nil(depth)
	end)

	it(`sat {sat_case.name} touching`, function ()
		local hit, normal, depth = sat_case.collide(
			identity,
			sat_case.shape_a,
			CFrame.new(2, 0, 0),
			sat_case.shape_b
		)
		check.truthy(hit)
		helpers.assert_unit_vector(check.non_nil(normal), 1e-3)
		check.near(check.non_nil(depth), 0, 1e-4)
	end)

	it(`sat {sat_case.name} overlapping`, function ()
		local cf_b = CFrame.new(2 - delta, 0, 0)
		local hit, normal, depth = sat_case.collide(
			identity,
			sat_case.shape_a,
			cf_b,
			sat_case.shape_b
		)
		check.truthy(hit)
		local hit_normal = check.non_nil(normal)
		local hit_depth = check.non_nil(depth)
		helpers.assert_unit_vector(hit_normal, 1e-3)
		check.truthy(hit_depth > 0)

		local separated_cf_a = CFrame.new(hit_normal * (hit_depth + delta))
		local separated = sat_case.collide(
			separated_cf_a,
			sat_case.shape_a,
			cf_b,
			sat_case.shape_b
		)
		check.falsy(separated)
	end)
end

describe('sat', function ()
	describe('box_box', function ()
		it('agrees with special and GJK for rotated boxes', function ()
			local cf_a = CFrame.new(-0.25, 0.1, 0.2) * CFrame.fromOrientation(0.25, -0.4, 0.1)
			local cf_b = CFrame.new(1.1, 0.2, -0.15) * CFrame.fromOrientation(-0.2, 0.3, 0.55)
			local sat_hit = bolt.sat.box_box(cf_a, box, cf_b, box)
			local special_hit = bolt.collision.box_box(cf_a, box, cf_b, box)
			local gjk_hit = bolt.gjk.intersects(cf_a, box, cf_b, box, 0)
			check.equal(sat_hit, special_hit)
			check.equal(sat_hit, gjk_hit)
		end)


		it('swap preserves depth and flips normal', function ()
			local cf_a = CFrame.new(-0.4, 0.1, 0)
			local cf_b = CFrame.new(0.8, 0.2, 0.1) * CFrame.fromOrientation(0.1, 0.2, -0.15)
			local hit_ab, normal_ab, depth_ab = bolt.sat.box_box(cf_a, box, cf_b, box)
			local hit_ba, normal_ba, depth_ba = bolt.sat.box_box(cf_b, box, cf_a, box)

			check.truthy(hit_ab)
			check.equal(hit_ba, hit_ab)
			check.near(check.non_nil(depth_ab), check.non_nil(depth_ba), 1e-4)
			check.vector_near(check.non_nil(normal_ab), -check.non_nil(normal_ba), 1e-4)
		end)

	end)

end)

return nil