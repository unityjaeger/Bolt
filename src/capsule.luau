--!strict
--!native
--!optimize 2

local types = require("./types")
local constants = require("./constants")

local FLT_EPSILON = constants.FLT_EPSILON

local function capsule_capsule(capsule_a_cf: CFrame, capsule_a_shape: types.CapsuleShape, capsule_b_cf: CFrame, capsule_b_shape: types.CapsuleShape): boolean
	local axis_a = capsule_a_cf.RightVector
	local axis_b = capsule_b_cf.RightVector
	local center_a = capsule_a_cf.Position
	local center_b = capsule_b_cf.Position

	local half_height_a = capsule_a_shape.half_height
	local half_height_b = capsule_b_shape.half_height

	local start_a = center_a - axis_a * half_height_a
	local start_b = center_b - axis_b * half_height_b

	local segment_a = axis_a * half_height_a * 2
	local segment_b = axis_b * half_height_b * 2

	local delta = start_a - start_b

	local len_sq_a = half_height_a * half_height_a * 4
	local len_sq_b = half_height_b * half_height_b * 4

	local param_a, param_b

	if len_sq_a < FLT_EPSILON and len_sq_b < FLT_EPSILON then
		param_a, param_b = 0, 0
	elseif len_sq_a < FLT_EPSILON then
		param_a = 0
		param_b = math.clamp(vector.dot(segment_b :: any, delta :: any) / len_sq_b, 0, 1)
	else
		local dot_a_delta = vector.dot(segment_a :: any, delta :: any)

		if len_sq_b < FLT_EPSILON then
			param_b = 0
			param_a = math.clamp(-dot_a_delta / len_sq_a, 0, 1)
		else
			local dot_ab = vector.dot(segment_a :: any, segment_b :: any)
			local dot_b_delta = vector.dot(segment_b :: any, delta :: any)

			local denom = len_sq_a * len_sq_b - dot_ab * dot_ab
			if denom > FLT_EPSILON then
				param_a = math.clamp((dot_ab * dot_b_delta - dot_a_delta * len_sq_b) / denom, 0, 1)
			else
				param_a = 0
			end

			param_b = (dot_ab * param_a + dot_b_delta) / len_sq_b

			if param_b < 0 then
				param_b = 0
				param_a = math.clamp(-dot_a_delta / len_sq_a, 0, 1)
			elseif param_b > 1 then
				param_b = 1
				param_a = math.clamp((dot_ab - dot_a_delta) / len_sq_a, 0, 1)
			end
		end
	end

	local closest_diff = delta + param_a * segment_a - param_b * segment_b
	local radius_sum = capsule_a_shape.radius + capsule_b_shape.radius
	return vector.dot(closest_diff :: any, closest_diff :: any) <= radius_sum * radius_sum
end

return {
	capsule_capsule = capsule_capsule
}