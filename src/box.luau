--!strict
--!native
--!optimize 2

local types = require("./types")
local constants = require("./constants")

local FLT_EPSILON = constants.FLT_EPSILON

local function box_box(box_a_cf: CFrame, box_a_shape: types.BoxShape, box_b_cf: CFrame, box_b_shape: types.BoxShape): boolean
	local diff = box_b_cf.Position - box_a_cf.Position

	local axa, aya, aza = box_a_cf.RightVector, box_a_cf.UpVector, box_a_cf.LookVector
	local axb, ayb, azb = box_b_cf.RightVector, box_b_cf.UpVector, box_b_cf.LookVector
	
	local half_extents_a = box_a_shape.half_extents
	local half_extents_b = box_b_shape.half_extents
	local hxa, hya, hza = half_extents_a.X, half_extents_a.Y, half_extents_a.Z
	local hxb, hyb, hzb = half_extents_b.X, half_extents_b.Y, half_extents_b.Z

	local r00, r01, r02 = vector.dot(axa :: any, axb :: any), vector.dot(axa :: any, ayb :: any), vector.dot(axa :: any, azb :: any)
	local r10, r11, r12 = vector.dot(aya :: any, axb :: any), vector.dot(aya :: any, ayb :: any), vector.dot(aya :: any, azb :: any)
	local r20, r21, r22 = vector.dot(aza :: any, axb :: any), vector.dot(aza :: any, ayb :: any), vector.dot(aza :: any, azb :: any)

	local a00, a01, a02 = math.abs(r00) + FLT_EPSILON, math.abs(r01) + FLT_EPSILON, math.abs(r02) + FLT_EPSILON
	local a10, a11, a12 = math.abs(r10) + FLT_EPSILON, math.abs(r11) + FLT_EPSILON, math.abs(r12) + FLT_EPSILON
	local a20, a21, a22 = math.abs(r20) + FLT_EPSILON, math.abs(r21) + FLT_EPSILON, math.abs(r22) + FLT_EPSILON

	local dx0 = vector.dot(diff :: any, axa :: any)
	local dy0 = vector.dot(diff :: any, aya :: any)
	local dz0 = vector.dot(diff :: any, aza :: any)

	if math.abs(dx0) > hxa + a00*hxb + a01*hyb + a02*hzb then return false end
	if math.abs(dy0) > hya + a10*hxb + a11*hyb + a12*hzb then return false end
	if math.abs(dz0) > hza + a20*hxb + a21*hyb + a22*hzb then return false end

	if math.abs(vector.dot(diff :: any, axb :: any)) > hxb + a00*hxa + a10*hya + a20*hza then return false end
	if math.abs(vector.dot(diff :: any, ayb :: any)) > hyb + a01*hxa + a11*hya + a21*hza then return false end
	if math.abs(vector.dot(diff :: any, azb :: any)) > hzb + a02*hxa + a12*hya + a22*hza then return false end

	if math.abs(dy0*r20 - dz0*r10) > hya*a20 + hza*a10 + hyb*a02 + hzb*a01 then return false end
	if math.abs(dy0*r21 - dz0*r11) > hya*a21 + hza*a11 + hxb*a02 + hzb*a00 then return false end
	if math.abs(dy0*r22 - dz0*r12) > hya*a22 + hza*a12 + hxb*a01 + hyb*a00 then return false end

	if math.abs(dz0*r00 - dx0*r20) > hxa*a20 + hza*a00 + hyb*a12 + hzb*a11 then return false end
	if math.abs(dz0*r01 - dx0*r21) > hxa*a21 + hza*a01 + hxb*a12 + hzb*a10 then return false end
	if math.abs(dz0*r02 - dx0*r22) > hxa*a22 + hza*a02 + hxb*a11 + hyb*a10 then return false end

	if math.abs(dx0*r10 - dy0*r00) > hxa*a10 + hya*a00 + hyb*a22 + hzb*a21 then return false end
	if math.abs(dx0*r11 - dy0*r01) > hxa*a11 + hya*a01 + hxb*a22 + hzb*a20 then return false end
	if math.abs(dx0*r12 - dy0*r02) > hxa*a12 + hya*a02 + hxb*a21 + hyb*a20 then return false end

	return true
end

local function box_sphere(box_cf: CFrame, box_shape: types.BoxShape, sphere_cf: CFrame, sphere_shape: types.SphereShape): boolean
	local relative = box_cf:Inverse() * sphere_cf.Position

	local box_half_extents = box_shape.half_extents
	local sphere_radius = sphere_shape.radius

	local sx, sy, sz = box_half_extents.X, box_half_extents.Y, box_half_extents.Z
	local rx, ry, rz = relative.X, relative.Y, relative.Z

	local dx = rx > sx and rx - sx
		or rx < -sx and rx + sx
		or 0
	local dy = ry > sy and ry - sy
		or ry < -sy and ry + sy
		or 0
	local dz = rz > sz and rz - sz
		or rz < -sz and rz + sz
		or 0

	return dx*dx + dy*dy + dz*dz <= sphere_radius * sphere_radius
end

local function box_capsule(box_cf: CFrame, box_shape: types.BoxShape, capsule_cf: CFrame, capsule_shape: types.CapsuleShape): boolean
	local local_capsule_cf = box_cf:ToObjectSpace(capsule_cf)
	local local_capsule_origin = local_capsule_cf.Position
	local local_capsule_axis = local_capsule_cf.RightVector
	local box_half_extents = box_shape.half_extents
	local capsule_half_height = capsule_shape.half_height
	local capsule_radius = capsule_shape.radius

	local t = math.clamp(
		vector.dot(local_capsule_axis :: any, local_capsule_origin :: any),
		-capsule_half_height, capsule_half_height
	)
	
	local seg_pt = local_capsule_origin + local_capsule_axis * t
	local box_pt = vector.clamp(seg_pt :: any, -box_half_extents :: any, box_half_extents :: any)

	t = math.clamp(
		vector.dot(local_capsule_axis :: any, box_pt - local_capsule_origin :: any),
		-capsule_half_height, capsule_half_height
	)
	
	local closest_on_segment = local_capsule_origin + local_capsule_axis * t
	local closest_on_box = vector.clamp(closest_on_segment :: any, -box_half_extents :: any, box_half_extents :: any)

	local diff = closest_on_segment - closest_on_box :: any
	return vector.dot(diff :: any, diff :: any) <= capsule_radius * capsule_radius
end

return {
	box_box = box_box,
	box_sphere = box_sphere,
	box_capsule = box_capsule
}