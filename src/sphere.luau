--!strict
--!native
--!optimize 2

local types = require("./types")

local function sphere_sphere(sphere_a_cf: CFrame, sphere_a_shape: types.SphereShape, sphere_b_cf: CFrame, sphere_b_shape: types.SphereShape): boolean
	return vector.magnitude(sphere_a_cf.Position - sphere_b_cf.Position :: any) <= sphere_a_shape.radius + sphere_b_shape.radius
end

local function sphere_capsule(sphere_cf: CFrame, sphere_shape: types.SphereShape, capsule_cf: CFrame, capsule_shape: types.CapsuleShape): boolean
	local sphere_origin = sphere_cf.Position
	local capsule_origin = capsule_cf.Position
	local axis = capsule_cf.RightVector

	local capsule_half_height = capsule_shape.half_height

	local offset = sphere_origin - capsule_origin

	local t = math.clamp(vector.dot(offset :: any, axis :: any), -capsule_half_height, capsule_half_height)
	local closest = capsule_origin + axis * t

	return vector.magnitude(sphere_origin - closest :: any) <= sphere_shape.radius + capsule_shape.radius
end

return {
	sphere_sphere = sphere_sphere,
	sphere_capsule = sphere_capsule
}