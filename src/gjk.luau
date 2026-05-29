--!native
--!strict
--!optimize 2

local types = require("./types")
local constants = require("./constants")
local support_map = require("./support_map")

local FLT_EPSILON = constants.FLT_EPSILON
local FLT_EPSILON_SQ = FLT_EPSILON * FLT_EPSILON
local HUGE = constants.HUGE

local V_ZERO = Vector3.zero
local CF_IDENT = CFrame.identity

local ptws = CF_IDENT.PointToWorldSpace
local vtws = CF_IDENT.VectorToWorldSpace
local vtos = CF_IDENT.VectorToObjectSpace
local ptos = CF_IDENT.PointToObjectSpace
local tos = CF_IDENT.ToObjectSpace

local m_num_points = 0
local m_y = table.create(4) :: {Vector3}
local m_p = table.create(4) :: {Vector3}
local m_q = table.create(4) :: {Vector3}

local function get_barycentric_coordinates_2d(in_a: Vector3, in_b: Vector3): (number, number)
	local ab = in_b - in_a
	local denominator = vector.dot(ab :: any, ab :: any)
	if denominator < FLT_EPSILON_SQ then
		if vector.dot(in_a :: any, in_a :: any) < vector.dot(in_b :: any, in_b :: any) then
			return 1, 0
		else
			return 0, 1
		end
	else
		local v = -vector.dot(in_a :: any, ab :: any) / denominator
		return 1 - v, v
	end
end

local function get_barycentric_coordinates_3d(in_a: Vector3, in_b: Vector3, in_c: Vector3): (number, number, number)
	local v0 = in_b - in_a
	local v1 = in_c - in_a
	local v2 = in_c - in_b

	local d00 = vector.dot(v0 :: any, v0 :: any)
	local d11 = vector.dot(v1 :: any, v1 :: any)
	local d22 = vector.dot(v2 :: any, v2 :: any)
	if d00 <= d22 then
		local d01 = vector.dot(v0 :: any, v1 :: any)

		local denominator = d00 * d11 - d01 * d01
		if denominator < 1e-12 then
			if d00 > d11 then
				local u, v = get_barycentric_coordinates_2d(in_a, in_b)
				return u, v, 0
			else
				local u, w = get_barycentric_coordinates_2d(in_a, in_c)
				return u, 0, w
			end
		else
			local a0 = vector.dot(in_a :: any, v0 :: any)
			local a1 = vector.dot(in_a :: any, v1 :: any)
			local v = (d01 * a1 - d11 * a0) / denominator
			local w = (d01 * a0 - d00 * a1) / denominator
			return 1 - v - w, v, w
		end
	else
		local d12 = vector.dot(v1 :: any, v2 :: any)
		local denominator = d11 * d22 - d12 * d12
		if denominator < 1e-12 then
			if d11 > d22 then
				local u, w = get_barycentric_coordinates_2d(in_a, in_c)
				return u, 0, w
			else
				local v, w = get_barycentric_coordinates_2d(in_b, in_c)
				return 0, v, w
			end
		else
			local c1 = vector.dot(in_c :: any, v1 :: any)
			local c2 = vector.dot(in_c :: any, v2 :: any)
			local u = (d22 * c1 - d12 * c2) / denominator
			local v = (d11 * c2 - d12 * c1) / denominator
			return u, v, 1 - u - v
		end
	end
end

local function get_closest_point_on_line(in_a: Vector3, in_b: Vector3): (Vector3, number)
	local u, v = get_barycentric_coordinates_2d(in_a, in_b)
	if v <= 0 then
		return in_a, 0b0001
	elseif u <= 0 then
		return in_b, 0b0010
	else
		return u * in_a + v * in_b, 0b0011
	end
end

