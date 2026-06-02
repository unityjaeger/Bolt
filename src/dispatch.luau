--!strict
--!native
--!optimize 2

local types = require("./types")
local shape_map = require("./shape_map")
local gjk = require("./gjk")
local mpr = require("./mpr")
local constants = require("./constants")

local HUGE = constants.HUGE
local CF_IDENT = CFrame.identity

local tos = CF_IDENT.ToObjectSpace
local vtos = CF_IDENT.VectorToObjectSpace
local ptos = CF_IDENT.PointToObjectSpace

local function dispatch_gjk_intersects<T, U>(
	cframe_a: CFrame, 
	shape_a: T & types.Shape, 
	cframe_b: CFrame, 
	shape_b: U & types.Shape, 
	in_tolerance: number
): boolean
	local is_mesh_a = shape_a.type == shape_map.MESH
	local is_mesh_b = shape_b.type == shape_map.MESH
	
	if not is_mesh_a and not is_mesh_b then
		local hit = gjk.intersects(cframe_a, shape_a, cframe_b, shape_b, in_tolerance)
		if hit then
			return true
		end
	elseif not is_mesh_a and is_mesh_b then
		local in_b = tos(cframe_b, cframe_a)
		local hulls = (shape_b :: types.MeshShape).hulls
		for _, hull_id in (shape_b :: types.MeshShape).local_tree:query_shape(in_b, shape_a) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_b * CFrame.new(hull.offset * hull.scale)
			local hit = gjk.intersects(cframe_a, shape_a, hull_cf, hull, in_tolerance)
			if hit then
				return true
			end
		end
	elseif is_mesh_a and not is_mesh_b then
		local in_a = tos(cframe_a, cframe_b)
		local hulls = (shape_a :: types.MeshShape).hulls
		for _, hull_id in (shape_a :: types.MeshShape).local_tree:query_shape(in_a, shape_b) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_a * CFrame.new(hull.offset * hull.scale)
			local hit = gjk.intersects(hull_cf, hull, cframe_b, shape_b, in_tolerance)
			if hit then
				return true
			end
		end
	else
		local hulls_a = (shape_a :: types.MeshShape).hulls
		local hulls_b = (shape_b :: types.MeshShape).hulls
		local local_tree_b = (shape_b :: types.MeshShape).local_tree
		for _, hull_a in hulls_a do
			local hull_a_cf = cframe_a * CFrame.new(hull_a.offset * hull_a.scale)
			local in_b = tos(cframe_b, hull_a_cf)
			for _, hull_b_id in local_tree_b:query_shape(in_b, hull_a) do
				local hull_b = hulls_b[hull_b_id]
				local hull_b_cf = cframe_b * CFrame.new(hull_b.offset * hull_b.scale)
				local hit = gjk.intersects(hull_a_cf, hull_a, hull_b_cf, hull_b, in_tolerance)
				if hit then
					return true
				end
			end
		end
	end
	
	return false
end

--raycast
local function dispatch_gjk_raycast<T, U>(
	ray_origin: Vector3,
	ray_direction: Vector3,
	cframe: CFrame,
	shape: T & types.Shape,
	in_tolerance: number
): (Vector3?, number?, Vector3?)
	local is_mesh = shape.type == shape_map.MESH
	
	local best_distance = HUGE
	local out_point : Vector3?, out_distance: number?, out_normal: Vector3? = nil, nil, nil
	
	if not is_mesh then
		return gjk.raycast(ray_origin, ray_direction, cframe, shape, in_tolerance)
	else
		local hulls = (shape :: types.MeshShape).hulls
		local local_origin = ptos(cframe, ray_origin)
		local local_direction = vtos(cframe, ray_direction)
		for _, hull_id in (shape :: types.MeshShape).local_tree:query_ray(local_origin, local_direction) do
			local hull = hulls[hull_id]
			local hull_cf = cframe * CFrame.new(hull.offset * hull.scale)
			local point, distance, normal = gjk.raycast(ray_origin, ray_direction, hull_cf, hull, in_tolerance)
			if distance and distance < best_distance then
				best_distance = distance
				out_point = point
				out_distance = distance
				out_normal = normal
			end
		end
	end
	
	return out_point, out_distance, out_normal
end

