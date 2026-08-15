--!native
--!strict
--!optimize 2

local types = require("./types")
local shape_map = require("./shape_map")

type Tree = types.Tree
type DynamicTree = types.DynamicTree
type StaticTree = types.StaticTree
type Config = types.DynamicTreeConfig

local INITIAL_REBUILD_THRESHOLD = 128
local REBUILD_RATIO_THRESHOLD = 1.5

local BIN_COUNT = 16
local PLANE_COUNT = BIN_COUNT - 1

local NULL = 0

local TRUE_HUGE = math.huge
local HUGE_VECTOR = vector.one * 2^32
local NEG_INF_VEC = -vector.one * math.huge
local POS_INF_VEC = vector.one * math.huge

--a closest hit query whose narrow phase resolves a mesh candidate sends dispatch into that mesh's local tree while the outer
--traversal is still happening, a nested traversal must not walk over the stack of the one that called it, so these are pooled
local stack_pool = {} :: {{number}}
local pooled_count = 0

local function acquire_stack(): {number}
	if pooled_count > 0 then
		local stack = stack_pool[pooled_count]
		pooled_count -= 1
		return stack
	end

	return table.create(64) :: {number}
end

local function release_stack(stack: {number})
	pooled_count += 1
	stack_pool[pooled_count] = stack
end

local function aabb_union(a_min: vector, a_max: vector, b_min: vector, b_max: vector): (vector, vector)
	return vector.min(a_min, b_min), vector.max(a_max, b_max)
end

local function aabb_sah(a_min: vector, a_max: vector): number
	local d = a_max - a_min
	return d.x*d.y + d.y*d.z + d.z*d.x
end

local function union_sah(a_min: vector, a_max: vector, b_min: vector, b_max: vector): number
	local d = vector.max(a_max, b_max) - vector.min(a_min, b_min)
	return d.x*d.y + d.y*d.z + d.z*d.x
end

local function aabb_contains(a_min: vector, a_max: vector, b_min: vector, b_max: vector): boolean
	return a_min.x <= b_min.x and a_max.x >= b_max.x
		and a_min.y <= b_min.y and a_max.y >= b_max.y
		and a_min.z <= b_min.z and a_max.z >= b_max.z
end

--instead of a boolean it returns the distance at which the cast first touches the node (TRUE_HUGE when it never does),
--so a traversal can visit the nearer child first and discard anything starting beyond the best hit so far

--a ray is just a cast whose box has no size, so both closest hit queries share this function
local function swept_aabb_enter(cast_min: vector, cast_max: vector, ray_inv_dir: Vector3, min: vector, max: vector, max_fraction: number): number
	local t1 = vector.max(NEG_INF_VEC, (min - cast_max) * ray_inv_dir :: any)
	local t2 = vector.min(POS_INF_VEC, (max - cast_min) * ray_inv_dir :: any)

	local min_vec = vector.min(t1, t2)
	local max_vec = vector.max(t1, t2)

	--math.max and math.min start from their first argument and keep anything that compares better,
	--so a NaN produced by a 0 * inf on an axis the ray runs parallel to gets skipped
	local tmin = math.max(0, min_vec.x, min_vec.y, min_vec.z)
	local tmax = math.min(max_fraction, max_vec.x, max_vec.y, max_vec.z)

	if tmin <= tmax then
		return tmin
	end

	return TRUE_HUGE
end

local function ray_aabb(ray_origin: Vector3, ray_inv_dir: Vector3, min: vector, max: vector): boolean
	local t1 = vector.max(NEG_INF_VEC, (min - ray_origin :: any) * ray_inv_dir)
	local t2 = vector.min(POS_INF_VEC, (max - ray_origin :: any) * ray_inv_dir)

	local min_vec = vector.min(t1, t2)
	local max_vec = vector.max(t1, t2)

	--see swept_aabb_enter for why the constants are used first
	local tmin = math.max(0, min_vec.x, min_vec.y, min_vec.z)
	local tmax = math.min(1, max_vec.x, max_vec.y, max_vec.z)

	return tmin <= tmax
end

--sweeping a box along a segment and testing it against a node is the same as expanding the node
--by the box's half extents and casting a ray from the box's center through it

--expanding by the half extents and then subtracting the center is just subtracting the box's own corners
local function swept_aabb(cast_min: vector, cast_max: vector, ray_inv_dir: Vector3, min: vector, max: vector): boolean
	local t1 = vector.max(NEG_INF_VEC, (min - cast_max) * ray_inv_dir :: any)
	local t2 = vector.min(POS_INF_VEC, (max - cast_min) * ray_inv_dir :: any)

	local min_vec = vector.min(t1, t2)
	local max_vec = vector.max(t1, t2)

	local tmin = math.max(0, min_vec.x, min_vec.y, min_vec.z)
	local tmax = math.min(1, max_vec.x, max_vec.y, max_vec.z)

	return tmin <= tmax
end

