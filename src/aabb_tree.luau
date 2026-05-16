--!native
--!strict
--!optimize 2

local types = require("./types")
local constants = require("./constants")
local shape_map = require("./shape_map")

type Node = {
	aabb_min: vector,
	aabb_max: vector,
	parent: number,
	child1: number,
	child2: number,
	height: number,
	id: number,
	cf: CFrame,
	shape: types.Shape
}

type DynamicTree = {
	padding: vector,
	root: number,
	nodes: {Node},
	free_list: number,
	leaf_map: {number},
	insert: (dyn_tree: DynamicTree, id: number, cf: CFrame, shape: types.Shape) -> (),
	remove: (dyn_tree: DynamicTree, id: number) -> (),
	move: (dyn_tree: DynamicTree, id: number, cf: CFrame) -> (),
	resize: (dyn_tree: DynamicTree, id: number, shape: types.Shape) -> (),
	clear: (dyn_tree: DynamicTree) -> (),
	query_aabb: (dyn_tree: DynamicTree, min: Vector3, max: Vector3) -> {number},
	query_ray: (dyn_tree: DynamicTree, ray_origin: Vector3, ray_direction: Vector3) -> {number},
    query_shape: (dyn_tree: DynamicTree, cframe: CFrame, shape: types.Shape) -> {number},
    query_shapecast: (dyn_tree: DynamicTree, shape: types.Shape, origin: CFrame, direction: Vector3) -> {number}
}

type Config = {
	aabb_padding: number
}

local HUGE = constants.HUGE
local NULL = 0

local query_traversal_stack = table.create(128) :: {number}

local function aabb_union(a_min: vector, a_max: vector, b_min: vector, b_max: vector): (vector, vector)
	return vector.min(a_min, b_min), vector.max(a_max, b_max)
end

local function aabb_sah(a_min: vector, a_max: vector): number
	local d = a_max - a_min
	return 2 * (d.x*d.y + d.y*d.z + d.z*d.x)
end

local function union_sah(a_min: vector, a_max: vector, b_min: vector, b_max: vector): number
	local d = vector.max(a_max, b_max) - vector.min(a_min, b_min)
	return 2 * (d.x*d.y + d.y*d.z + d.z*d.x)
end

local function aabb_contains(a_min: vector, a_max: vector, b_min: vector, b_max: vector): boolean
	return a_min.x <= b_min.x and a_max.x >= b_max.x
		and a_min.y <= b_min.y and a_max.y >= b_max.y
		and a_min.z <= b_min.z and a_max.z >= b_max.z
end

local function aabb_overlap(a_min: vector, a_max: vector, b_min: vector, b_max: vector): boolean
	return a_min.x <= b_max.x and a_max.x >= b_min.x
		and a_min.y <= b_max.y and a_max.y >= b_min.y
		and a_min.z <= b_max.z and a_max.z >= b_min.z
end

local function ray_aabb(ray_origin: Vector3, ray_inv_dir: Vector3, min: vector, max: vector): boolean
	local t1 = (min - ray_origin :: any) * ray_inv_dir
	local t2 = (max - ray_origin :: any) * ray_inv_dir

	local min_vec = vector.min(t1, t2)
	local max_vec = vector.max(t1, t2)

	local tmin = math.max(min_vec.x, min_vec.y, min_vec.z)
	local tmax = math.min(max_vec.x, max_vec.y, max_vec.z)

	return tmax >= math.max(tmin, 0) and tmin <= 1
end