--shapecast_simple
local function dispatch_gjk_shapecast_simple<T, U>(
	cframe_a: CFrame,
	direction: Vector3,
	shape_a: T & types.Shape,
	cframe_b: CFrame,
	shape_b: U & types.Shape,
	in_tolerance: number
): (boolean, number?)
	local is_mesh_a = shape_a.type == shape_map.MESH
	local is_mesh_b = shape_b.type == shape_map.MESH
	
	local best_distance = HUGE
	local out_distance: number? = nil
	
	if not is_mesh_a and not is_mesh_b then
		return gjk.shapecast_simple(cframe_a, direction, shape_a, cframe_b, shape_b, in_tolerance)
	elseif not is_mesh_a and is_mesh_b then
		local hulls = (shape_b :: types.MeshShape).hulls
		local local_origin = tos(cframe_b, cframe_a)
		local local_direction = vtos(cframe_b, direction)
		for _, hull_id in (shape_b :: types.MeshShape).local_tree:query_shapecast(shape_a, local_origin, local_direction) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_b * CFrame.new(hull.offset * hull.scale)
			local _, distance = gjk.shapecast_simple(cframe_a, direction, shape_a, hull_cf, hull, in_tolerance)
			if distance and distance < best_distance then
				best_distance = distance
				out_distance = distance
			end
		end
	elseif is_mesh_a and not is_mesh_b then
		local hulls = (shape_a :: types.MeshShape).hulls
		local local_origin = tos(cframe_a, cframe_b)
		local local_direction = vtos(cframe_a, direction)
		for _, hull_id in (shape_a :: types.MeshShape).local_tree:query_shapecast(shape_b, local_origin, -local_direction) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_a * CFrame.new(hull.offset * hull.scale)
			local _, distance = gjk.shapecast_simple(hull_cf, direction, hull, cframe_b, shape_b, in_tolerance)
			if distance and distance < best_distance then
				best_distance = distance
				out_distance = distance
			end
		end
	else
		local hulls_a = (shape_a :: types.MeshShape).hulls
		local hulls_b = (shape_b :: types.MeshShape).hulls
		local local_tree_b = (shape_b :: types.MeshShape).local_tree
		for hull_a_id, hull_a in hulls_a do
			local hull_a_cf = cframe_a * CFrame.new(hull_a.offset * hull_a.scale)
			local local_origin = tos(cframe_b, hull_a_cf)
			local local_direction = vtos(cframe_b, direction)
			for _, hull_b_id in local_tree_b:query_shapecast(hull_a, local_origin, local_direction) do
				local hull_b = hulls_b[hull_b_id]
				local hull_b_cf = cframe_b * CFrame.new(hull_b.offset * hull_b.scale)
				local _, distance = gjk.shapecast_simple(hull_a_cf, direction, hull_a, hull_b_cf, hull_b, in_tolerance)
				if distance and distance < best_distance then
					best_distance = distance
					out_distance = distance
				end
			end
		end
	end
	
	return out_distance ~= nil, out_distance
end

local function dispatch_gjk_shapecast<T, U>(
	cframe_a: CFrame,
	direction: Vector3,
	shape_a: T & types.Shape,
	cframe_b: CFrame,
	shape_b: U & types.Shape,
	in_tolerance: number
): (Vector3?, number?, Vector3?)
	local is_mesh_a = shape_a.type == shape_map.MESH
	local is_mesh_b = shape_b.type == shape_map.MESH

	local best_distance = HUGE
	local out_point : Vector3?, out_distance: number?, out_normal: Vector3? = nil, nil, nil

	if not is_mesh_a and not is_mesh_b then
		return gjk.shapecast(cframe_a, direction, shape_a, cframe_b, shape_b, in_tolerance)
	elseif not is_mesh_a and is_mesh_b then
		local hulls = (shape_b :: types.MeshShape).hulls
		local local_origin = tos(cframe_b, cframe_a)
		local local_direction = vtos(cframe_b, direction)
		for _, hull_id in (shape_b :: types.MeshShape).local_tree:query_shapecast(shape_a, local_origin, local_direction) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_b * CFrame.new(hull.offset * hull.scale)
			local point, distance, normal = gjk.shapecast(cframe_a, direction, shape_a, hull_cf, hull, in_tolerance)
			if distance and distance < best_distance then
				best_distance = distance
				out_distance = distance
				out_point = point
				out_normal = normal
			end
		end
	elseif is_mesh_a and not is_mesh_b then
		local hulls = (shape_a :: types.MeshShape).hulls
		local local_origin = tos(cframe_a, cframe_b)
		local local_direction = vtos(cframe_a, direction)
		for _, hull_id in (shape_a :: types.MeshShape).local_tree:query_shapecast(shape_b, local_origin, -local_direction) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_a * CFrame.new(hull.offset * hull.scale)
			local point, distance, normal = gjk.shapecast(hull_cf, direction, hull, cframe_b, shape_b, in_tolerance)
			if distance and distance < best_distance then
				best_distance = distance
				out_distance = distance
				out_point = point
				out_normal = normal
			end
		end
	else
		local hulls_a = (shape_a :: types.MeshShape).hulls
		local hulls_b = (shape_b :: types.MeshShape).hulls
		local local_tree_b = (shape_b :: types.MeshShape).local_tree
		for hull_a_id, hull_a in hulls_a do
			local hull_a_cf = cframe_a * CFrame.new(hull_a.offset * hull_a.scale)
			local local_origin = tos(cframe_b, hull_a_cf)
			local local_direction = vtos(cframe_b, direction)
			for _, hull_b_id in local_tree_b:query_shapecast(hull_a, local_origin, local_direction) do
				local hull_b = hulls_b[hull_b_id]
				local hull_b_cf = cframe_b * CFrame.new(hull_b.offset * hull_b.scale)
				local point, distance, normal = gjk.shapecast(hull_a_cf, direction, hull_a, hull_b_cf, hull_b, in_tolerance)
				if distance and distance < best_distance then
					best_distance = distance
					out_distance = distance
					out_point = point
					out_normal = normal
				end
			end
		end
	end

	return out_point, out_distance, out_normal
