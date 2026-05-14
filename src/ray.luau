--!strict
--!native
--!optimize 2

local types = require("./types")
local constants = require("./constants")

local FLT_EPSILON = constants.FLT_EPSILON
local HUGE = constants.HUGE

local function ray_sphere(
	ray_origin: Vector3,
	ray_direction: Vector3,
	sphere_cf: CFrame,
	sphere_shape: types.SphereShape
): (Vector3?, number?, Vector3?, boolean?)
	local radius = sphere_shape.radius
	
	local sphere_origin = sphere_cf.Position
	local center_origin = ray_origin - sphere_origin
	
	local a = vector.dot(ray_direction :: any, ray_direction :: any)
	local hb = vector.dot(ray_direction :: any, center_origin :: any)
	local c = vector.dot(center_origin :: any, center_origin :: any) - radius * radius
	
	local disc = hb * hb - a * c
	if disc < 0 then
		return nil, nil, nil, nil
	end
	
	local sq = math.sqrt(disc)
	local inv_a = 1 / a
	local t1 = (-hb - sq) * inv_a
	local t2 = (-hb + sq) * inv_a
	
	local is_inside = false
	local t
	
	if t1 >= 0 then
		t = t1
	elseif t2 >= 0 then
		is_inside = true
		t = t2
	else
		return nil, nil, nil, nil
	end
	
	if t > 1 then
		return nil, nil, nil, nil
	end
	
	local hit = ray_origin + ray_direction * t
	local dist = t * vector.magnitude(ray_direction :: any)
	local normal = (hit - sphere_origin) * (1 / radius)
	return hit, dist, normal, is_inside
end

local function ray_box(
	ray_origin: Vector3,
	ray_direction: Vector3,
	box_cf: CFrame,
	box_shape: types.BoxShape
): (Vector3?, number?, Vector3?, boolean?)
	local pos, right, up, look = box_cf.Position, box_cf.RightVector, box_cf.UpVector, box_cf.LookVector

	local rel = ray_origin - pos
	local ox, oy, oz = vector.dot(rel :: any, right :: any), vector.dot(rel :: any, up :: any), vector.dot(rel :: any, look :: any)
	local dx, dy, dz = vector.dot(ray_direction :: any, right :: any), vector.dot(ray_direction :: any, up :: any), vector.dot(ray_direction :: any, look :: any)

	local he = box_shape.half_extents
	local hx, hy, hz = he.X, he.Y, he.Z

	local tnear_x, tfar_x, nsign_x
	if math.abs(dx) < FLT_EPSILON then
		if ox < -hx or ox > hx then return nil, nil, nil, nil end
		tnear_x, tfar_x, nsign_x = -math.huge, math.huge, 0
	else
		local t1 = (-hx - ox) / dx
		local t2 = ( hx - ox) / dx
		if t1 < t2 then tnear_x, tfar_x, nsign_x = t1, t2, -1
		else tnear_x, tfar_x, nsign_x = t2, t1,  1 end
	end

	local tnear_y, tfar_y, nsign_y
	if math.abs(dy) < FLT_EPSILON then
		if oy < -hy or oy > hy then return nil, nil, nil, nil end
		tnear_y, tfar_y, nsign_y = -math.huge, math.huge, 0
	else
		local t1 = (-hy - oy) / dy
		local t2 = ( hy - oy) / dy
		if t1 < t2 then tnear_y, tfar_y, nsign_y = t1, t2, -1
		else tnear_y, tfar_y, nsign_y = t2, t1,  1 end
	end

	local tnear_z, tfar_z, nsign_z
	if math.abs(dz) < FLT_EPSILON then
		if oz < -hz or oz > hz then return nil, nil, nil, nil end
		tnear_z, tfar_z, nsign_z = -math.huge, math.huge, 0
	else
		local t1 = (-hz - oz) / dz
		local t2 = ( hz - oz) / dz
		if t1 < t2 then tnear_z, tfar_z, nsign_z = t1, t2, -1
		else tnear_z, tfar_z, nsign_z = t2, t1,  1 end
	end

	local t_min = math.max(tnear_x, tnear_y, tnear_z)
	local t_max = math.min(tfar_x,  tfar_y,  tfar_z)

	if t_min > t_max or t_max < 0 then
		return nil, nil, nil, nil
	end

	local t
	local world_normal
	local is_inside = false
	
	if t_min >= 0 then
		if t_min >= 1 then
			return nil, nil, nil, nil
		end
		
		t = t_min
		
		if tnear_x >= tnear_y and tnear_x >= tnear_z then
			world_normal = right * nsign_x
		elseif tnear_y >= tnear_z then
			world_normal = up * nsign_y
		else
			world_normal = look * nsign_z
		end
	else
		if t_max >= 1 then
			return nil, nil, nil, nil
		end
		
		t = t_max

		if tfar_x <= tfar_y and tfar_x <= tfar_z then
			world_normal = right * -nsign_x
		elseif tfar_y <= tfar_z then
			world_normal = up * -nsign_y
		else
			world_normal = look * -nsign_z
		end
		
		is_inside = true
	end

	local hit = ray_origin + ray_direction * t
	return hit, t * vector.magnitude(ray_direction :: any), world_normal, is_inside
