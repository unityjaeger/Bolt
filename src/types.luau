export type Shape = {
	type: number,
	--inflates the shape by this distance in every direction, as if it were swept by a sphere of
	--this radius, every query treats the inflated surface as the real one
	
	--must be nonnegative, a negative value is ignored rather than shrinking the shape
	margin: number?
}

export type BoxShape = Shape & {
	half_extents: Vector3
}

export type SphereShape = Shape & {
	radius: number
}

export type EllipsoidShape = Shape & {
	half_extents: Vector3
}

export type CapsuleShape = Shape & {
	radius: number,
	half_height: number
}

export type CylinderShape = Shape & {
	radius: number,
	half_height: number
}

export type WedgeShape = Shape & {
	half_extents: Vector3,
	local_slope: Vector3,
	local_edge: Vector3,
	vertices: {Vector3}
}

export type CornerWedgeShape = Shape & {
	half_extents: Vector3,
	local_slope1: Vector3,
	local_slope2: Vector3,
	local_edge1: Vector3,
	local_edge2: Vector3,
	local_edge3: Vector3,
	vertices: {Vector3}
}

export type Hull = {
	offset: Vector3,
	vertices: {Vector3},
	adjacency: {{number}}
}

export type MeshShape = Shape & {
	half_extents: Vector3,
	original_half_extents: Vector3,
	hulls: {HullShape},
	local_tree: StaticTree,
	--how much of the mesh's margin the local tree's bounds already account for,
	--so a margin change widens them by the difference instead of rebuilding
	
	--it only rises, since bounds that stay wide after a margin drops will
	--cost a rejected candidate while tightened ones would cull real contacts

	--resize_mesh rebuilds the bounds and resets it
	tree_margin: number
}

export type HullShape = Shape & Hull & {
	scale: Vector3,
	original_half_extents: Vector3
}

export type Support<T = Shape> = (shape: T, direction: Vector3) -> Vector3

export type Tree = {
	root: number,
	node_count: number,
	free_list: number,
	aabb_min: {vector},
	aabb_max: {vector},
	parent: {number},
	child1: {number},
	child2: {number},
	height: {number},
	enlarged: {boolean},
	id: {number},
	cf: {CFrame},
	shape: {Shape},
	leaf_map: {number},
	proxy_count: number,
	base_cost_ratio: number?,
	clear: (dyn_tree: Tree) -> (),
	query_aabb: (tree: Tree, min: Vector3, max: Vector3) -> {number},
	query_ray: (tree: Tree, ray_origin: Vector3, ray_direction: Vector3) -> {number},
	query_ray_closest: (
		tree: Tree,
		ray_origin: Vector3,
		ray_direction: Vector3,
		narrow_phase: (id: number, max_fraction: number) -> number?,
		max_fraction: number?
	) -> (number?, number?),
	query_shape: (tree: Tree, cframe: CFrame, shape: Shape) -> {number},
	query_aabb_any: (tree: Tree, min: Vector3, max: Vector3, predicate: (id: number) -> boolean) -> boolean,
	query_shape_any: (tree: Tree, cframe: CFrame, shape: Shape, predicate: (id: number) -> boolean) -> boolean,
	query_shapecast: (tree: Tree, shape: Shape, origin: CFrame, direction: Vector3) -> {number},
	query_shapecast_closest: (
		tree: Tree,
		shape: Shape,
		origin: CFrame,
		direction: Vector3,
		narrow_phase: (id: number, max_fraction: number) -> number?,
		max_fraction: number?
	) -> (number?, number?),
	full_rebuild: (tree: Tree) -> number
}

export type DynamicTree = Tree & {
	padding: vector,
	insert: (dyn_tree: DynamicTree, id: number, cf: CFrame, shape: Shape) -> (),
	remove: (dyn_tree: DynamicTree, id: number) -> (),
	move: (dyn_tree: DynamicTree, id: number, cf: CFrame) -> (),
	resize: (dyn_tree: DynamicTree, id: number, shape: Shape) -> (),
	should_rebuild: (dyn_tree: DynamicTree) -> boolean,
	partial_rebuild: (dyn_tree: DynamicTree) -> number
}

export type StaticTree = Tree & {
	insert: (tree: StaticTree, id: number, cf: CFrame, shape: Shape) -> (),
	remove: (tree: StaticTree, id: number) -> ()
}

export type DynamicTreeConfig = {
	aabb_padding: number
}

return {}