end

local function dispatch_mpr_mesh_primitive<T, U>(
	cframe_a: CFrame, 
	shape_a: T & types.Shape, 
	cframe_b: CFrame, 
	shape_b: U & types.Shape, 
	in_tolerance: number
): {{normal: Vector3, depth: number, point: Vector3, hull_a_id: number?, hull_b_id: number?}}
	local is_mesh_a = shape_a.type == shape_map.MESH
	local is_mesh_b = shape_b.type == shape_map.MESH
	
	local out = {}
	
	if not is_mesh_a and is_mesh_b then
		local in_b = tos(cframe_b, cframe_a)
		local hulls = (shape_b :: types.MeshShape).hulls
		for _, hull_id in (shape_b :: types.MeshShape).local_tree:query_shape(in_b, shape_a) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_b * CFrame.new(hull.offset * hull.scale)
			local hit, normal, depth, point = mpr.intersects(cframe_a, shape_a, hull_cf, hull, in_tolerance)
			if hit then
				table.insert(out, {normal = normal, depth = depth :: number, point = point :: Vector3, hull_b_id = hull_id})
			end
		end
	elseif is_mesh_a and not is_mesh_b then
		local in_a = tos(cframe_a, cframe_b)
		local hulls = (shape_a :: types.MeshShape).hulls
		for _, hull_id in (shape_a :: types.MeshShape).local_tree:query_shape(in_a, shape_b) do
			local hull = hulls[hull_id]
			local hull_cf = cframe_a * CFrame.new(hull.offset * hull.scale)
			local hit, normal, depth, point = mpr.intersects(hull_cf, hull, cframe_b, shape_b, in_tolerance)
			if hit then
				table.insert(out, {normal = -normal, depth = depth :: number, point = point :: Vector3, hull_a_id = hull_id})
			end
		end
	end
	
	return out
end

local function dispatch_mpr_mesh_mesh<T, U>(cframe_a: CFrame, 
	shape_a: T & types.Shape, 
	cframe_b: CFrame, 
	shape_b: U & types.Shape, 
	in_tolerance: number
): {{normal: Vector3, depth: number, point: Vector3, hull_a_id: number?, hull_b_id: number?}}
	local out = {}
	
	local hulls_a = (shape_a :: types.MeshShape).hulls
	local hulls_b = (shape_b :: types.MeshShape).hulls
	local local_tree_b = (shape_b :: types.MeshShape).local_tree
	for hull_a_id, hull_a in hulls_a do
		local hull_a_cf = cframe_a * CFrame.new(hull_a.offset * hull_a.scale)
		local in_b = tos(cframe_b, hull_a_cf)
		for _, hull_b_id in local_tree_b:query_shape(in_b, hull_a) do
			local hull_b = hulls_b[hull_b_id]
			local hull_b_cf = cframe_b * CFrame.new(hull_b.offset * hull_b.scale)
			local hit, normal, depth, point = mpr.intersects(hull_a_cf, hull_a, hull_b_cf, hull_b, in_tolerance)
			if hit then
				table.insert(out, {normal = normal, depth = depth :: number, point = point :: Vector3, hull_a_id = hull_a_id, hull_b_id = hull_b_id})
			end
		end
	end
	
	return out
end

return {
	dispatch_gjk_intersects = dispatch_gjk_intersects,
	dispatch_gjk_raycast = dispatch_gjk_raycast,
	dispatch_gjk_shapecast_simple = dispatch_gjk_shapecast_simple,
	dispatch_gjk_shapecast = dispatch_gjk_shapecast,
	dispatch_mpr_mesh_primitive = dispatch_mpr_mesh_primitive,
	dispatch_mpr_mesh_mesh = dispatch_mpr_mesh_mesh
}