local function shape_aabb(cf: CFrame, shape): (vector, vector)
	if shape.type == shape_map.BOX then
		local half_extents = (shape :: types.BoxShape).half_extents
		local center = cf.Position
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector

		local e = vector.abs(right :: any) * half_extents.X +
			vector.abs(up :: any) * half_extents.Y +
			vector.abs(look :: any) * half_extents.Z

		return center - e :: any, center + e :: any
	elseif shape.type == shape_map.SPHERE then
		local radius = (shape :: types.SphereShape).radius
		local center = cf.Position

		local e = vector.one * radius

		return center - e :: any, center + e :: any
	elseif shape.type == shape_map.CAPSULE then
		local radius = (shape :: types.CapsuleShape).radius
		local half_height = (shape :: types.CapsuleShape).half_height
		local center = cf.Position

		local e = vector.abs(cf.RightVector :: any) * half_height + vector.one * radius

		return center - e :: any, center + e :: any
	elseif shape.type == shape_map.CYLINDER then
		local radius = (shape :: types.CylinderShape).radius
		local half_height = (shape :: types.CylinderShape).half_height
		local center = cf.Position

		local axis = vector.abs(cf.RightVector :: any)
		local rx, ry, rz = axis.x, axis.y, axis.z

		local e = vector.create(
			half_height * rx + radius * (1 - rx * rx)^.5,
			half_height * ry + radius * (1 - ry * ry)^.5,
			half_height * rz + radius * (1 - rz * rz)^.5
		)

		return center - e :: any, center + e :: any
	elseif shape.type == shape_map.WEDGE then
		local half_extents = (shape :: types.WedgeShape).half_extents

		local origin = cf.Position
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector

		local a = half_extents.X * vector.abs(right :: any)

		local p = half_extents.Z * look
		local q = half_extents.Y * up

		local d = vector.abs(p - q :: any)
		local n = -(p + q)

		return origin - a :: any + vector.min(-d, n :: any) :: any, origin + a :: any + vector.max(d, n :: any) :: any
	elseif shape.type == shape_map.CORNER_WEDGE then
		local half_extents = (shape :: types.CornerWedgeShape).half_extents

		local origin = cf.Position
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector

		local sr = half_extents.X * right
		local su = half_extents.Y * up
		local sl = half_extents.Z * look

		local v1 = sr + sl - su
		local v2 = sr - sl - su
		local v3 = sr + sl + su
		local v4 = -sr - sl - su
		local v5 = -sr + sl - su

		local minv = vector.min(v1 :: any, v2 :: any, v3 :: any, v4 :: any, v5 :: any)
		local maxv = vector.max(v1 :: any, v2 :: any, v3 :: any, v4 :: any, v5 :: any)

		return origin + minv :: any, origin + maxv :: any
	elseif shape.type == shape_map.MESH then
		local half_extents = (shape :: types.MeshShape).part.Size / 2
		local center = cf.Position
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector

		local e = vector.abs(right :: any) * half_extents.X +
			vector.abs(up :: any) * half_extents.Y +
			vector.abs(look :: any) * half_extents.Z

		local extent = vector.create(e.x, e.y, e.z)
		return center - extent :: any, center + extent :: any
	else
		error("unsupported shape")
	end
end

local function alloc(dyn_tree: DynamicTree): number
	local index

	if dyn_tree.free_list ~= NULL then
		index = dyn_tree.free_list
		local node = dyn_tree.nodes[index]
		dyn_tree.free_list = node.parent

		node.parent = NULL
		node.child1 = NULL
		node.child2 = NULL
		--rest of the (re)info will be set following the alloc call
	else
		index = #dyn_tree.nodes + 1
		dyn_tree.nodes[index] = {
			parent = NULL,
			child1 = NULL,
			child2 = NULL,
			height = -1
		} :: any
	end

	return index
end

local function free(dyn_tree: DynamicTree, index: number)
	local node = dyn_tree.nodes[index]
	node.height = -1
	node.parent = dyn_tree.free_list
	dyn_tree.free_list = index
end

