--!native
--!strict
--!optimize 2

local types = require("./types")
local constants = require("./constants")
local support_map = require("./support_map")

local MAX_ITER = 1000
local MAX_TOLERANCE = 1e-6
local FLT_EPSILON = constants.FLT_EPSILON

local CF_IDENT = CFrame.identity
local V3_ZERO = Vector3.zero
local SMALL_ZERO = Vector3.new(FLT_EPSILON * 10, 0, 0)

local ptws = CF_IDENT.PointToWorldSpace
local vtos = CF_IDENT.VectorToObjectSpace
local vtws = CF_IDENT.VectorToWorldSpace
local tos = CF_IDENT.ToObjectSpace

local function segment_dist(P: Vector3, x0: Vector3, b: Vector3): (number, Vector3)
	local d = b - x0
	local a = x0 - P
	
	local t = -vector.dot(a :: any, d :: any) / vector.dot(d :: any, d :: any)
	if t <= 0 then
		return vector.magnitude(x0 - P :: any), x0
	elseif t >= 1 then
		return vector.magnitude(b - P :: any), b
	else
		local w = d * t + x0
		return vector.magnitude(w - P :: any), w
	end
end

local function tri_dist(P: Vector3, x0: Vector3, B: Vector3, C: Vector3): (number, Vector3)
	local d1 = B - x0
	local d2 = C - x0
	local a = x0 - P
	
	local v = vector.dot(d1 :: any, d1 :: any)
	local w = vector.dot(d2 :: any, d2 :: any)
	local p = vector.dot(a :: any, d1 :: any)
	local q = vector.dot(a :: any, d2 :: any)
	local r = vector.dot(d1 :: any, d2 :: any)
	
	local s, t = 0, 0
	local div = (w * v - r * r)
	if math.abs(div) < FLT_EPSILON then
		s = -1
	else
		s = (q * r - w * p) / div
		t = (-s * r - q) / w
	end
	
	if s >= 0 and s <= 1 and t >= 0 and t <= 1 and t + s <= 1 then
		d1 *= s
		d2 *= t
		local witness = x0 + d1 + d2
		return vector.magnitude(witness - P :: any), witness
	else
		local dist, witness = segment_dist(P, x0, B)
		local dist2, witness2 = segment_dist(P, x0, C)
		if dist2 < dist then
			dist = dist2
			witness = witness2
		end
		
		dist2, witness2 = segment_dist(P, B, C)
		if dist2 < dist then
			dist = dist2
			witness = witness2
		end
		
		return dist, witness
	end
end