local function unmargined_shape_aabb(cf: CFrame, shape: types.Shape): (vector, vector)
	if shape.type == shape_map.BOX or shape.type == shape_map.MESH then
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
	elseif shape.type == shape_map.ELLIPSOID then
		local half_extents = (shape :: types.EllipsoidShape).half_extents
		local center = cf.Position
		local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector

		local rx, ry, rz = right.X, right.Y, right.Z
		local ux, uy, uz = up.X, up.Y, up.Z
		local lx, ly, lz = look.X, look.Y, look.Z

		local hx, hy, hz = half_extents.X, half_extents.Y, half_extents.Z

		local ex = math.sqrt((hx * rx) ^ 2 + (hy * ux) ^ 2 + (hz * lx) ^ 2)
		local ey = math.sqrt((hx * ry) ^ 2 + (hy * uy) ^ 2 + (hz * ly) ^ 2)
		local ez = math.sqrt((hx * rz) ^ 2 + (hy * uz) ^ 2 + (hz * lz) ^ 2)

		local e = vector.create(ex, ey, ez)
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
		local up, look = cf.UpVector, cf.LookVector
		local ux, uy, uz = up.X, up.Y, up.Z
		local lx, ly, lz = look.X, look.Y, look.Z

		local e = vector.create(
			half_height * axis.x + radius * (ux * ux + lx * lx)^.5,
			half_height * axis.y + radius * (uy * uy + ly * ly)^.5,
			half_height * axis.z + radius * (uz * uz + lz * lz)^.5
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
		local v3 = sr - sl + su
		local v4 = -sr - sl - su
		local v5 = -sr + sl - su

		local minv = vector.min(v1 :: any, v2 :: any, v3 :: any, v4 :: any, v5 :: any)
		local maxv = vector.max(v1 :: any, v2 :: any, v3 :: any, v4 :: any, v5 :: any)

		return origin + minv :: any, origin + maxv :: any
	elseif shape.type == shape_map.HULL then
		local hull = (shape :: types.HullShape)
		local scale = hull.scale
		local vertices = hull.vertices

		local point = cf * (vertices[1] * scale)
		local min = point
		local max = point

		for i = 2, #vertices do
			point = cf * (vertices[i] * scale)
			min = vector.min(min :: any, point :: any)
			max = vector.max(max :: any, point :: any)
		end

		return min :: any, max :: any
	else
		error("unsupported shape")
	end
end

--the broad phase has to agree with the narrow phase about how big a shape is, so a margin widens
--the bounds too, without this the tree would filter out pairs that gjk and mpr would have found

--only a positive margin counts, which is the same rule gjk and mpr apply, a negative one is not supported
local function shape_aabb(cf: CFrame, shape: types.Shape): (vector, vector)
	local min, max = unmargined_shape_aabb(cf, shape)
	local margin = shape.margin

	if margin == nil or margin <= 0 then
		return min, max
	end

	local expand = vector.one * margin
	return min - expand, max + expand
end

local function alloc(tree: Tree): number
	local index

	if tree.free_list ~= NULL then
		index = tree.free_list
		tree.free_list = tree.parent[index]

		tree.parent[index] = NULL
		tree.child1[index] = NULL
		tree.child2[index] = NULL
		tree.enlarged[index] = false
	else
		index = tree.node_count + 1
		tree.node_count = index

		--every array is written on allocation so none of them ever holds a hole
		tree.aabb_min[index] = vector.zero
		tree.aabb_max[index] = vector.zero
		tree.parent[index] = NULL
		tree.child1[index] = NULL
		tree.child2[index] = NULL
		tree.height[index] = -1
		tree.enlarged[index] = false
		tree.id[index] = 0
		
		--leaf payload is written with a placeholder so these arrays stay dense too
		
		--leaves land on ~50% of indices, which is roughly where luau will write integer keys into the hash part
		tree.cf[index] = false :: any
		tree.shape[index] = false :: any
	end

	return index
end

local function free(tree: Tree, index: number)
	tree.height[index] = -1
	tree.parent[index] = tree.free_list
	tree.free_list = index
end

local function find_best_sibling(dyn_tree: DynamicTree, min: vector, max: vector): number
	local aabb_min = dyn_tree.aabb_min
	local aabb_max = dyn_tree.aabb_max
	local child1 = dyn_tree.child1
	local child2 = dyn_tree.child2
	local height = dyn_tree.height

	local centerD = (min + max) / 2
	local areaD = aabb_sah(min, max)

	local root_index = dyn_tree.root

	local area_base = aabb_sah(aabb_min[root_index], aabb_max[root_index])

	local direct_cost = union_sah(aabb_min[root_index], aabb_max[root_index], min, max)
	local inherited_cost = 0

	local best_sibling = root_index
	local best_cost = direct_cost

	local index = root_index
	while height[index] > 0 do
		local child1_index = child1[index]
		local child2_index = child2[index]

		local cost = direct_cost + inherited_cost

		if cost < best_cost then
			best_sibling = index
			best_cost = cost
		end

		inherited_cost += direct_cost - area_base

		local leaf1 = height[child1_index] == 0
		local leaf2 = height[child2_index] == 0

		local child1_min, child1_max = aabb_min[child1_index], aabb_max[child1_index]
		local lower_cost1 = TRUE_HUGE
		local direct_cost1 = union_sah(child1_min, child1_max, min, max)
		local area1 = 0
		if leaf1 then
			local cost1 = direct_cost1 + inherited_cost
			if cost1 < best_cost then
				best_sibling = child1_index
				best_cost = cost1
			end
		else
			area1 = aabb_sah(child1_min, child1_max)
			lower_cost1 = inherited_cost + direct_cost1 + math.min(areaD - area1, 0)
		end

		local child2_min, child2_max = aabb_min[child2_index], aabb_max[child2_index]
		local lower_cost2 = TRUE_HUGE
		local direct_cost2 = union_sah(child2_min, child2_max, min, max)
		local area2 = 0
		if leaf2 then
			local cost2 = direct_cost2 + inherited_cost
			if cost2 < best_cost then
				best_sibling = child2_index
				best_cost = cost2
			end
		else
			area2 = aabb_sah(child2_min, child2_max)
			lower_cost2 = inherited_cost + direct_cost2 + math.min(areaD - area2, 0)
		end

		if leaf1 and leaf2 then
			break
		end

		if best_cost <= lower_cost1 and best_cost <= lower_cost2 then
			break
		end

		if lower_cost1 == lower_cost2 and leaf1 == false then
			local d1 = (child1_min + child1_max) / 2 - centerD
			local d2 = (child2_min + child2_max) / 2 - centerD
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
	local aabb_min = dyn_tree.aabb_min
	local aabb_max = dyn_tree.aabb_max
	local parent = dyn_tree.parent
	local child1 = dyn_tree.child1
	local child2 = dyn_tree.child2
	local height = dyn_tree.height

	if height[iA] < 2 then
		return
	end

	local iB = child1[iA]
	local iC = child2[iA]

	if height[iB] == 0 then
		local iF = child1[iC]
		local iG = child2[iC]

		local cost_base = aabb_sah(aabb_min[iC], aabb_max[iC])

		local aabbBG_min, aabbBG_max = aabb_union(aabb_min[iB], aabb_max[iB], aabb_min[iG], aabb_max[iG])
		local costBF = aabb_sah(aabbBG_min, aabbBG_max)

		local aabbBF_min, aabbBF_max = aabb_union(aabb_min[iB], aabb_max[iB], aabb_min[iF], aabb_max[iF])
		local costBG = aabb_sah(aabbBF_min, aabbBF_max)

		if cost_base < costBF and cost_base < costBG then
			return
		end

		if costBF < costBG then
			child1[iA] = iF
			child1[iC] = iB

			parent[iB] = iC
			parent[iF] = iA

			aabb_min[iC] = aabbBG_min
			aabb_max[iC] = aabbBG_max

			height[iC] = 1 + math.max(height[iB], height[iG])
			height[iA] = 1 + math.max(height[iC], height[iF])
		else
			child1[iA] = iG
			child2[iC] = iB

			parent[iB] = iC
			parent[iG] = iA

			aabb_min[iC] = aabbBF_min
			aabb_max[iC] = aabbBF_max

			height[iC] = 1 + math.max(height[iB], height[iF])
			height[iA] = 1 + math.max(height[iC], height[iG])
		end
	elseif height[iC] == 0 then
		local iD = child1[iB]
		local iE = child2[iB]

		local cost_base = aabb_sah(aabb_min[iB], aabb_max[iB])

		local aabbCE_min, aabbCE_max = aabb_union(aabb_min[iC], aabb_max[iC], aabb_min[iE], aabb_max[iE])
		local costCD = aabb_sah(aabbCE_min, aabbCE_max)

		local aabbCD_min, aabbCD_max = aabb_union(aabb_min[iC], aabb_max[iC], aabb_min[iD], aabb_max[iD])
		local costCE = aabb_sah(aabbCD_min, aabbCD_max)

		if cost_base < costCD and cost_base < costCE then
			return
		end

		if costCD < costCE then
			child2[iA] = iD
			child1[iB] = iC

			parent[iC] = iB
			parent[iD] = iA

			aabb_min[iB] = aabbCE_min
			aabb_max[iB] = aabbCE_max

			height[iB] = 1 + math.max(height[iC], height[iE])
			height[iA] = 1 + math.max(height[iB], height[iD])
		else
			child2[iA] = iE
			child2[iB] = iC

			parent[iC] = iB
			parent[iE] = iA

			aabb_min[iB] = aabbCD_min
			aabb_max[iB] = aabbCD_max

			height[iB] = 1 + math.max(height[iC], height[iD])
			height[iA] = 1 + math.max(height[iB], height[iE])
		end
	else
		local iD = child1[iB]
		local iE = child2[iB]
		local iF = child1[iC]
		local iG = child2[iC]

		local areaB = aabb_sah(aabb_min[iB], aabb_max[iB])
		local areaC = aabb_sah(aabb_min[iC], aabb_max[iC])
		local cost_base = areaB + areaC
		local best_rotation = nil
		local best_cost = cost_base

		local aabbBG_min, aabbBG_max = aabb_union(aabb_min[iB], aabb_max[iB], aabb_min[iG], aabb_max[iG])
		local costBF = areaB + aabb_sah(aabbBG_min, aabbBG_max)
		if costBF < best_cost then
			best_rotation = 1
			best_cost = costBF
		end

		local aabbBF_min, aabbBF_max = aabb_union(aabb_min[iB], aabb_max[iB], aabb_min[iF], aabb_max[iF])
		local costBG = areaB + aabb_sah(aabbBF_min, aabbBF_max)
		if costBG < best_cost then
			best_rotation = 2
			best_cost = costBG
		end

		local aabbCE_min, aabbCE_max = aabb_union(aabb_min[iC], aabb_max[iC], aabb_min[iE], aabb_max[iE])
		local costCD = areaC + aabb_sah(aabbCE_min, aabbCE_max)
		if costCD < best_cost then
			best_rotation = 3
			best_cost = costCD
		end

		local aabbCD_min, aabbCD_max = aabb_union(aabb_min[iC], aabb_max[iC], aabb_min[iD], aabb_max[iD])
		local costCE = areaC + aabb_sah(aabbCD_min, aabbCD_max)
		if costCE < best_cost then
			best_rotation = 4
			--best_cost = costCD -> not necessary to update as we dont use it below
		end

		if best_rotation == 1 then
			child1[iA] = iF
			child1[iC] = iB

			parent[iB] = iC
			parent[iF] = iA

			aabb_min[iC] = aabbBG_min
			aabb_max[iC] = aabbBG_max

			height[iC] = 1 + math.max(height[iB], height[iG])
			height[iA] = 1 + math.max(height[iC], height[iF])
		elseif best_rotation == 2 then
			child1[iA] = iG
			child2[iC] = iB

			parent[iB] = iC
			parent[iG] = iA

			aabb_min[iC] = aabbBF_min
			aabb_max[iC] = aabbBF_max

			height[iC] = 1 + math.max(height[iB], height[iF])
			height[iA] = 1 + math.max(height[iC], height[iG])
		elseif best_rotation == 3 then
			child2[iA] = iD
			child1[iB] = iC

			parent[iC] = iB
			parent[iD] = iA

			aabb_min[iB] = aabbCE_min
			aabb_max[iB] = aabbCE_max

			height[iB] = 1 + math.max(height[iC], height[iE])
			height[iA] = 1 + math.max(height[iB], height[iD])
		elseif best_rotation == 4 then
			child2[iA] = iE
			child2[iB] = iC

			parent[iC] = iB
			parent[iE] = iA

			aabb_min[iB] = aabbCD_min
			aabb_max[iB] = aabbCD_max

			height[iB] = 1 + math.max(height[iC], height[iD])
			height[iA] = 1 + math.max(height[iB], height[iE])
		end
	end
end

local function refit(dyn_tree: DynamicTree, index: number, should_rotate: boolean)
	local aabb_min = dyn_tree.aabb_min
	local aabb_max = dyn_tree.aabb_max
	local parent = dyn_tree.parent
	local child1 = dyn_tree.child1
	local child2 = dyn_tree.child2
	local enlarged = dyn_tree.enlarged

	while index ~= NULL do
		local c1 = child1[index]
		local c2 = child2[index]

		local prev_size = aabb_max[index] - aabb_min[index]
		local new_min, new_max = aabb_union(aabb_min[c1], aabb_max[c1], aabb_min[c2], aabb_max[c2])
		aabb_min[index] = new_min
		aabb_max[index] = new_max

		local new_size = new_max - new_min
		if vector.dot(new_size :: vector, new_size :: vector) > vector.dot(prev_size :: vector, prev_size :: vector) then
			enlarged[index] = true
		end

		if should_rotate then
			rotate(dyn_tree, index)
		end

		index = parent[index]
	end
end

local function insert_leaf(dyn_tree: DynamicTree, leaf: number)
	local aabb_min = dyn_tree.aabb_min
	local aabb_max = dyn_tree.aabb_max
	local parent = dyn_tree.parent
	local child1 = dyn_tree.child1
	local child2 = dyn_tree.child2
	local height = dyn_tree.height

	if dyn_tree.root == NULL then
		dyn_tree.root = leaf
		parent[leaf] = NULL
		return
	end

	local leaf_min, leaf_max = aabb_min[leaf], aabb_max[leaf]

	local sibling_index = find_best_sibling(dyn_tree, leaf_min, leaf_max)

	local old_parent = parent[sibling_index]
	local new_parent_index = alloc(dyn_tree)

	parent[new_parent_index] = old_parent
	child1[new_parent_index] = sibling_index
	child2[new_parent_index] = leaf
	aabb_min[new_parent_index], aabb_max[new_parent_index] = aabb_union(aabb_min[sibling_index], aabb_max[sibling_index], leaf_min, leaf_max)
	height[new_parent_index] = height[sibling_index] + 1

	if old_parent == NULL then
		dyn_tree.root = new_parent_index
	else
		if child1[old_parent] == sibling_index then
			child1[old_parent] = new_parent_index
		else
			child2[old_parent] = new_parent_index
		end
	end

	parent[sibling_index] = new_parent_index
	parent[leaf] = new_parent_index

	refit(dyn_tree, new_parent_index, true)
end

local function remove_leaf(dyn_tree: DynamicTree, leaf: number)
	local parent = dyn_tree.parent
	local child1 = dyn_tree.child1
	local child2 = dyn_tree.child2

	if leaf == dyn_tree.root then
		dyn_tree.root = NULL
		return
	end

	local parent_index = parent[leaf]
	local grand_parent_index = parent[parent_index]
	local sibling = child1[parent_index] == leaf
		and child2[parent_index]
		or child1[parent_index]

	if grand_parent_index == NULL then
		dyn_tree.root = sibling
		parent[sibling] = NULL
		free(dyn_tree, parent_index)
	else
		if child1[grand_parent_index] == parent_index then
			child1[grand_parent_index] = sibling
		else
			child2[grand_parent_index] = sibling
		end

		parent[sibling] = grand_parent_index

		free(dyn_tree, parent_index)
		refit(dyn_tree, grand_parent_index, false)
	end
end

local function public_insert(dyn_tree: DynamicTree, id: number, cf: CFrame, shape: types.Shape)
	local leaf_map = dyn_tree.leaf_map
	if leaf_map[id] then
		error("id already registered")
	end

	local min, max = shape_aabb(cf, shape)

	local index = alloc(dyn_tree)
	local padding = dyn_tree.padding

	dyn_tree.aabb_min[index] = min - padding
	dyn_tree.aabb_max[index] = max + padding
	dyn_tree.height[index] = 0
	dyn_tree.id[index] = id
	dyn_tree.cf[index] = cf
	dyn_tree.shape[index] = shape

	dyn_tree.proxy_count += 1
	leaf_map[id] = index

	insert_leaf(dyn_tree, index)
end

local function public_remove(dyn_tree: DynamicTree, id: number)
	local index = dyn_tree.leaf_map[id]
	if not index then
		return
	end

	dyn_tree.leaf_map[id] = nil
	dyn_tree.proxy_count -= 1

	remove_leaf(dyn_tree, index)
	free(dyn_tree, index)

	if dyn_tree.proxy_count == 0 then
		dyn_tree.base_cost_ratio = nil
	end
end

local function public_move(dyn_tree: DynamicTree, id: number, cf: CFrame)
	local index = dyn_tree.leaf_map[id]
	local min, max = shape_aabb(cf, dyn_tree.shape[index])

	if aabb_contains(dyn_tree.aabb_min[index], dyn_tree.aabb_max[index], min, max) then
		dyn_tree.cf[index] = cf
		return
	end

	local padding = dyn_tree.padding

	remove_leaf(dyn_tree, index)

	dyn_tree.aabb_min[index] = min - padding
	dyn_tree.aabb_max[index] = max + padding
	dyn_tree.cf[index] = cf

	insert_leaf(dyn_tree, index)
end

local function public_resize(dyn_tree: DynamicTree, id: number, shape: types.Shape)
	local index = dyn_tree.leaf_map[id]
	local min, max = shape_aabb(dyn_tree.cf[index], shape)

	local padding = dyn_tree.padding

	remove_leaf(dyn_tree, index)

	dyn_tree.aabb_min[index] = min - padding
	dyn_tree.aabb_max[index] = max + padding
	dyn_tree.shape[index] = shape

	insert_leaf(dyn_tree, index)
end

local function public_clear(tree: Tree)
	tree.root = NULL
	tree.free_list = NULL
	tree.node_count = 0
	tree.proxy_count = 0
	tree.base_cost_ratio = nil

	tree.leaf_map = {}
	tree.aabb_min = {}
	tree.aabb_max = {}
	tree.parent = {}
	tree.child1 = {}
	tree.child2 = {}
	tree.height = {}
	tree.enlarged = {}
	tree.id = {}
	tree.cf = {}
	tree.shape = {}
end

local function public_query_aabb(tree: Tree, min: Vector3, max: Vector3): {number}
	local out = {}

	local index = tree.root
	if index == NULL then
		return out
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local child1 = tree.child1
	local child2 = tree.child2
	local ids = tree.id

	--faster to do it this way than with scalars
	local root_lo = vector.max(aabb_min[index], min :: any)
	local root_hi = vector.min(aabb_max[index], max :: any)
	if vector.min(root_lo, root_hi) ~= root_lo then
		return out
	end

	local stack = acquire_stack()

	--index always refers to a node that already passed the overlap test
	local count = 0
	local top = 0

	while true do
		local c1 = child1[index]
		if c1 == NULL then
			count += 1
			out[count] = ids[index]
		else
			local c2 = child2[index]

			local lo1 = vector.max(aabb_min[c1], min :: any)
			local hi1 = vector.min(aabb_max[c1], max :: any)
			local hit1 = vector.min(lo1, hi1) == lo1

			local lo2 = vector.max(aabb_min[c2], min :: any)
			local hi2 = vector.min(aabb_max[c2], max :: any)
			local hit2 = vector.min(lo2, hi2) == lo2

			if hit1 then
				index = c1
				if hit2 then
					top += 1
					stack[top] = c2
				end
				continue
			elseif hit2 then
				index = c2
				continue
			end
		end

		if top == 0 then
			break
		end

		index = stack[top]
		top -= 1
	end

	release_stack(stack)
	return out
end

local function public_query_shape(tree: Tree, cframe: CFrame, shape: types.Shape): {number}
	local min, max = shape_aabb(cframe, shape)
	return public_query_aabb(tree, min :: any, max :: any)
end

--nothing is collected and the traversal stops at the first candidate the callback accepts,
--so neither the rest of the tree nor the rest of the candidates cost anything
local function public_query_aabb_any(tree: Tree, min: Vector3, max: Vector3, callback: (id: number) -> boolean): boolean
	local index = tree.root
	if index == NULL then
		return false
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local child1 = tree.child1
	local child2 = tree.child2
	local ids = tree.id

	local root_lo = vector.max(aabb_min[index], min :: any)
	local root_hi = vector.min(aabb_max[index], max :: any)
	if vector.min(root_lo, root_hi) ~= root_lo then
		return false
	end

	local stack = acquire_stack()

	local top = 0

	while true do
		local c1 = child1[index]
		if c1 == NULL then
			if callback(ids[index]) then
				release_stack(stack)
				return true
			end
		else
			local c2 = child2[index]

			local lo1 = vector.max(aabb_min[c1], min :: any)
			local hi1 = vector.min(aabb_max[c1], max :: any)
			local hit1 = vector.min(lo1, hi1) == lo1

			local lo2 = vector.max(aabb_min[c2], min :: any)
			local hi2 = vector.min(aabb_max[c2], max :: any)
			local hit2 = vector.min(lo2, hi2) == lo2

			if hit1 then
				index = c1
				if hit2 then
					top += 1
					stack[top] = c2
				end
				continue
			elseif hit2 then
				index = c2
				continue
			end
		end

		if top == 0 then
			release_stack(stack)
			return false
		end

		index = stack[top]
		top -= 1
	end
end

local function public_query_shape_any(tree: Tree, cframe: CFrame, shape: types.Shape, callback: (id: number) -> boolean): boolean
	local min, max = shape_aabb(cframe, shape)
	return public_query_aabb_any(tree, min :: any, max :: any, callback)
end

local function public_query_ray(tree: Tree, ray_origin: Vector3, ray_direction: Vector3): {number}
	local out = {}

	local index = tree.root
	if index == NULL then
		return out
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local child1 = tree.child1
	local child2 = tree.child2
	local ids = tree.id

	local inv_ray_dir = 1 / ray_direction

	if not ray_aabb(ray_origin, inv_ray_dir, aabb_min[index], aabb_max[index]) then
		return out
	end

	local stack = acquire_stack()

	local count = 0
	local top = 0

	while true do
		local c1 = child1[index]
		if c1 == NULL then
			count += 1
			out[count] = ids[index]
		else
			local c2 = child2[index]

			local hit1 = ray_aabb(ray_origin, inv_ray_dir, aabb_min[c1], aabb_max[c1])
			local hit2 = ray_aabb(ray_origin, inv_ray_dir, aabb_min[c2], aabb_max[c2])

			if hit1 then
				index = c1
				if hit2 then
					top += 1
					stack[top] = c2
				end
				continue
			elseif hit2 then
				index = c2
				continue
			end
		end

		if top == 0 then
			break
		end

		index = stack[top]
		top -= 1
	end

	release_stack(stack)
	return out
end

--shared by query_ray_closest and query_shapecast_closest

--a ray is passed as a cast whose box is a single point, which makes the arithmetic identical to a dedicated ray version
local function query_closest_swept(
	tree: Tree,
	cast_min: vector,
	cast_max: vector,
	inv_ray_dir: Vector3,
	narrow_phase: (id: number, max_fraction: number) -> number?,
	max_fraction: number?
): (number?, number?)
	local index = tree.root
	if index == NULL then
		return nil, nil
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local child1 = tree.child1
	local child2 = tree.child2
	local ids = tree.id

	--starting below 1 caps the search, anything the cast reaches later is pruned before its narrow phase runs
	local best_fraction = max_fraction or 1
	local best_id: number? = nil

	if swept_aabb_enter(cast_min, cast_max, inv_ray_dir, aabb_min[index], aabb_max[index], best_fraction) == TRUE_HUGE then
		return nil, nil
	end

	local stack = acquire_stack()
	local t_stack = acquire_stack()

	local top = 0

	while true do
		local c1 = child1[index]
		if c1 == NULL then
			local id = ids[index]
			local fraction = narrow_phase(id, best_fraction)
			if fraction ~= nil and fraction <= best_fraction then
				best_fraction = fraction
				best_id = id
			end
		else
			local c2 = child2[index]

			local enter1 = swept_aabb_enter(cast_min, cast_max, inv_ray_dir, aabb_min[c1], aabb_max[c1], best_fraction)
			local enter2 = swept_aabb_enter(cast_min, cast_max, inv_ray_dir, aabb_min[c2], aabb_max[c2], best_fraction)

			--descend into whichever child the segment enters first, so the closest hit is found
			--as early as possible and shrinks best_fraction for everything still queued
			if enter1 < enter2 then
				index = c1
				if enter2 ~= TRUE_HUGE then
					top += 1
					stack[top] = c2
					t_stack[top] = enter2
				end
				continue
			elseif enter2 ~= TRUE_HUGE then
				index = c2
				if enter1 ~= TRUE_HUGE then
					top += 1
					stack[top] = c1
					t_stack[top] = enter1
				end
				continue
			end
		end

		--a queued node is worth visiting only if the segment reaches it before the best hit
		repeat
			if top == 0 then
				release_stack(t_stack)
				release_stack(stack)
				return best_id, if best_id ~= nil then best_fraction else nil
			end

			index = stack[top]
			local queued_fraction = t_stack[top]
			top -= 1
		until queued_fraction <= best_fraction
	end
end

local function public_query_ray_closest(
	tree: Tree,
	ray_origin: Vector3,
	ray_direction: Vector3,
	narrow_phase: (id: number, max_fraction: number) -> number?,
	max_fraction: number?
): (number?, number?)
	return query_closest_swept(tree, ray_origin :: any, ray_origin :: any, 1 / ray_direction, narrow_phase, max_fraction)
end

local function public_query_shapecast(tree: Tree, shape: types.Shape, origin: CFrame, direction: Vector3): {number}
	local out = {}

	local index = tree.root
	if index == NULL then
		return out
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local child1 = tree.child1
	local child2 = tree.child2
	local ids = tree.id

	local inv_ray_dir = 1 / direction

	local cast_min, cast_max = shape_aabb(origin, shape)

	if not swept_aabb(cast_min, cast_max, inv_ray_dir, aabb_min[index], aabb_max[index]) then
		return out
	end

	local stack = acquire_stack()

	local count = 0
	local top = 0

	while true do
		local c1 = child1[index]
		if c1 == NULL then
			count += 1
			out[count] = ids[index]
		else
			local c2 = child2[index]

			local hit1 = swept_aabb(cast_min, cast_max, inv_ray_dir, aabb_min[c1], aabb_max[c1])
			local hit2 = swept_aabb(cast_min, cast_max, inv_ray_dir, aabb_min[c2], aabb_max[c2])

			if hit1 then
				index = c1
				if hit2 then
					top += 1
					stack[top] = c2
				end
				continue
			elseif hit2 then
				index = c2
				continue
			end
		end

		if top == 0 then
			break
		end

		index = stack[top]
		top -= 1
	end

	release_stack(stack)
	return out
end

local function public_query_shapecast_closest(
	tree: Tree,
	shape: types.Shape,
	origin: CFrame,
	direction: Vector3,
	narrow_phase: (id: number, max_fraction: number) -> number?,
	max_fraction: number?
): (number?, number?)
	local cast_min, cast_max = shape_aabb(origin, shape)
	return query_closest_swept(tree, cast_min, cast_max, 1 / direction, narrow_phase, max_fraction)
end

local function partition_sah(indices: {number}, bin_indices: {number}, boxes_min: {vector}, boxes_max: {vector}, start: number, count: number): number
	local bins_min = table.create(BIN_COUNT, HUGE_VECTOR) :: {vector}
	local bins_max = table.create(BIN_COUNT, -HUGE_VECTOR) :: {vector}
	local bins_count = table.create(BIN_COUNT, 0) :: {number}

	local planes_left_count = table.create(PLANE_COUNT) :: {number}
	local planes_left_aabb_min = table.create(PLANE_COUNT) :: {vector}
	local planes_left_aabb_max = table.create(PLANE_COUNT) :: {vector}
	local planes_right_count = table.create(PLANE_COUNT) :: {number}
	local planes_right_aabb_min = table.create(PLANE_COUNT) :: {vector}
	local planes_right_aabb_max = table.create(PLANE_COUNT) :: {vector}

	local center = (boxes_min[start] + boxes_max[start]) / 2
	local centroid_min = center
	local centroid_max = center

	for i = start + 1, start + count - 1 do
		center = (boxes_min[i] + boxes_max[i]) / 2
		centroid_min = vector.min(centroid_min, center)
		centroid_max = vector.max(centroid_max, center)
	end

	local d = centroid_max - centroid_min

	local axis_index
	local inv_d
	if d.x > d.y and d.x > d.z then
		axis_index = 0
		inv_d = d.x
	elseif d.y > d.z then
		axis_index = 1
		inv_d = d.y
	else
		axis_index = 2
		inv_d = d.z
	end

	inv_d = inv_d > 0 and 1 / inv_d or 0

	local min_c = axis_index == 0 and centroid_min.x or axis_index == 1 and centroid_min.y or centroid_min.z
	for i = start, start + count - 1 do
		local c = (boxes_min[i] + boxes_max[i]) / 2
		local c_choice = axis_index == 0 and c.x or axis_index == 1 and c.y or c.z
		local bin_index = math.floor(BIN_COUNT * (c_choice - min_c) * inv_d)
		bin_index = math.clamp(bin_index, 1, BIN_COUNT)
		bin_indices[i] = bin_index
		bins_count[bin_index] += 1
		bins_min[bin_index], bins_max[bin_index] = aabb_union(bins_min[bin_index], bins_max[bin_index], boxes_min[i], boxes_max[i])
	end

	planes_left_count[1] = bins_count[1]
	planes_left_aabb_min[1] = bins_min[1]
	planes_left_aabb_max[1] = bins_max[1]
	for i = 2, PLANE_COUNT do
		planes_left_count[i] = planes_left_count[i - 1] + bins_count[i]
		planes_left_aabb_min[i], planes_left_aabb_max[i] = aabb_union(planes_left_aabb_min[i - 1], planes_left_aabb_max[i - 1], bins_min[i], bins_max[i])
	end

	planes_right_count[PLANE_COUNT] = bins_count[BIN_COUNT]
	planes_right_aabb_min[PLANE_COUNT] = bins_min[BIN_COUNT]
	planes_right_aabb_max[PLANE_COUNT] = bins_max[BIN_COUNT]
	for i = PLANE_COUNT - 1, 1, -1 do
		planes_right_count[i] = planes_right_count[i + 1] + bins_count[i + 1]
		planes_right_aabb_min[i], planes_right_aabb_max[i] = aabb_union(planes_right_aabb_min[i + 1], planes_right_aabb_max[i + 1], bins_min[i + 1], bins_max[i + 1])
	end

	local min_cost = TRUE_HUGE
	local best_plane = 0
	for i = 1, PLANE_COUNT do
		local left_count = planes_left_count[i]
		local right_count = planes_right_count[i]
		local left_area = aabb_sah(planes_left_aabb_min[i], planes_left_aabb_max[i])
		local right_area = aabb_sah(planes_right_aabb_min[i], planes_right_aabb_max[i])

		local cost = left_count * left_area + right_count * right_area

		if cost < min_cost then
			best_plane = i
			min_cost = cost
		end
	end

	local i1 = start
	local i2 = start + count
	while i1 < i2 do
		while i1 < i2 and bin_indices[i1] <= best_plane do
			i1 += 1
		end

		while i1 < i2 and bin_indices[i2 - 1] > best_plane do
			i2 -= 1
		end

		if i1 < i2 then
			local i2_sub_1 = i2 - 1
			indices[i1], indices[i2_sub_1] = indices[i2_sub_1], indices[i1]
			boxes_min[i1], boxes_min[i2_sub_1] = boxes_min[i2_sub_1], boxes_min[i1]
			boxes_max[i1], boxes_max[i2_sub_1] = boxes_max[i2_sub_1], boxes_max[i1]
			bin_indices[i1], bin_indices[i2_sub_1] = bin_indices[i2_sub_1], bin_indices[i1]
			i1 += 1
			i2 = i2_sub_1
		end
	end

	if i1 > start and i1 < start + count then
		return i1
	else
		return start + count // 2
	end
end

local function build_tree(tree: Tree, leaf_count: number, leaf_indices: {number}, leaf_boxes_min: {vector}, leaf_boxes_max: {vector}): number
	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local parent = tree.parent
	local child1 = tree.child1
	local child2 = tree.child2
	local height = tree.height

	local bin_indices = table.create(leaf_count) :: {number}

	if leaf_count == 1 then
		parent[leaf_indices[1]] = NULL
		return leaf_indices[1]
	end

	local node_indices = {alloc(tree)}
	local child_counts = {-1}
	local start_indices = {1}
	local end_indices = {leaf_count + 1}
	local split_indices = {partition_sah(leaf_indices, bin_indices, leaf_boxes_min, leaf_boxes_max, 1, leaf_count)}
	local top = 1

	while true do
		local item_index = top
		child_counts[item_index] += 1

		if child_counts[item_index] == 2 then
			if top == 1 then
				break
			end

			local parent_index = top - 1
			local parent_node_index = node_indices[parent_index]

			if child_counts[parent_index] == 0 then
				child1[parent_node_index] = node_indices[item_index]
			else
				child2[parent_node_index] = node_indices[item_index]
			end

			local node_index = node_indices[item_index]
			parent[node_index] = parent_node_index

			local c1 = child1[node_index]
			local c2 = child2[node_index]

			aabb_min[node_index], aabb_max[node_index] = aabb_union(aabb_min[c1], aabb_max[c1], aabb_min[c2], aabb_max[c2])
			height[node_index] = 1 + math.max(height[c1], height[c2])

			top -= 1
		else
			local start_index, end_index
			if child_counts[item_index] == 0 then
				start_index = start_indices[item_index]
				end_index = split_indices[item_index]
			else
				start_index = split_indices[item_index]
				end_index = end_indices[item_index]
			end

			local count = end_index - start_index
			if count == 1 then
				local child_index = leaf_indices[start_index]
				local node_index = node_indices[item_index]

				if child_counts[item_index] == 0 then
					child1[node_index] = child_index
				else
					child2[node_index] = child_index
				end

				parent[child_index] = node_index
			else
				top += 1
				node_indices[top] = alloc(tree)
				child_counts[top] = -1
				start_indices[top] = start_index
				end_indices[top] = end_index
				split_indices[top] = partition_sah(leaf_indices, bin_indices, leaf_boxes_min, leaf_boxes_max, start_index, count)
			end
		end
	end

	local root_index = node_indices[1]

	local c1 = child1[root_index]
	local c2 = child2[root_index]

	aabb_min[root_index], aabb_max[root_index] = aabb_union(aabb_min[c1], aabb_max[c1], aabb_min[c2], aabb_max[c2])
	height[root_index] = 1 + math.max(height[c1], height[c2])

	return root_index
end

--when every shape in a tree grows by the same distance, so does every node,
--and a parent still contains a child that moved with it

--that makes a uniform inflation a pass over the bounds rather
--than a rebuild, no node changes place, so the topology it was built with stays valid

--free list nodes are covered too, which costs nothing since allocation overwrites their bounds
local function expand_bounds(tree: Tree, amount: number)
	if amount <= 0 then
		return
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local expand = vector.one * amount

	for index = 1, tree.node_count do
		aabb_min[index] -= expand
		aabb_max[index] += expand
	end
end

local function compute_cost_ratio(tree: Tree): number
	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local height = tree.height

	local cost = 0
	local leaf_cost = 0

	--every allocated node is either part of the tree or on the free list (height -1), so a flat
	--scan covers exactly the nodes a walk from the root would, sequentially and without a stack
	for index = 1, tree.node_count do
		local node_height = height[index]
		if node_height > 0 then
			cost += aabb_sah(aabb_min[index], aabb_max[index])
		elseif node_height == 0 then
			leaf_cost += aabb_sah(aabb_min[index], aabb_max[index])
		end
	end

	return cost / leaf_cost
end

local function rebuild_tree(tree: Tree, full_build: boolean): number
	if tree.root == NULL then
		tree.base_cost_ratio = nil
		return 0
	end

	local aabb_min = tree.aabb_min
	local aabb_max = tree.aabb_max
	local parent = tree.parent
	local child1 = tree.child1
	local child2 = tree.child2
	local height = tree.height
	local enlarged = tree.enlarged

	local leaf_indices = {}
	local leaf_boxes_min = {}
	local leaf_boxes_max = {}

	local leaf_count = 0
	local stack = {}
	local stack_count = 0

	local node_index = tree.root

	while true do
		if height[node_index] == 0 or (not enlarged[node_index] and not full_build) then
			leaf_count += 1
			leaf_indices[leaf_count] = node_index
			leaf_boxes_min[leaf_count] = aabb_min[node_index]
			leaf_boxes_max[leaf_count] = aabb_max[node_index]
			parent[node_index] = NULL
		else
			local doomed_node_index = node_index

			stack[stack_count] = child2[node_index]
			stack_count += 1

			node_index = child1[node_index]
			free(tree, doomed_node_index)
			continue
		end

		if stack_count == 0 then
			break
		end

		stack_count -= 1
		node_index = stack[stack_count]
	end

	tree.root = build_tree(tree, leaf_count, leaf_indices, leaf_boxes_min, leaf_boxes_max)
	tree.base_cost_ratio = compute_cost_ratio(tree)

	return leaf_count
end

local function should_rebuild(dyn_tree: DynamicTree): boolean
	if dyn_tree.root == NULL then
		return false
	end

	if dyn_tree.base_cost_ratio == nil then
		if dyn_tree.proxy_count < INITIAL_REBUILD_THRESHOLD then
			return false
		end

		return true
	end

	local ratio = compute_cost_ratio(dyn_tree)
	if ratio > dyn_tree.base_cost_ratio * REBUILD_RATIO_THRESHOLD then
		return true
	end

	return false
end

local function full_rebuild(tree: Tree): number
	return rebuild_tree(tree, true)
end

local function partial_rebuild(dyn_tree: DynamicTree): number
	return rebuild_tree(dyn_tree, false)
end

local function new_dynamic_tree(config: Config): DynamicTree
	return {
		padding = vector.one * config.aabb_padding,
		root = NULL,
		node_count = 0,
		free_list = NULL,
		aabb_min = {},
		aabb_max = {},
		parent = {},
		child1 = {},
		child2 = {},
		height = {},
		enlarged = {},
		id = {},
		cf = {},
		shape = {},
		leaf_map = {},
		proxy_count = 0,
		insert = public_insert,
		remove = public_remove,
		move = public_move,
		resize = public_resize,
		clear = public_clear,
		query_aabb = public_query_aabb,
		query_shape = public_query_shape,
		query_aabb_any = public_query_aabb_any,
		query_shape_any = public_query_shape_any,
		query_ray = public_query_ray,
		query_ray_closest = public_query_ray_closest,
		query_shapecast = public_query_shapecast,
		query_shapecast_closest = public_query_shapecast_closest,
		should_rebuild = should_rebuild,
		full_rebuild = full_rebuild,
		partial_rebuild = partial_rebuild,
	}
end

local function public_static_insert(tree: StaticTree, id: number, cf: CFrame, shape: types.Shape)
	--combines insert_leaf and public_insert while only having the minimum code necessary to build a valid tree for rebuilding
	local leaf_map = tree.leaf_map
	if leaf_map[id] then
		error("id already registered")
	end

	local min, max = shape_aabb(cf, shape)

	local index = alloc(tree)

	tree.aabb_min[index] = min
	tree.aabb_max[index] = max
	tree.height[index] = 0
	tree.id[index] = id
	tree.cf[index] = cf
	tree.shape[index] = shape

	tree.proxy_count += 1
	leaf_map[id] = index

	local parent = tree.parent
	local child1 = tree.child1
	local child2 = tree.child2

	if tree.root == NULL then
		tree.root = index
		parent[index] = NULL
		return
	end

	local new_parent_index = alloc(tree)
	local old_root = tree.root
	parent[new_parent_index] = NULL
	child1[new_parent_index] = old_root
	child2[new_parent_index] = index
	tree.height[new_parent_index] = tree.height[old_root] + 1
	--the new parent is always the new root, so unioning its two children keeps every
	--internal AABB valid without a walk, and rebuild recomputes them all anyway
	tree.aabb_min[new_parent_index], tree.aabb_max[new_parent_index] = aabb_union(tree.aabb_min[old_root], tree.aabb_max[old_root], min, max)
	tree.root = new_parent_index
	parent[old_root] = new_parent_index
	parent[index] = new_parent_index
end

local function public_static_remove(tree: StaticTree, id: number)
	--combines remove_leaf and public_remove while also removing the refits
	local leaf_map = tree.leaf_map
	local index = leaf_map[id]
	if not index then
		return
	end

	leaf_map[id] = nil
	tree.proxy_count -= 1

	local parent = tree.parent
	local child1 = tree.child1
	local child2 = tree.child2

	if index == tree.root then
		tree.root = NULL
		free(tree, index)
		return
	end

	local parent_index = parent[index]
	local grand_parent_index = parent[parent_index]
	local sibling = child1[parent_index] == index
		and child2[parent_index]
		or child1[parent_index]

	if grand_parent_index == NULL then
		tree.root = sibling
		parent[sibling] = NULL
		free(tree, parent_index)
	else
		if child1[grand_parent_index] == parent_index then
			child1[grand_parent_index] = sibling
		else
			child2[grand_parent_index] = sibling
		end

		parent[sibling] = grand_parent_index

		free(tree, parent_index)
	end

	free(tree, index)
end

local function new_static_tree(): StaticTree
	return {
		root = NULL,
		node_count = 0,
		free_list = NULL,
		aabb_min = {},
		aabb_max = {},
		parent = {},
		child1 = {},
		child2 = {},
		height = {},
		enlarged = {},
		id = {},
		cf = {},
		shape = {},
		leaf_map = {},
		proxy_count = 0,
		clear = public_clear,
		query_aabb = public_query_aabb,
		query_shape = public_query_shape,
		query_aabb_any = public_query_aabb_any,
		query_shape_any = public_query_shape_any,
		query_ray = public_query_ray,
		query_ray_closest = public_query_ray_closest,
		query_shapecast = public_query_shapecast,
		query_shapecast_closest = public_query_shapecast_closest,
		insert = public_static_insert,
		remove = public_static_remove,
		full_rebuild = full_rebuild
	}
end

return {
	new_dynamic = new_dynamic_tree,
	new_static = new_static_tree,
	expand_bounds = expand_bounds
}