local function find_best_sibling(dyn_tree: DynamicTree, min: vector, max: vector): number
	local nodes = dyn_tree.nodes

	local centerD = (min + max) / 2
	local areaD = aabb_sah(min, max)

	local root_index = dyn_tree.root
	local root = nodes[root_index]

	local area_base = aabb_sah(root.aabb_min, root.aabb_max)

	local direct_cost = union_sah(root.aabb_min, root.aabb_max, min, max)
	local inherited_cost = 0

	local best_sibling = root_index
	local best_cost = direct_cost

	local index = root_index
	while nodes[index].height > 0 do
		local child1_index = nodes[index].child1
		local child2_index = nodes[index].child2

		local cost = direct_cost + inherited_cost

		if cost < best_cost then
			best_sibling = index
			best_cost = cost
		end

		inherited_cost += direct_cost - area_base

		local leaf1 = nodes[child1_index].height == 0
		local leaf2 = nodes[child2_index].height == 0

		local lower_cost1 = HUGE
		local child1 = nodes[child1_index]
		local direct_cost1 = union_sah(child1.aabb_min, child1.aabb_max, min, max)
		local area1 = 0
		if leaf1 then
			local cost1 = direct_cost1 + inherited_cost
			if cost < best_cost then
				best_sibling = child1_index
				best_cost = cost1
			end
		else
			area1 = aabb_sah(child1.aabb_min, child1.aabb_max)
			lower_cost1 = inherited_cost + direct_cost1 + math.min(areaD - area1, 0)
		end

		local lower_cost2 = HUGE
		local child2 = nodes[child2_index]
		local direct_cost2 = union_sah(child2.aabb_min, child2.aabb_max, min, max)
		local area2 = 0
		if leaf2 then
			local cost2 = direct_cost2 + inherited_cost
			if cost2 < best_cost then
				best_sibling = child2_index
				best_cost = cost2
			end
		else
			area2 = aabb_sah(child2.aabb_min, child2.aabb_max)
			lower_cost2 = inherited_cost + direct_cost2 + math.min(areaD - area2, 0)
		end

		if leaf1 and leaf2 then
			break
		end

		if best_cost <= lower_cost1 and best_cost <= lower_cost2 then
			break
		end

		if lower_cost1 == lower_cost2 and leaf1 == false then
			local d1 = (child1.aabb_min + child1.aabb_max) / 2 - centerD
			local d2 = (child2.aabb_min + child2.aabb_max) / 2 - centerD
			lower_cost1 = vector.dot(d1, d1)
			lower_cost2 = vector.dot(d2, d2)
		end

		if lower_cost1 < lower_cost2 and leaf1 == false then
			index = child1_index
			area_base = area1
			direct_cost = direct_cost1
		else
			index = child2_index
			area_base = area2
			direct_cost = direct_cost2
		end
	end

	return best_sibling
end

