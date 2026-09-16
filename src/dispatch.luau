--!strict
--!native
--!optimize 2

local types = require("./types")
local shape_map = require("./shape_map")
local gjk = require("./gjk")
local mpr = require("./mpr")
local aabb_tree = require("./aabb_tree")
local constants = require("./constants")

local HUGE = constants.HUGE
local CF_IDENT = CFrame.identity

local tos = CF_IDENT.ToObjectSpace
local vtos = CF_IDENT.VectorToObjectSpace
local ptos = CF_IDENT.PointToObjectSpace

--the closest hit queries report positions along the sweep as a fraction of the direction, while
--gjk reports them as distances

--converting needs the direction's length, and a zero length sweep
--collapses every hit onto fraction 0, which is where a stationary cast happens
local function fraction_scale(direction: Vector3): number
	local length = vector.magnitude(direction :: any)
	return if length > 0 then 1 / length else 0
end

--a composite is never handed to gjk or mpr directly, its children are, so a margin written on the
--composite has to reach them or it does nothing at all

--the composite's own tree has to follow as well, since bounds built from unmargined children would
--cull children whose inflated surface the query still reaches

--comparing against the first child costs one field read on every composite query, and the work
--behind it only happens when the margin actually changed, which for most shapes is once
local function composite_children(composite: types.Composite): {types.Child}
	local children = composite.children
	local first = children[1]

	if first == nil or first.shape.margin == composite.margin then
		return children
	end

	local margin = composite.margin
	for _, child in children do
		child.shape.margin = margin
	end

	local target = if margin ~= nil and margin > 0 then margin else 0
	local applied = composite.tree_margin
	local local_tree = composite.local_tree

	if (local_tree :: any).resize ~= nil then
		--a dynamic composite can rebuild a leaf from its child, so its bounds land on the margin
		--exactly rather than only ever growing toward it
		if target ~= applied then
			for i, child in children do
				(local_tree :: types.DynamicTree):resize(i, child.shape)
			end
			composite.tree_margin = target
		end
	elseif target > applied then
		--a static tree has no way to rebuild a leaf, but every child grew by the same distance, so
		--the bounds can be widened in place instead

		--only growth is applied, bounds left wide after a margin shrinks cost a rejected candidate
		--and nothing else, while contracting them would land a little short of where they started
		--every time the margin moved, and bounds even slightly too tight cull real contacts
		aabb_tree.expand_bounds(local_tree, target - applied)
		composite.tree_margin = target
	end

	return children
end

