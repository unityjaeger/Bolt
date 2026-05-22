--!native
--!strict
--!optimize 2

local types = require("./types")
local constants = require("./constants")
local support_map = require("./support_map")

local FLT_EPSILON = constants.FLT_EPSILON
local X_AXIS = vector.create(1, 0, 0)
local Y_AXIS = vector.create(0, 1, 0)
local Z_AXIS = vector.create(0, 0, 1)

local CF_IDENT = CFrame.identity
local V3_ZERO = Vector3.zero

local ptws = CF_IDENT.PointToWorldSpace
local vtos = CF_IDENT.VectorToObjectSpace
local vtws = CF_IDENT.VectorToWorldSpace
local tos = CF_IDENT.ToObjectSpace

local function intersects<T, U>(cframe_a: CFrame, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, in_tolerance: number): (boolean, Vector3, number?, Vector3?)
	local transform_b_in_a = tos(cframe_a, cframe_b)
	
	local support_a = support_map[shape_a.type] :: any --idk why but it doesnt wanna infer
	local support_b = support_map[shape_b.type]
	
	local center_b_in_a = transform_b_in_a.Position
	local v01 = V3_ZERO
	local v02 = center_b_in_a
	local v0 = v02 -- normally v02 - v01 but v01 is 0
	
	local point
	
	--coincident centers :(
	if vector.magnitude(v0 :: any) < FLT_EPSILON then
		local dir = X_AXIS
		local vA = support_a(shape_a, -dir)
		local vB = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, dir :: any)))
		local diff = vB - vA
		local depth = -vector.dot(diff, dir)
		local world_center = ptws(cframe_a, v01)
		local world_normal = vtws(cframe_a, -dir :: any)
		return true, world_normal, depth, world_center
	end
	
	local n = -v0 :: any
	local v11 = support_a(shape_a, -n)
	local v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n)))
	local v1 = v12 - v11
	if vector.dot(v1 :: any, n) <= 0 then
		local world_normal = vtws(cframe_a, -n)
		return false, world_normal, nil, nil
	end
	
	n = vector.cross(v1 :: any, v0 :: any)
	--v1 is parallel to v0, gotta find something that lets us proceed to the iterative part
	if vector.magnitude(n) < FLT_EPSILON then
		n = vector.cross(v0 :: any, Y_AXIS)
		if vector.magnitude(n) < FLT_EPSILON then
			n = vector.cross(v0 :: any, Z_AXIS)
		end
		v11 = support_a(shape_a, -n)
		v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
		v1 = v12 - v11
		n = vector.cross(v1, v0 :: any)
	end
	
	local v21 = support_a(shape_a, -n)
	local v22 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
	local v2 = v22 - v21
	if vector.dot(v2, n) <= 0 then
		local world_normal = vtws(cframe_a, -n :: any)
		return false, world_normal, nil, nil
	end
	
	n = vector.cross(v1 - v0, v2 - v0)
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
		if vector.dot(v3, n) <= 0 then
			local world_normal = vtws(cframe_a, -n :: any)
			return false, world_normal, nil, nil
		end
		
		if vector.dot(vector.cross(v1, v3), v0 :: any) < 0 then
			v2 = v3
			v21 = v31
			v22 = v32
			n = vector.cross(v1 - v0, v3 - v0)
			continue
		end
		
		if vector.dot(vector.cross(v3, v2), v0 :: any) < 0 then
			v1 = v3
			v11 = v31
			v12 = v32
			n = vector.cross(v3 - v0, v2 - v0)
			continue
		end
		
		local hit = false
		while true do
			local cross_edge = vector.cross(v2 - v1, v3 - v1)
			local cross_len = vector.magnitude(cross_edge)
			if cross_len < FLT_EPSILON then
				--degenerate portal face
				n = X_AXIS
				point = v01
				hit = true
				break
			end
			
			n = cross_edge / cross_len
			
			local d = vector.dot(n, v1)
			if d >= 0 and not hit then
				local b0 = vector.dot(vector.cross(v1, v2), v3)
				local b1 = vector.dot(vector.cross(v3, v2), v0 :: any)
				local b2 = vector.dot(vector.cross(v0 :: any, v1), v3)
				local b3 = vector.dot(vector.cross(v2, v1), v0 :: any)
				
				local sum = b0 + b1 + b2 + b3
				if sum <= 0 then
					b0 = 0
					b1 = vector.dot(vector.cross(v2, v3), n)
					b2 = vector.dot(vector.cross(v3, v1), n)
					b3 = vector.dot(vector.cross(v1, v2), n)
					
					sum = b1 + b2 + b3
				end
				
				local inv = 1 / sum
				--see normally u would compute 2 points but theyre always the same so who caressss
				point = (b0 * v01 + b1 * v11 + b2 * v21 + b3 * v31) * inv
				
				hit = true
			end
			
			local v41 = support_a(shape_a, -n)
			local v42 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, n :: any)))
			local v4 = v42 - v41
			
			local delta = vector.dot(v4 - v3, n)
			local seperation = -vector.dot(v4, n)
			
			if delta <= in_tolerance or seperation >= 0 then
				local world_normal = vtws(cframe_a, -n :: any)
				if hit then
					local world_p = ptws(cframe_a, point)
					return true, world_normal, -seperation, world_p
				else
					return false, world_normal, nil, nil
				end
			end
			
			local d1 = vector.dot(vector.cross(v4 :: any, v1 :: any), v0 :: any)
			if d1 < 0 then
				local d2 = vector.dot(vector.cross(v4 :: any, v2 :: any), v0 :: any)
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
				local d3 = vector.dot(vector.cross(v4 :: any, v3 :: any), v0 :: any)
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

local function is_separated<T, U>(cframe_a: CFrame, shape_a: T & types.Shape, cframe_b: CFrame, shape_b: U & types.Shape, cached_normal: Vector3): boolean
	local transform_b_in_a = tos(cframe_a, cframe_b)
	local normal_in_a = vtos(cframe_a, cached_normal)
	
	local support_a = support_map[shape_a.type]
	local support_b = support_map[shape_b.type]

	local v11 = support_a(shape_a, normal_in_a)
	local v12 = ptws(transform_b_in_a, support_b(shape_b, vtos(transform_b_in_a, -normal_in_a)))
	local v_test = v12 - v11

	local gap = vector.dot(v_test :: any, normal_in_a :: any)
	return gap > FLT_EPSILON
end

return {
	intersects = intersects,
	is_separated = is_separated
}