--beautiful variable names becaue its ported directly from box2d and i dont wanna touch it anymore
local function rotate(dyn_tree: DynamicTree, iA: number)
	local nodes = dyn_tree.nodes
	local A = nodes[iA]
	if A.height < 2 then
		return
	end

	local iB = A.child1
	local iC = A.child2

	local B = nodes[iB]
	local C = nodes[iC]

	if B.height == 0 then
		local iF = C.child1
		local iG = C.child2
		local F = nodes[iF]
		local G = nodes[iG]

		local cost_base = aabb_sah(C.aabb_min, C.aabb_max)

		local aabbBG_min, aabbBG_max = aabb_union(B.aabb_min, B.aabb_max, G.aabb_min, G.aabb_max)
		local costBF = aabb_sah(aabbBG_min, aabbBG_max)

		local aabbBF_min, aabbBF_max = aabb_union(B.aabb_min, B.aabb_max, F.aabb_min, F.aabb_max)
		local costBG = aabb_sah(aabbBF_min, aabbBF_max)

		if cost_base < costBF and cost_base < costBG then
			return
		end

		if costBF < costBG then
			A.child1 = iF
			C.child1 = iB

			B.parent = iC
			F.parent = iA 

			C.aabb_min = aabbBG_min
			C.aabb_max = aabbBG_max

			C.height = 1 + math.max(B.height, G.height)
			A.height = 1 + math.max(C.height, F.height)
		else
			A.child1 = iG
			C.child2 = iB

			B.parent = iC
			G.parent = iA

			C.aabb_min = aabbBF_min
			C.aabb_max = aabbBF_max

			C.height = 1 + math.max(B.height, F.height)
			A.height = 1 + math.max(C.height, G.height)
		end
	elseif C.height == 0 then
		local iD = B.child1
		local iE = B.child2
		local D = nodes[iD]
		local E = nodes[iE]

		local cost_base = aabb_sah(B.aabb_min, B.aabb_max)

		local aabbCE_min, aabbCE_max = aabb_union(C.aabb_min, C.aabb_max, E.aabb_min, E.aabb_max)
		local costCD = aabb_sah(aabbCE_min, aabbCE_max)

		local aabbCD_min, aabbCD_max = aabb_union(C.aabb_min, C.aabb_max, D.aabb_min, D.aabb_max)
		local costCE = aabb_sah(aabbCD_min, aabbCD_max)

		if cost_base < costCD and cost_base < costCE then
			return
		end

		if costCD < costCE then
			A.child2 = iD
			B.child1 = iC

			C.parent = iB
			D.parent = iA

			B.aabb_min = aabbCE_min
			B.aabb_max = aabbCE_max

			B.height = 1 + math.max(C.height, E.height)
			A.height = 1 + math.max(B.height, D.height)
		else
			A.child2 = iE
			B.child2 = iC

			C.parent = iB
			E.parent = iA

			B.aabb_min = aabbCD_min
			B.aabb_max = aabbCD_max

			B.height = 1 + math.max(C.height, D.height)
			A.height = 1 + math.max(B.height, E.height)
		end
	else
		local iD = B.child1
		local iE = B.child2
		local iF = C.child1
		local iG = C.child2

		local D = nodes[iD]
		local E = nodes[iE]
		local F = nodes[iF]
		local G = nodes[iG]

		local areaB = aabb_sah(B.aabb_min, B.aabb_max)
		local areaC = aabb_sah(C.aabb_min, C.aabb_max)
		local cost_base = areaB + areaC
		local best_rotation = nil
		local best_cost = cost_base

		local aabbBG_min, aabbBG_max = aabb_union(B.aabb_min, B.aabb_max, G.aabb_min, G.aabb_max)
		local costBF = areaB + aabb_sah(aabbBG_min, aabbBG_max)
		if costBF < best_cost then
			best_rotation = 1
			best_cost = costBF
		end

		local aabbBF_min, aabbBF_max = aabb_union(B.aabb_min, B.aabb_max, F.aabb_min, F.aabb_max)
		local costBG = areaB + aabb_sah(aabbBF_min, aabbBF_max)
		if costBG < best_cost then
			best_rotation = 2
			best_cost = costBG
		end

		local aabbCE_min, aabbCE_max = aabb_union(C.aabb_min, C.aabb_max, E.aabb_min, E.aabb_max)
		local costCD = areaC + aabb_sah(aabbCE_min, aabbCE_max)
		if costCD < best_cost then
			best_rotation = 3
			best_cost = costCD
		end

		local aabbCD_min, aabbCD_max = aabb_union(C.aabb_min, C.aabb_max, D.aabb_min, D.aabb_max)
		local costCE = areaC + aabb_sah(aabbCD_min, aabbCD_max)
		if costCE < best_cost then
			best_rotation = 4
			--best_cost = costCD -> not necessary to update as we dont use it below
		end

		if best_rotation == 1 then
			A.child1 = iF
			C.child1 = iB

			B.parent = iC
			F.parent = iA

			C.aabb_min = aabbBG_min
			C.aabb_max = aabbBG_max

			C.height = 1 + math.max(B.height, G.height)
			A.height = 1 + math.max(C.height, F.height)
		elseif best_rotation == 2 then
			A.child1 = iG
			C.child2 = iB

			B.parent = iC
			G.parent = iA

			C.aabb_min = aabbBF_min
			C.aabb_max = aabbBF_max

			C.height = 1 + math.max(B.height, F.height)
			A.height = 1 + math.max(C.height, G.height)
		elseif best_rotation == 3 then
			A.child2 = iD
			B.child1 = iC

			C.parent = iB
			D.parent = iA

			B.aabb_min = aabbCE_min
			B.aabb_max = aabbCE_max

			B.height = 1 + math.max(C.height, E.height)
			A.height = 1 + math.max(B.height, D.height)
		elseif best_rotation == 4 then
			A.child2 = iE
			B.child2 = iC

			C.parent = iB
			E.parent = iA

			B.aabb_min = aabbCD_min
			B.aabb_max = aabbCD_max

			B.height = 1 + math.max(C.height, D.height)
			A.height = 1 + math.max(B.height, E.height)
		end
	end
end