local function get_closest_point_on_triangle(in_a: Vector3, in_b: Vector3, in_c: Vector3, must_include_c: boolean): (Vector3, number)
	local temp_ac = in_c - in_a
	local bc = in_c - in_b

	local swap = vector.dot(bc :: any, bc :: any) < vector.dot(temp_ac :: any, temp_ac :: any)
	local a = swap and in_c or in_a
	local c = swap and in_a or in_c

	local ab = in_b - a
	local ac = c - a
	local n = vector.cross(ab :: any, ac :: any)
	local n_len_sq = vector.dot(n :: any, n :: any)

	if n_len_sq < 1e-10 then
		local closest_set = 0b0100
		local closest_point = in_c
		local best_dist_sq = vector.dot(in_c :: any, in_c :: any)

		if not must_include_c then
			local a_len_sq = vector.dot(in_a :: any, in_a :: any)
			if a_len_sq < best_dist_sq then
				closest_set = 0b0001
				closest_point = in_a
				best_dist_sq = a_len_sq
			end

			local b_len_sq = vector.dot(in_b :: any, in_b :: any)
			if b_len_sq < best_dist_sq then
				closest_set = 0b0010
				closest_point = in_b
				best_dist_sq = b_len_sq
			end
		end

		local ac_len_sq = vector.dot(ac :: any, ac :: any)
		if ac_len_sq > FLT_EPSILON_SQ then
			local v = math.clamp(-vector.dot(a :: any, ac :: any) / ac_len_sq, 0, 1)
			local q = a + v * ac
			local dist_sq = vector.dot(q :: any, q :: any)
			if dist_sq < best_dist_sq then
				closest_set = 0b0101
				closest_point = q
				best_dist_sq = dist_sq
			end
		end

		local bc_len_sq = vector.dot(bc :: any, bc :: any)
		if bc_len_sq > FLT_EPSILON_SQ then
			local v = math.clamp(-vector.dot(in_b :: any, bc :: any) / bc_len_sq, 0, 1)
			local q = in_b + v * bc
			local dist_sq = vector.dot(q :: any, q :: any)
			if dist_sq < best_dist_sq then
				closest_set = 0b0110
				closest_point = q
				best_dist_sq = dist_sq
			end
		end

		if not must_include_c then
			local ab = in_b - in_a
			local ab_len_sq = vector.dot(ab :: any, ab :: any)
			if ab_len_sq > FLT_EPSILON_SQ then
				local v = math.clamp(-vector.dot(in_a :: any, ab :: any) / ab_len_sq, 0, 1)
				local q = in_a + v * ab
				local dist_sq = vector.dot(q :: any, q :: any)
				if dist_sq < best_dist_sq then
					closest_set = 0b0011
					closest_point = q
					best_dist_sq = dist_sq
				end
			end
		end

		return closest_point, closest_set
	end

	local ap = -a
	local d1 = vector.dot(ab :: any, ap :: any)
	local d2 = vector.dot(ac :: any, ap :: any)
	if d1 <= 0 and d2 <= 0 then
		return a, swap and 0b0100 or 0b0001
	end

	local bp = -in_b
	local d3 = vector.dot(ab :: any, bp :: any)
	local d4 = vector.dot(ac :: any, bp :: any)
	if d3 >= 0 and d4 <= d3 then
		return in_b, 0b0010
	end

	if d1 * d4 <= d3 * d2 and d1 >= 0 and d3 <= 0 then
		local v = d1 / (d1 - d3)
		return a + v * ab, swap and 0b0110 or 0b0011
	end

	local cp = -c
	local d5 = vector.dot(ab :: any, cp :: any)
	local d6 = vector.dot(ac :: any, cp :: any)
	if d6 >= 0 and d5 <= d6 then
		return c, swap and 0b0001 or 0b0100
	end

	if d5 * d2 <= d1 * d6 and d2 >= 0 and d6 <= 0 then
		local w = d2 / (d2 - d6)
		return a + w * ac, 0b0101
	end

	local d4_d3 = d4 - d3;
	local d5_d6 = d5 - d6;
	if d3 * d6 <= d5 * d4 and d4_d3 >= 0 and d5_d6 >= 0 then
		local w = d4_d3 / (d4_d3 + d5_d6)
		return in_b + w * (c - in_b), swap and 0b0011 or 0b0110
	end

	return n * vector.dot(a + in_b + c :: any, n :: any) / (3 * n_len_sq) :: any, 0b0111
