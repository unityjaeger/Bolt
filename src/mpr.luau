--!native
--!strict
--!optimize 2

local types = require("./types")
local constants = require("./constants")
local support_map = require("./support_map")

local FLT_EPSILON = constants.FLT_EPSILON
local ARBITRARY_DIR = vector.create(1e-3, 0, 0)

local CF_IDENT = CFrame.identity
local V3_ZERO = Vector3.zero

local ptws = CF_IDENT.PointToWorldSpace
local vtos = CF_IDENT.VectorToObjectSpace

local function intersects<T, U>(transform_b_in_a: CFrame, shape_a: T & types.Shape, shape_b: U & types.Shape, in_tolerance: number): (boolean, Vector3, number?, Vector3?, Vector3?)
	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]
	
	local center_b_in_a = transform_b_in_a.Position
	local v01 = V3_ZERO
	local v02 = center_b_in_a
	local v0 = v02 -- normally v02 - v01 but v01 is 0
	
	local point1
	local point2
	
	if vector.magnitude(v0 :: any) < FLT_EPSILON then
		v0 = ARBITRARY_DIR
	end
	
	local n = -v0 :: any
	local v11 = support_a(shape_a, -n :: any)
	local v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
	local v1 = v12 - v11
	if vector.dot(v1 :: any, n :: any) <= 0 then
		return false, -n :: any, nil, nil, nil
	end
	
	local n = vector.cross(v1 :: any, v0 :: any)
	if vector.magnitude(n) < FLT_EPSILON then
		return true, -vector.normalize(v1 - v0 :: any) :: any, vector.dot(n, v1 :: any), v11, v12
	end
	
	local v21 = support_a(shape_a, -n)
	local v22 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
	local v2 = v22 - v21
	if vector.dot(v2 :: any, n) <= 0 then
		return false, -n :: any, nil, nil, nil
	end
	
	n = vector.cross(v1 - v0 :: any, v2 - v0 :: any)
	local dist = vector.dot(n, v0 :: any)
	
	if dist > 0 then
		v1, v2 = v2, v1
		v11, v21 = v21, v11
		v12, v22 = v22, v12
		n = -n
	end
	
	while true do
		local v31 = support_a(shape_a, -n)
		local v32 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
		local v3 = v32 - v31
		if vector.dot(v3 :: any, n) <= 0 then
			return false, -n :: any, nil, nil, nil
		end
		
		if vector.dot(vector.cross(v1 :: any, v3 :: any), v0 :: any) < 0 then
			v2 = v3
			v21 = v31
			v22 = v32
			n = vector.cross(v1 - v0 :: any, v3 - v0 :: any)
			continue
		end
		
		if vector.dot(vector.cross(v3 :: any, v2 :: any), v0 :: any) < 0 then
			v1 = v3
			v11 = v31
			v12 = v32
			n = vector.cross(v3 - v0 :: any, v2 - v0 :: any)
			continue
		end
		
		local hit = false
		while true do
			n = vector.normalize(vector.cross(v2 - v1 :: any, v3 - v1 :: any))
			local d = vector.dot(n, v1 :: any)
			if d >= 0 and not hit then
				local b0 = vector.dot(vector.cross(v1 :: any, v2 :: any), v3 :: any)
				local b1 = vector.dot(vector.cross(v3 :: any, v2 :: any), v0 :: any)
				local b2 = vector.dot(vector.cross(v0 :: any, v1 :: any), v3 :: any)
				local b3 = vector.dot(vector.cross(v2 :: any, v1 :: any), v0 :: any)
				
				local sum = b0 + b1 + b2 + b3
				if sum <= 0 then
					b0 = 0
					b1 = vector.dot(vector.cross(v2 :: any, v3 :: any), n)
					b2 = vector.dot(vector.cross(v3 :: any, v1 :: any), n)
					b3 = vector.dot(vector.cross(v1 :: any, v2 :: any), n)
					
					sum = b1 + b2 + b3
				end
				
				local inv = 1 / sum
				
				point1 = (b0 * v01 + b1 * v11 + b2 * v21 + b3 * v31) * inv
				point2 = (b0 * v02 + b1 * v12 + b2 * v22 + b3 * v32) * inv
				
				hit = true
			end
			
			local v41 = support_a(shape_a, -n)
			local v42 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
			local v4 = v42 - v41
			
			local delta = vector.dot(v4 - v3 :: any, n)
			local seperation = -vector.dot(v4 :: any, n)
			
			if delta <= in_tolerance or seperation >= 0 then
				if hit then
					return true, -n :: any, -seperation, point1, point2
				else
					return false, -n :: any, nil, nil, nil
				end
			end
			
			local d1 = vector.dot(vector.cross(v4 :: any, v1 :: any), v0 :: any)
			local d2 = vector.dot(vector.cross(v4 :: any, v2 :: any), v0 :: any)
			local d3 = vector.dot(vector.cross(v4 :: any, v3 :: any), v0 :: any)
			
			if d1 < 0 then
				if d2 < 0 then
					v1 = v4
					v11 = v41
					v12 = v42
				else
					v3 = v4
					v31 = v41
					v32 = v42
				end
			else
				if d3 < 0 then
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
	end
end

local function is_seperated<T, U>(transform_b_in_a: CFrame, cached_normal: Vector3, shape_a: T & types.Shape, shape_b: U & types.Shape): boolean
	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]
	
	local v11 = support_a(shape_a, -cached_normal)
	local v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, cached_normal)))
	local v_test = v12 - v11
	if vector.dot(v_test :: any, cached_normal :: any) <= 0 then
		return true
	end
	
	return false
end

return {
	intersects = intersects,
	is_seperated = is_seperated
}