local function refit(dyn_tree: DynamicTree, index: number, should_rotate: boolean)
	local nodes = dyn_tree.nodes

	while index ~= NULL do
		local node = nodes[index]
		local child1 = nodes[node.child1]
		local child2 = nodes[node.child2]

		node.aabb_min, node.aabb_max = aabb_union(child1.aabb_min, child1.aabb_max, child2.aabb_min, child2.aabb_max)

		if should_rotate then
			rotate(dyn_tree, index)
		end

		index = node.parent
	end
end

local function insert_leaf(dyn_tree: DynamicTree, leaf: number)
	local nodes = dyn_tree.nodes
	if dyn_tree.root == NULL then
		dyn_tree.root = leaf
		nodes[leaf].parent = NULL
		return
	end

	local new_leaf = nodes[leaf]

	local sibling_index = find_best_sibling(dyn_tree, new_leaf.aabb_min, new_leaf.aabb_max)
	local sibling = nodes[sibling_index]

	local old_parent = sibling.parent
	local new_parent_index = alloc(dyn_tree)

	local new_parent = nodes[new_parent_index]
	new_parent.parent = old_parent
	new_parent.child1 = sibling_index
	new_parent.child2 = leaf
	new_parent.aabb_min, new_parent.aabb_max = aabb_union(sibling.aabb_min, sibling.aabb_max, new_leaf.aabb_min, new_leaf.aabb_max)
	new_parent.height = sibling.height + 1

	if old_parent == NULL then
		dyn_tree.root = new_parent_index
	else
		local grand_parent = nodes[old_parent]
		if grand_parent.child1 == sibling_index then
			grand_parent.child1 = new_parent_index
		else 
			grand_parent.child2 = new_parent_index
		end
	end

	nodes[sibling_index].parent = new_parent_index
	nodes[leaf].parent = new_parent_index

	refit(dyn_tree, new_parent_index, true)
end

local function remove_leaf(dyn_tree: DynamicTree, leaf: number)
	local nodes = dyn_tree.nodes
	if leaf == dyn_tree.root then
		dyn_tree.root = NULL
		return
	end

	local parent_index = nodes[leaf].parent
	local grand_parent_index = nodes[parent_index].parent
	local sibling = nodes[parent_index].child1 == leaf
		and nodes[parent_index].child2
		or nodes[parent_index].child1

	if grand_parent_index == NULL then
		dyn_tree.root = sibling
		nodes[sibling].parent = NULL
		free(dyn_tree, parent_index)
	else
		local grand_parent = nodes[grand_parent_index]
		if grand_parent.child1 == parent_index then
			grand_parent.child1 = sibling
		else
			grand_parent.child2 = sibling
		end

		nodes[sibling].parent = grand_parent_index

		free(dyn_tree, parent_index)
		refit(dyn_tree, grand_parent_index, false)
	end
end

local function public_insert(dyn_tree: DynamicTree, id: number, cf: CFrame, shape: types.Shape)
	local min, max = shape_aabb(cf, shape)

	local index = alloc(dyn_tree)
	local node = dyn_tree.nodes[index]
	local padding = dyn_tree.padding

	node.aabb_min = min - padding
	node.aabb_max = max + padding
	node.height = 0
	node.id = id
	node.cf = cf
	node.shape = shape

	dyn_tree.leaf_map[id] = index
	insert_leaf(dyn_tree, index)
end

local function public_remove(dyn_tree: DynamicTree, id: number)
	local index = dyn_tree.leaf_map[id]
	if not index then
		return
	end

	dyn_tree.leaf_map[id] = nil
	remove_leaf(dyn_tree, index)
	free(dyn_tree, index)
end

local function public_move(dyn_tree: DynamicTree, id: number, cf: CFrame)
	local index = dyn_tree.leaf_map[id]
	local node = dyn_tree.nodes[index]
	local min, max = shape_aabb(cf, node.shape)

	if aabb_contains(node.aabb_min, node.aabb_max, min, max) then
		node.cf = cf
		return
	end

	local padding = dyn_tree.padding

	remove_leaf(dyn_tree, index)

	node.aabb_min = min - padding
	node.aabb_max = max + padding
	node.cf = cf

	insert_leaf(dyn_tree, index)