end

local function origin_outside_of_tetrahedron_planes(in_a: Vector3, in_b: Vector3, in_c: Vector3, in_d: Vector3): number
	local ab = in_b - in_a
	local ac = in_c - in_a
	local ad = in_d - in_a

	local nABC = vector.cross(ab :: any, ac :: any)
	local nACD = vector.cross(ac :: any, ad :: any)
	local nADB = vector.cross(ad :: any, ab :: any)
	local nBDC = vector.cross(in_d - in_b :: any, in_c - in_b :: any)

	local signd0 = vector.dot(ad :: any, nABC) --d
	local signd1 = vector.dot(ab :: any, nACD) --b
	local signd2 = vector.dot(ac :: any, nADB) --c
	local signd3 = -vector.dot(ab :: any, nBDC) --a

	local all_positive = signd0 >= 0 and signd1 >= 0 and signd2 >= 0 and signd3 >= 0
	local all_negative = signd0 <= 0 and signd1 <= 0 and signd2 <= 0 and signd3 <= 0
	if not all_positive and not all_negative then
		return 0xF
	end

	local signp0 = vector.dot(in_a :: any, nABC) --abc
	local signp1 = vector.dot(in_a :: any, nACD) --acd
	local signp2 = vector.dot(in_a :: any, nADB) --adb
	local signp3 = vector.dot(in_b :: any, nBDC) --bdc

	if all_positive then
		return 
			(signp0 >= -FLT_EPSILON and 1 or 0) +
			(signp1 >= -FLT_EPSILON and 2 or 0) +
			(signp2 >= -FLT_EPSILON and 4 or 0) +
			(signp3 >= -FLT_EPSILON and 8 or 0)
	else
		return
			(signp0 <= FLT_EPSILON and 1 or 0) +
			(signp1 <= FLT_EPSILON and 2 or 0) +
			(signp2 <= FLT_EPSILON and 4 or 0) +
			(signp3 <= FLT_EPSILON and 8 or 0)
	end
end

local function get_closest_point_on_tetrahedron(in_a: Vector3, in_b: Vector3, in_c: Vector3, in_d: Vector3, must_include_d: boolean): (Vector3, number)
	local closest_set = 0b1111
	local closest_point = V_ZERO
	local best_dist_sq = HUGE

	local origin_out_of_planes = origin_outside_of_tetrahedron_planes(in_a, in_b, in_c, in_d)

	if bit32.band(origin_out_of_planes, 1) == 1 then
		if must_include_d then
			closest_set = 0b0001
			closest_point = in_a
		else
			closest_point, closest_set = get_closest_point_on_triangle(in_a, in_b, in_c, false)
		end

		best_dist_sq = vector.dot(closest_point :: any, closest_point :: any)
	end

	if bit32.band(origin_out_of_planes, 2) == 2 then
		local q, set = get_closest_point_on_triangle(in_a, in_c, in_d, must_include_d)
		local dist_sq = vector.dot(q :: any, q :: any)
		if dist_sq < best_dist_sq then
			best_dist_sq = dist_sq
			closest_point = q
			closest_set = bit32.band(set, 0b0001) + bit32.lshift(bit32.band(set, 0b0110), 1)
		end
	end

	if bit32.band(origin_out_of_planes, 4) == 4 then
		local q, set = get_closest_point_on_triangle(in_a, in_b, in_d, must_include_d)
		local dist_sq = vector.dot(q :: any, q :: any)
		if dist_sq < best_dist_sq then
			best_dist_sq = dist_sq
			closest_point = q
			closest_set = bit32.band(set, 0b0011) + bit32.lshift(bit32.band(set, 0b0100), 1)
		end
	end

	if bit32.band(origin_out_of_planes, 8) == 8 then
		local q, set = get_closest_point_on_triangle(in_b, in_c, in_d, must_include_d)
		local dist_sq = vector.dot(q :: any, q :: any)
		if dist_sq < best_dist_sq then
			closest_point = q
			closest_set = bit32.lshift(set, 1)
		end
	end

	return closest_point, closest_set