local function dispatch_gjk_intersects<T, U>(
	cframe_a: CFrame, 
	shape_a: T & types.Shape, 
	cframe_b: CFrame, 
	shape_b: U & types.Shape, 
	in_tolerance: number
): boolean
	local is_composite_a = shape_a.type == shape_map.COMPOSITE
	local is_composite_b = shape_b.type == shape_map.COMPOSITE

	if not is_composite_a and not is_composite_b then
		local hit = gjk.intersects(cframe_a, shape_a, cframe_b, shape_b, in_tolerance)
		if hit then
			return true
		end
	elseif not is_composite_a and is_composite_b then
		local in_b = tos(cframe_b, cframe_a)
		local children = composite_children(shape_b :: types.Composite)
		local local_tree = (shape_b :: types.Composite).local_tree

		return local_tree:query_shape_any(in_b, shape_a, function(child_id: number): boolean
			local child = children[child_id]
			local child_cf = cframe_b * child.cf
			local hit = gjk.intersects(cframe_a, shape_a, child_cf, child.shape, in_tolerance)
			return hit
		end)
	elseif is_composite_a and not is_composite_b then
		local in_a = tos(cframe_a, cframe_b)
		local children = composite_children(shape_a :: types.Composite)
		local local_tree = (shape_a :: types.Composite).local_tree

		return local_tree:query_shape_any(in_a, shape_b, function(child_id: number): boolean
			local child = children[child_id]
			local child_cf = cframe_a * child.cf
			local hit = gjk.intersects(child_cf, child.shape, cframe_b, shape_b, in_tolerance)
			return hit
		end)
	else
		local children_a = composite_children(shape_a :: types.Composite)
		local children_b = composite_children(shape_b :: types.Composite)
		local local_tree_b = (shape_b :: types.Composite).local_tree

		for _, child_a in children_a do
			local child_a_cf = cframe_a * child_a.cf
			local in_b = tos(cframe_b, child_a_cf)

			local hit = local_tree_b:query_shape_any(in_b, child_a.shape, function(child_b_id: number): boolean
				local child_b = children_b[child_b_id]
				local child_b_cf = cframe_b * child_b.cf
				local hit = gjk.intersects(child_a_cf, child_a.shape, child_b_cf, child_b.shape, in_tolerance)
				return hit
			end)

			if hit then
				return true
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
	local is_composite = shape.type == shape_map.COMPOSITE

	local best_distance = HUGE
	local out_point : Vector3?, out_distance: number?, out_normal: Vector3? = nil, nil, nil

	if not is_composite then
		return gjk.raycast(ray_origin, ray_direction, cframe, shape, in_tolerance)
	else
		local children = composite_children(shape :: types.Composite)
		local local_tree = (shape :: types.Composite).local_tree
		local local_origin = ptos(cframe, ray_origin)
		local local_direction = vtos(cframe, ray_direction)
		local inv_length = fraction_scale(ray_direction)

		local_tree:query_ray_closest(local_origin, local_direction, function(child_id: number): number?
			local child = children[child_id]
			local child_cf = cframe * child.cf
			local point, distance, normal = gjk.raycast(ray_origin, ray_direction, child_cf, child.shape, in_tolerance)
			if distance == nil then
				return nil
			end

			if distance < best_distance then
				best_distance = distance
				out_point = point
				out_distance = distance
				out_normal = normal
			end

			return distance * inv_length
		end)
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
	local is_composite_a = shape_a.type == shape_map.COMPOSITE
	local is_composite_b = shape_b.type == shape_map.COMPOSITE

	local best_distance = HUGE
	local out_distance: number? = nil

	if not is_composite_a and not is_composite_b then
		return gjk.shapecast_simple(cframe_a, direction, shape_a, cframe_b, shape_b, in_tolerance)
	elseif not is_composite_a and is_composite_b then
		local children = composite_children(shape_b :: types.Composite)
		local local_tree = (shape_b :: types.Composite).local_tree
		local local_origin = tos(cframe_b, cframe_a)
		local local_direction = vtos(cframe_b, direction)
		local inv_length = fraction_scale(direction)

		local_tree:query_shapecast_closest(shape_a, local_origin, local_direction, function(child_id: number): number?
			local child = children[child_id]
			local child_cf = cframe_b * child.cf
			local _, distance = gjk.shapecast_simple(cframe_a, direction, shape_a, child_cf, child.shape, in_tolerance)
			if distance == nil then
				return nil
			end

			if distance < best_distance then
				best_distance = distance
				out_distance = distance
			end

			return distance * inv_length
		end)
	elseif is_composite_a and not is_composite_b then
		local children = composite_children(shape_a :: types.Composite)
		local local_tree = (shape_a :: types.Composite).local_tree
		local local_origin = tos(cframe_a, cframe_b)
		local local_direction = vtos(cframe_a, direction)
		local inv_length = fraction_scale(direction)

		local_tree:query_shapecast_closest(shape_b, local_origin, -local_direction, function(child_id: number): number?
			local child = children[child_id]
			local child_cf = cframe_a * child.cf
			local _, distance = gjk.shapecast_simple(child_cf, direction, child.shape, cframe_b, shape_b, in_tolerance)
			if distance == nil then
				return nil
			end

			if distance < best_distance then
				best_distance = distance
				out_distance = distance
			end

			return distance * inv_length
		end)
	else
		local children_a = composite_children(shape_a :: types.Composite)
		local children_b = composite_children(shape_b :: types.Composite)
		local local_tree_b = (shape_b :: types.Composite).local_tree
		local inv_length = fraction_scale(direction)

		for child_a_id, child_a in children_a do
			local child_a_cf = cframe_a * child_a.cf
			local local_origin = tos(cframe_b, child_a_cf)
			local local_direction = vtos(cframe_b, direction)

			--each child of a runs its own query, so feed the best hit found so far back in as a cap
			--and later children prune against it instead of restarting from the full sweep
			local seed = if best_distance < HUGE then best_distance * inv_length else 1

			local_tree_b:query_shapecast_closest(child_a.shape, local_origin, local_direction, function(child_b_id: number): number?
				local child_b = children_b[child_b_id]
				local child_b_cf = cframe_b * child_b.cf
				local _, distance = gjk.shapecast_simple(child_a_cf, direction, child_a.shape, child_b_cf, child_b.shape, in_tolerance)
				if distance == nil then
					return nil
				end

				if distance < best_distance then
					best_distance = distance
					out_distance = distance
				end

				return distance * inv_length
			end, seed)
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
	local is_composite_a = shape_a.type == shape_map.COMPOSITE
	local is_composite_b = shape_b.type == shape_map.COMPOSITE

	local best_distance = HUGE
	local out_point : Vector3?, out_distance: number?, out_normal: Vector3? = nil, nil, nil

	if not is_composite_a and not is_composite_b then
		return gjk.shapecast(cframe_a, direction, shape_a, cframe_b, shape_b, in_tolerance)
	elseif not is_composite_a and is_composite_b then
		local children = composite_children(shape_b :: types.Composite)
		local local_tree = (shape_b :: types.Composite).local_tree
		local local_origin = tos(cframe_b, cframe_a)
		local local_direction = vtos(cframe_b, direction)
		local inv_length = fraction_scale(direction)

		local_tree:query_shapecast_closest(shape_a, local_origin, local_direction, function(child_id: number): number?
			local child = children[child_id]
			local child_cf = cframe_b * child.cf
			local point, distance, normal = gjk.shapecast(cframe_a, direction, shape_a, child_cf, child.shape, in_tolerance)
			if distance == nil then
				return nil
			end

			if distance < best_distance then
				best_distance = distance
				out_distance = distance
				out_point = point
				out_normal = normal
			end

			return distance * inv_length
		end)
	elseif is_composite_a and not is_composite_b then
		local children = composite_children(shape_a :: types.Composite)
		local local_tree = (shape_a :: types.Composite).local_tree
		local local_origin = tos(cframe_a, cframe_b)
		local local_direction = vtos(cframe_a, direction)
		local inv_length = fraction_scale(direction)

		local_tree:query_shapecast_closest(shape_b, local_origin, -local_direction, function(child_id: number): number?
			local child = children[child_id]
			local child_cf = cframe_a * child.cf
			local point, distance, normal = gjk.shapecast(child_cf, direction, child.shape, cframe_b, shape_b, in_tolerance)
			if distance == nil then
				return nil
			end

			if distance < best_distance then
				best_distance = distance
				out_distance = distance
				out_point = point
				out_normal = normal
			end

			return distance * inv_length
		end)
	else
		local children_a = composite_children(shape_a :: types.Composite)
		local children_b = composite_children(shape_b :: types.Composite)
		local local_tree_b = (shape_b :: types.Composite).local_tree
		local inv_length = fraction_scale(direction)

		for child_a_id, child_a in children_a do
			local child_a_cf = cframe_a * child_a.cf
			local local_origin = tos(cframe_b, child_a_cf)
			local local_direction = vtos(cframe_b, direction)

			--each child of a runs its own query, so feed the best hit found so far back in as a cap
			--and later children prune against it instead of restarting from the full sweep
			local seed = if best_distance < HUGE then best_distance * inv_length else 1

			local_tree_b:query_shapecast_closest(child_a.shape, local_origin, local_direction, function(child_b_id: number): number?
				local child_b = children_b[child_b_id]
				local child_b_cf = cframe_b * child_b.cf
				local point, distance, normal = gjk.shapecast(child_a_cf, direction, child_a.shape, child_b_cf, child_b.shape, in_tolerance)
				if distance == nil then
					return nil
				end

				if distance < best_distance then
					best_distance = distance
					out_distance = distance
					out_point = point
					out_normal = normal
				end

				return distance * inv_length
			end, seed)
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
): {{normal: Vector3, depth: number, point_a: Vector3, point_b: Vector3, child_a_id: number?, child_b_id: number?}}
	local is_composite_a = shape_a.type == shape_map.COMPOSITE
	local is_composite_b = shape_b.type == shape_map.COMPOSITE

	local out = {}

	if not is_composite_a and is_composite_b then
		local in_b = tos(cframe_b, cframe_a)
		local children = composite_children(shape_b :: types.Composite)
		for _, child_id in (shape_b :: types.Composite).local_tree:query_shape(in_b, shape_a) do
			local child = children[child_id]
			local child_cf = cframe_b * child.cf
			local hit, normal, depth, point_a, point_b = mpr.intersects(cframe_a, shape_a, child_cf, child.shape, in_tolerance)
			if hit then
				table.insert(out, {normal = normal, depth = depth :: number, point_a = point_a :: Vector3, point_b = point_b :: Vector3, child_b_id = child_id})
			end
		end
	elseif is_composite_a and not is_composite_b then
		local in_a = tos(cframe_a, cframe_b)
		local children = composite_children(shape_a :: types.Composite)
		for _, child_id in (shape_a :: types.Composite).local_tree:query_shape(in_a, shape_b) do
			local child = children[child_id]
			local child_cf = cframe_a * child.cf
			local hit, normal, depth, point_a, point_b = mpr.intersects(child_cf, child.shape, cframe_b, shape_b, in_tolerance)
			if hit then
				table.insert(out, {normal = normal, depth = depth :: number, point_a = point_a :: Vector3, point_b = point_b :: Vector3, child_a_id = child_id})
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
): {{normal: Vector3, depth: number, point_a: Vector3, point_b: Vector3, child_a_id: number, child_b_id: number}}
	local out = {}

	local children_a = composite_children(shape_a :: types.Composite)
	local children_b = composite_children(shape_b :: types.Composite)
	local local_tree_b = (shape_b :: types.Composite).local_tree
	for child_a_id, child_a in children_a do
		local child_a_cf = cframe_a * child_a.cf
		local in_b = tos(cframe_b, child_a_cf)
		for _, child_b_id in local_tree_b:query_shape(in_b, child_a.shape) do
			local child_b = children_b[child_b_id]
			local child_b_cf = cframe_b * child_b.cf
			local hit, normal, depth, point_a, point_b = mpr.intersects(child_a_cf, child_a.shape, child_b_cf, child_b.shape, in_tolerance)
			if hit then
				table.insert(out, {normal = normal, depth = depth :: number, point_a = point_a :: Vector3, point_b = point_b :: Vector3, child_a_id = child_a_id, child_b_id = child_b_id})
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