end

local function public_resize(dyn_tree: DynamicTree, id: number, shape: types.Shape)
	local index = dyn_tree.leaf_map[id]
	local node = dyn_tree.nodes[index]
	local min, max = shape_aabb(node.cf, shape)

	remove_leaf(dyn_tree, index)

	node.aabb_min = min
	node.aabb_max = max
	node.shape = shape

	insert_leaf(dyn_tree, index)
end

local function public_clear(dyn_tree: DynamicTree)
	dyn_tree.root = NULL
	dyn_tree.nodes = {}
	dyn_tree.free_list = NULL
	dyn_tree.leaf_map = {}
end

local function public_query_aabb(dyn_tree: DynamicTree, min: Vector3, max: Vector3): {number}
	local nodes = dyn_tree.nodes
	local root = dyn_tree.root

	if root == NULL then
		return {}
	end

	table.clear(query_traversal_stack)
	table.insert(query_traversal_stack, root)

	local out = {}
	local top = 1

	while top > 0 do
		local index = query_traversal_stack[top]
		top -= 1

		local node = nodes[index]
		if aabb_overlap(node.aabb_min, node.aabb_max, min :: any, max :: any) then
			if node.child1 == NULL then
				table.insert(out, node.id)
			else
				top += 1
				query_traversal_stack[top] = node.child1
				top += 1
				query_traversal_stack[top] = node.child2
			end
		end
	end

	return out :: {number}
end

local function public_query_shape(dyn_tree: DynamicTree, cframe: CFrame, shape: types.Shape): {number}
	local min, max = shape_aabb(cframe, shape)
	return public_query_aabb(dyn_tree, min :: any, max :: any)
end

local function public_query_ray(dyn_tree: DynamicTree, ray_origin: Vector3, ray_direction: Vector3): {number}
	local nodes = dyn_tree.nodes
	local root = dyn_tree.root

	if root == NULL then
		return {}
	end

	table.clear(query_traversal_stack)
	table.insert(query_traversal_stack, root)

	local out = {}
	local top = 1

	local inv_ray_dir = 1 / ray_direction

	while top > 0 do
		local index = query_traversal_stack[top]
		top -= 1

		local node = nodes[index]
		if ray_aabb(ray_origin, inv_ray_dir, node.aabb_min, node.aabb_max) then
			if node.child1 == NULL then
				table.insert(out, node.id)
			else
				top += 1
				query_traversal_stack[top] = node.child1
				top += 1
				query_traversal_stack[top] = node.child2
			end
		end
	end

	return out :: {number}
end

local function public_query_shapecast(dyn_tree: DynamicTree, shape: types.Shape, origin: CFrame, direction: Vector3): {number}
	local nodes = dyn_tree.nodes
	local root = dyn_tree.root

	if root == NULL then
		return {}
	end

	table.clear(query_traversal_stack)
	table.insert(query_traversal_stack, root)

	local out = {}
	local top = 1

	local inv_ray_dir = 1 / direction

	local min, max = shape_aabb(origin, shape)
	local half_extents = (max - min) / 2
	local ray_origin = origin.Position

	while top > 0 do
		local index = query_traversal_stack[top]
		top -= 1

		local node = nodes[index]
		if ray_aabb(ray_origin, inv_ray_dir, node.aabb_min - half_extents, node.aabb_max + half_extents) then
			if node.child1 == NULL then
				table.insert(out, node.id)
			else
				top += 1
				query_traversal_stack[top] = node.child1
				top += 1
				query_traversal_stack[top] = node.child2
			end
		end
	end

	return out :: {number}
end

local function new_dynamic_tree(config: Config): DynamicTree
	return {
		padding = vector.one * config.aabb_padding,
		root = NULL,
		nodes = {},
		free_list = NULL,
		leaf_map = {},
		insert = public_insert,
		remove = public_remove,
		move = public_move,
		resize = public_resize,
		clear = public_clear,
		query_aabb = public_query_aabb,
        query_shape = public_query_shape,
		query_ray = public_query_ray,
		query_shapecast = public_query_shapecast
	}
end

return {
	new_dynamic = new_dynamic_tree
}