end

local function get_closest(prev_v_len_sq: number, io_v: Vector3, last_point_part_of_closest_feature: boolean): (boolean, Vector3, number, number)
	local v, set

	if m_num_points == 1 then
		--single point
		set = 0b0001
		v = m_y[1]
	elseif m_num_points == 2 then
		--line segment
		v, set = get_closest_point_on_line(m_y[1], m_y[2])
	elseif m_num_points == 3 then
		--triangle
		v, set = get_closest_point_on_triangle(m_y[1], m_y[2], m_y[3], last_point_part_of_closest_feature)
	elseif m_num_points == 4 then
		--tetrahedron
		v, set = get_closest_point_on_tetrahedron(m_y[1], m_y[2], m_y[3], m_y[4], last_point_part_of_closest_feature)
	else
		return false, io_v, prev_v_len_sq, 0
	end

	local v_len_sq = vector.dot(v :: any, v :: any)
	if v_len_sq < prev_v_len_sq then
		return true, v, v_len_sq, set
	end

	return false, io_v, prev_v_len_sq, 0
end

local function get_max_y_length_sq(): number
	local y_len_sq = vector.dot(m_y[1] :: any, m_y[1] :: any)
	for i = 2, m_num_points do
		y_len_sq = math.max(y_len_sq, vector.dot(m_y[i] :: any, m_y[i] :: any))
	end
	return y_len_sq
end

local function update_point_set_y(set: number)
	local num_points = 0
	for i = 1, m_num_points do
		if (bit32.band(set, bit32.lshift(1, i - 1)) ~= 0) then
			num_points += 1
			m_y[num_points] = m_y[i]
		end
	end
	m_num_points = num_points
end

local function update_point_set_p(set: number)
	local num_points = 0
	for i = 1, m_num_points do
		if (bit32.band(set, bit32.lshift(1, i - 1)) ~= 0) then
			num_points += 1
			m_p[num_points] = m_p[i]
		end
	end
	m_num_points = num_points
end

local function update_point_set_pq(set: number)
	local num_points = 0
	for i = 1, m_num_points do
		if (bit32.band(set, bit32.lshift(1, i - 1)) ~= 0) then
			num_points += 1
			m_p[num_points] = m_p[i]
			m_q[num_points] = m_q[i]
		end
	end
	m_num_points = num_points
end

local function intersects<T, U>(cframe_a: CFrame, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, in_tolerance: number, io_v: Vector3?): (boolean, Vector3)
	io_v = io_v or V_ZERO

	local transform_b_in_a = tos(cframe_a, cframe_b)

	local tolerance_sq = in_tolerance * in_tolerance

	m_num_points = 0

	local prev_v_len_sq = HUGE

	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]

	while true do
		local p = support_a(shape_a, io_v)
		local q = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -io_v)))
		local w = p - q

		if vector.dot(io_v :: any, w :: any) < 0 then
			return false, io_v
		end

		m_num_points += 1
		m_y[m_num_points] = w

		local success, v_len_sq, set
		success, io_v, v_len_sq, set = get_closest(prev_v_len_sq, io_v, true)
		if not success then
			return false, io_v
		end

		if set == 0xF then
			return true, V_ZERO
		end

		if v_len_sq <= tolerance_sq then
			return true, V_ZERO
		end

		if prev_v_len_sq <= FLT_EPSILON * get_max_y_length_sq() then
			return true, V_ZERO
		end

		io_v = -io_v

		if prev_v_len_sq - v_len_sq <= FLT_EPSILON * prev_v_len_sq then
			return false, io_v
		end

		prev_v_len_sq = v_len_sq
		update_point_set_y(set)
	end