end

local function ray_capsule(
	ray_origin: Vector3,
	ray_direction: Vector3,
	capsule_cf: CFrame,
	capsule_shape: types.CapsuleShape
): (Vector3?, number?, Vector3?, boolean?)
	local radius = capsule_shape.radius
	local half_height = capsule_shape.half_height
	local radius_sq = radius * radius
	local length = half_height * 2
	
	local capsule_origin = capsule_cf.Position
	local axis = capsule_cf.RightVector
	local cap_a = capsule_origin - axis * half_height
	local cap_b = capsule_origin + axis * half_height
	
	local AO = ray_origin - cap_a
	
	local D_dot_D = vector.dot(ray_direction :: any, ray_direction :: any)
	local D_dot_AO = vector.dot(ray_direction :: any, AO :: any)
	local AO_sq = vector.dot(AO :: any, AO :: any)
	local ad = vector.dot(axis :: any, ray_direction :: any)
	local aao = vector.dot(axis :: any, AO :: any)
	
	local best_t = HUGE
	local best_normal = nil
	local is_inside = false
	
	local cyl_a = D_dot_D - ad * ad
	if cyl_a > FLT_EPSILON then
		local cyl_hb = D_dot_AO - ad * aao
		local cyl_c = AO_sq - aao * aao - radius_sq
		local disc = cyl_hb * cyl_hb - cyl_a * cyl_c
		if disc >= 0 then
			local sq = math.sqrt(disc)
			local inv_a = 1 / cyl_a
			local t1 = (-cyl_hb - sq) * inv_a
			local t2 = (-cyl_hb + sq) * inv_a
			
			local t = if t1 >= 0 then t1 else t2
			if t1 < 0 then
				is_inside = true
			end
			if t >= 0 and t <= 1 then
				local proj = aao + t * ad
				if proj >= 0 and proj <= length then
					best_t = t
					local hit = ray_origin + ray_direction * t
					local on_axis = cap_a + axis * proj
					best_normal = (hit - on_axis) * (1 / radius)
				end
			end
		end
	end
	
	do
		local disc = D_dot_AO * D_dot_AO - D_dot_D * (AO_sq - radius_sq)
		if disc >= 0 then
			local sq = math.sqrt(disc)
			local inv_a = 1 / D_dot_D
			local t = (-D_dot_AO - sq) * inv_a
			if t < 0 then
				is_inside = true
				t = (-D_dot_AO + sq) * inv_a
			end
			if t >= 0 and t <= 1 and t < best_t and (aao + t * ad) <= 0 then
				best_t = t
				local hit = ray_origin + ray_direction * t
				best_normal = (hit - cap_a) * (1 / radius)
			end
		end
	end
	
	do
		local BO = ray_origin - cap_b
		local b = vector.dot(ray_direction :: any, BO :: any)
		local c = vector.dot(BO :: any, BO :: any) - radius_sq
		local disc = b * b - D_dot_D * c
		if disc >= 0 then
			local sq = math.sqrt(disc)
			local inv_a = 1 / D_dot_D
			local t = (-b - sq) * inv_a
			if t < 0 then
				is_inside = true
				t = (-b + sq) * inv_a
			end
			if t >= 0 and t <= 1 and t < best_t and (aao + t * ad) >= length then
				best_t = t
				local hit = ray_origin + ray_direction * t
				best_normal = (hit - cap_b) * (1 / radius)
			end
		end
	end
	
	if best_t == HUGE then
		return nil, nil, nil, nil
	end
	
	local hit = ray_origin + ray_direction * best_t
	local dist = best_t * vector.magnitude(ray_direction :: any)
	return hit, dist, best_normal, is_inside
end

return {
	ray_box = ray_box,
	ray_sphere = ray_sphere,
	ray_capsule = ray_capsule
}