local function intersects<T, U>(cframe_a: CFrame, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, in_tolerance: number): (boolean, Vector3, number?, Vector3?)
	in_tolerance = math.max(in_tolerance, MAX_TOLERANCE)
	local transform_b_in_a = tos(cframe_a, cframe_b)

	local support_a = support_map[shape_a.type] :: any
	local support_b = support_map[shape_b.type]
	
	local center_b_in_a = transform_b_in_a.Position
	local v01 = V3_ZERO
	local v02 = center_b_in_a
	local v0 = -center_b_in_a

	if v0:FuzzyEq(V3_ZERO, FLT_EPSILON) then
		v0 = SMALL_ZERO
	end

	local dir = vector.normalize(-v0 :: any)
	
	local v11 = support_a(shape_a, dir)
	local v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -dir :: any)))
	local v1 = v11 - v12
	
	local dot = vector.dot(v1, dir)
	if dot < FLT_EPSILON then
		return false, vtws(cframe_a, -dir :: any), nil, nil
	end
	
	dir = vector.cross(v0 :: any, v1)
	if vector.dot(dir, dir) < FLT_EPSILON then
		if vector.magnitude(v1) < FLT_EPSILON then
			local pointB = ptws(cframe_a, v12)
			return true, V3_ZERO, 0, pointB
		else
			local out_normal = vtws(cframe_a, vector.normalize(v1) :: any)
			local depth = vector.magnitude(v1)
			local pointB = ptws(cframe_a, v12)
			return true, -out_normal, depth, pointB
		end
	end
	
	dir = vector.normalize(dir)
	local v21 = support_a(shape_a, dir)
	local v22 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -dir :: any)))
	local v2 = v21 - v22
	
	dot = vector.dot(v2, dir)
	if dot < FLT_EPSILON then
		return false, vtws(cframe_a, -dir :: any), nil, nil
	end
	
	local va = v1 - v0
	local vb = v2 - v0
	dir = vector.normalize(vector.cross(va, vb))
	
	dot = vector.dot(dir, v0 :: any)
	if dot > 0 then
		v1, v2 = v2, v1
		v11, v21 = v21, v11
		v12, v22 = v22, v12
		dir = -dir
	end
	
	local v31, v32, v3
	while true do
		v31 = support_a(shape_a, dir)
		v32 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -dir :: any)))
		v3 = v31 - v32
		local dot_v3 = vector.dot(v3, dir)
		if dot_v3 < FLT_EPSILON then
			return false, vtws(cframe_a, -dir :: any), nil, nil
		end
		
		local cont = false
		va = vector.cross(v1, v3)
		dot = vector.dot(va, v0 :: any)
		if dot <= -FLT_EPSILON then
			v2 = v3
			v21 = v31
			v22 = v32
			cont = true
		end
		
		if not cont then
			va = vector.cross(v3, v2)
			dot = vector.dot(va, v0 :: any)
			if dot <= -FLT_EPSILON then
				v1 = v3
				v11 = v31
				v12 = v32
				cont = true
			end
		end
		
		if cont then
			va = v1 - v0
			vb = v2 - v0
			dir = vector.normalize(vector.cross(va, vb))
		else
			break
		end
	end
	
	local success = false
	for i = 1, MAX_ITER do
		local v2v1 = v2 - v1
		local v3v1 = v3 - v1
		dir = vector.normalize(vector.cross(v2v1, v3v1))
		dot = vector.dot(dir, v1)
		if dot > -FLT_EPSILON then
			success = true
			break
		end
		
		local v41 = support_a(shape_a, dir)
		local v42 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -dir :: any)))
		local v4 = v41 - v42
		dot = vector.dot(v4, dir)
		if dot <= -FLT_EPSILON then
			return false, vtws(cframe_a, -dir :: any), nil, nil
		end
		
		local dv1 = vector.dot(v1, dir)
		local dv2 = vector.dot(v2, dir)
		local dv3 = vector.dot(v3, dir)
		local dv4 = vector.dot(v4, dir)
		
		local dot1 = dv4 - dv1
		local dot2 = dv4 - dv2
		local dot3 = dv4 - dv3
		
		dot1 = math.min(dot1, dot2, dot3)
		if dot1 <= in_tolerance then
			return false, vtws(cframe_a, -dir :: any), nil, nil
		end
		
		local v4v0 = vector.cross(v4, v0 :: any)
		dot = vector.dot(v1, v4v0)
		if dot > 0 then
			dot = vector.dot(v2, v4v0)
			if dot > 0 then
				v1 = v4
				v11 = v41
				v12 = v42
			else
				v3 = v4
				v31 = v41
				v32 = v42
			end
		else
			dot = vector.dot(v3, v4v0)
			if dot > 0 then
				v2 = v4
				v21 = v41
				v22 = v42
			else
				v1 = v4
				v11 = v41
				v12 = v42
			end
		end
	end
	
	if not success then
		return false, vtws(cframe_a, -dir :: any), nil, nil
	end
	
	local iterations = 0
	while true do
		local v2v1 = v2 - v1
		local v3v1 = v3 - v1
		dir = vector.normalize(vector.cross(v2v1, v3v1))
		
		local v41 = support_a(shape_a, dir)
		local v42 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -dir :: any)))
		local v4 = v41 - v42
		
		local dv1 = vector.dot(v1, dir)
		local dv2 = vector.dot(v2, dir)
		local dv3 = vector.dot(v3, dir)
		local dv4 = vector.dot(v4, dir)

		local dot1 = dv4 - dv1
		local dot2 = dv4 - dv2
		local dot3 = dv4 - dv3

		dot1 = math.min(dot1, dot2, dot3)
		if dot1 <= in_tolerance or iterations == MAX_ITER then
			local depth, witness = tri_dist(V3_ZERO, v1, v2, v3)
			local face_normal = vector.normalize(vector.cross(v2 - v1, v3 - v1))
			
			local witness_dot = vector.dot(face_normal, witness :: any)
			if witness_dot < 0 then
				face_normal = -face_normal
			end
			depth = math.abs(witness_dot)

			v2v1 = v2 - v1
			v3v1 = v3 - v1
			dir = vector.normalize(vector.cross(v2v1, v3v1))
			
			local b0 = vector.dot(vector.cross(v1, v2), v3)
			local b1 = vector.dot(vector.cross(v3, v2), v0 :: any)
			local b2 = vector.dot(vector.cross(v0 :: any, v1), v3)
			local b3 = vector.dot(vector.cross(v2, v1), v0 :: any)
			local sum = b0 + b1 + b2 + b3

			if math.abs(sum) < FLT_EPSILON then
				b0 = 0
				b1 = vector.dot(vector.cross(v2, v3), dir)
				b2 = vector.dot(vector.cross(v3, v1), dir)
				b3 = vector.dot(vector.cross(v1, v2), dir)
				sum = b1 + b2 + b3
			end
			
			local inv = 1 / sum
			local point_b = ptws(cframe_a, (b0 * v02 + b1 * v12 + b2 * v22 + b3 * v32 :: any) * inv)
			
			local out_normal = vtws(cframe_a, face_normal :: any)
			return true, -out_normal, depth, point_b
		end
		
		local v4v0 = vector.cross(v4, v0 :: any)
		dot = vector.dot(v1, v4v0)
		if dot > 0 then
			dot = vector.dot(v2, v4v0)
			if dot > 0 then
				v1 = v4
				v11 = v41
				v12 = v42
			else
				v3 = v4
				v31 = v41
				v32 = v42
			end
		else
			dot = vector.dot(v3, v4v0)
			if dot > 0 then
				v2 = v4
				v21 = v41
				v22 = v42
			else
				v1 = v4
				v11 = v41
				v12 = v42
			end
		end
		
		iterations += 1
	end
	
	return false, vtws(cframe_a, -dir :: any), nil, nil
end

local function is_separated<T, U>(cframe_a: CFrame, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, cached_normal: Vector3): boolean
	local transform_b_in_a = tos(cframe_a, cframe_b)
	local normal_in_a = vtos(cframe_a, cached_normal)

	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]

	local v11 = support_a(shape_a, -normal_in_a)
	local v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, normal_in_a)))
	local v_test = v12 - v11

	local gap = vector.dot(v_test :: any, normal_in_a :: any)
	return gap <= FLT_EPSILON
end

return {
	intersects = intersects,
	is_separated = is_separated
}