end

local function raycast<T>(ray_origin: Vector3, ray_direction: Vector3, cframe: CFrame, shape: T & types.Shape, in_tolerance: number): (Vector3?, number?, Vector3?)
	local local_origin = ptos(cframe, ray_origin)
	local local_direction = vtos(cframe, ray_direction)

	local tolerance_sq = in_tolerance * in_tolerance

	local support = support_map[shape.type]

	m_num_points = 0

	local lambda = 0
	local x = local_origin
	local v = x - support(shape, V_ZERO)
	local v_len_sq = HUGE
	local allow_restart = false

	local out_normal

	while true do
		local p = support(shape, v)
		local w = x - p

		local v_dot_w = vector.dot(v :: any, w :: any)
		if v_dot_w > 0 then
			local v_dot_r = vector.dot(v :: any, local_direction :: any)
			if v_dot_r >= -1e-18 then
				return nil, nil, nil
			end

			local delta = v_dot_w / v_dot_r
			local old_lambda = lambda
			lambda -= delta

			if old_lambda == lambda then
				break
			end

			if lambda >= 1 then
				return nil, nil, nil
			end

			out_normal = v
			x = local_origin + lambda * local_direction
			v_len_sq = HUGE
			allow_restart = true
		end

		m_num_points += 1
		m_p[m_num_points] = p

		for i = 1, m_num_points do
			m_y[i] = x - m_p[i]
		end

		local success, set
		success, v, v_len_sq, set = get_closest(v_len_sq, v, false)
		if not success then
			if not allow_restart then
				break
			end

			allow_restart = false
			m_p[1] = p
			m_num_points = 1
			v = x - p
			v_len_sq = HUGE
			continue
		elseif set == 0xF then
			break
		end

		update_point_set_p(set)

		if v_len_sq <= tolerance_sq then
			break
		end
	end

	out_normal = out_normal and vector.normalize(out_normal :: any) or V_ZERO
	local world_normal = vtws(cframe, out_normal :: any)
	local world_point = ptws(cframe, x)

	return world_point, lambda * vector.magnitude(ray_direction :: any), world_normal
end

local function shapecast_simple<T, U>(cframe_a: CFrame, direction: Vector3, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, in_tolerance: number): (boolean, number?)
	local local_start = tos(cframe_b, cframe_a)
	local local_direction = vtos(cframe_b, direction)

	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]

	local tolerance_sq = in_tolerance * in_tolerance

	m_num_points = 0

	local lambda = 0
	local x = V_ZERO
	local v = ptws(local_start, support_a(shape_a, V_ZERO)) - support_b(shape_b, V_ZERO)
	local v_len_sq = HUGE
	local allow_restart = false

	while true do
		local p = support_b(shape_b, v) - ptws(local_start, support_a(shape_a, vtos(local_start, -v)))
		local w = x - p

		local v_dot_w = vector.dot(v :: any, w :: any)
		if v_dot_w > 0 then
			local v_dot_r = vector.dot(v :: any, local_direction :: any)
			if v_dot_r >= -1e-18 then
				return false, nil
			end

			local delta = v_dot_w / v_dot_r
			local old_lambda = lambda
			lambda -= delta

			if old_lambda == lambda then
				break
			end

			if lambda >= 1 then
				return false, nil
			end

			x = lambda * local_direction
			v_len_sq = HUGE
			allow_restart = true
		end

		m_num_points += 1
		m_p[m_num_points] = p

		for i = 1, m_num_points do
			m_y[i] = x - m_p[i]
		end

		local success, set
		success, v, v_len_sq, set = get_closest(v_len_sq, v, false)
		if not success then
			if not allow_restart then
				break
			end

			allow_restart = false
			m_p[1] = p
			m_num_points = 1
			v = x - p
			v_len_sq = HUGE
			continue
		elseif set == 0xF then
			break
		end

		update_point_set_p(set)

		if v_len_sq <= tolerance_sq then
			break
		end
	end

	return true, lambda * vector.magnitude(direction :: any) :: any
end

local function shapecast<T, U>(cframe_a: CFrame, direction: Vector3, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, in_tolerance: number): (Vector3?, number?, Vector3?)
	local local_start = tos(cframe_b, cframe_a)
	local local_direction = vtos(cframe_b, direction)

	local convex_radius_a = shape_a.convex_radius
	local convex_radius_b = shape_b.convex_radius

	local tolerance_sq = in_tolerance * in_tolerance
	local sum_convex_radius = convex_radius_a + convex_radius_b

	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]

	m_num_points = 0

	local lambda = 0
	local x = V_ZERO
	local v = -support_b(shape_b, V_ZERO) + ptws(local_start, support_a(shape_a, V_ZERO))
	local v_len_sq = HUGE
	local allow_restart = false

	local prev_v = V_ZERO
	while true do
		local p = ptws(local_start, support_a(shape_a, vtos(local_start, -v)))
		local q = support_b(shape_b, v)
		local w = x - (q - p)

		local v_dot_w = vector.dot(v :: any, w :: any) - sum_convex_radius * vector.magnitude(v :: any)
		if v_dot_w > 0 then
			local v_dot_r = vector.dot(v :: any, local_direction :: any)
			if v_dot_r >= -1e-18 then
				return nil, nil, nil
			end

			local delta = v_dot_w / v_dot_r
			local old_lambda = lambda
			lambda -= delta

			if old_lambda == lambda then
				break
			end

			if lambda >= 1 then
				return nil, nil, nil
			end

			x = lambda * local_direction
			v_len_sq = HUGE
			local _tolerance = (in_tolerance + sum_convex_radius)
			tolerance_sq = _tolerance * _tolerance
			allow_restart = true
		end

		m_num_points += 1
		m_p[m_num_points] = p
		m_q[m_num_points] = q

		for i = 1, m_num_points do
			m_y[i] = x - (m_q[i] - m_p[i])
		end

		local success, set
		success, v, v_len_sq, set = get_closest(v_len_sq, v, false)
		if not success then
			if not allow_restart then
				break
			end

			allow_restart = false
			m_p[1] = p
			m_q[1] = q
			m_num_points = 1
			v = x - q
			v_len_sq = HUGE
			continue
		elseif set == 0xF then
			break
		end

		update_point_set_pq(set)

		if v_len_sq <= tolerance_sq then
			break
		end

		prev_v = v
	end

	for i = 1, m_num_points do
		m_y[i] = x - (m_q[i] - m_p[i])
	end

	local normalized_v = vector.dot(v :: any, v :: any) < FLT_EPSILON and V_ZERO or vector.normalize(v :: any) :: any
	local offset_b = convex_radius_b * normalized_v

	local point
	if m_num_points == 1 then
		point = m_q[1] + offset_b
	elseif m_num_points == 2 then
		local bu, bv = get_barycentric_coordinates_2d(m_y[1], m_y[2])
		point = bu * m_q[1] + bv * m_q[2] + offset_b
	elseif m_num_points == 3 or m_num_points == 4 then
		local bu, bv, bw = get_barycentric_coordinates_3d(m_y[1], m_y[2], m_y[3])
		point = bu * m_q[1] + bv * m_q[2] + bw * m_q[3] + offset_b
	end

	local out_normal = sum_convex_radius > 0 and normalized_v or vector.dot(prev_v :: any, prev_v :: any) < FLT_EPSILON and V_ZERO or vector.normalize(prev_v :: any)
	local world_normal = vtws(cframe_b, out_normal)
	local world_hit = ptws(cframe_b, point)

	return world_hit, lambda * vector.magnitude(local_direction :: any), world_normal
end

return {
	intersects = intersects,
	raycast = raycast,
	shapecast_simple = shapecast_simple,
	shapecast = shapecast
}