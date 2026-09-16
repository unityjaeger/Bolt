--!strict

local types = require("@self/types")
local shape_map = require("@self/shape_map")
local box = require("@self/box")
local sphere = require("@self/sphere")
local capsule = require("@self/capsule")
local ray = require("@self/ray")
local gjk = require("@self/gjk")
local aabb_tree = require("@self/aabb_tree")
local mpr = require("@self/mpr")
local sat = require("@self/sat")
local dispatch = require("@self/dispatch")

local UP = Vector3.yAxis
local RIGHT = Vector3.xAxis
local LOOK = Vector3.zAxis

export type Shape = types.Shape
export type BoxShape = types.BoxShape
export type SphereShape = types.SphereShape
export type EllipsoidShape = types.EllipsoidShape
export type CapsuleShape = types.CapsuleShape
export type CylinderShape = types.CylinderShape
export type WedgeShape = types.WedgeShape
export type CornerWedgeShape = types.CornerWedgeShape
export type Child = types.Child
export type Composite = types.Composite
export type StaticComposite = types.StaticComposite
export type DynamicComposite = types.DynamicComposite
export type Hull = types.Hull
export type HullShape = types.HullShape
export type Support<T = Shape> = types.Support<T>

export type Tree = types.Tree
export type DynamicTree = types.DynamicTree
export type StaticTree = types.StaticTree
export type DynamicTreeConfig = types.DynamicTreeConfig

local function create_box(size: Vector3): BoxShape
	return {
		type = shape_map.BOX,
		half_extents = size / 2
	}	
end

local function create_sphere(radius: number): SphereShape
	return {
		type = shape_map.SPHERE,
		radius = radius
	}
end

local function create_ellipsoid(size: Vector3): EllipsoidShape
	return {
		type = shape_map.ELLIPSOID,
		half_extents = size / 2
	}
end

local function create_capsule(radius: number, height: number): CapsuleShape
	return {
		type = shape_map.CAPSULE,
		radius = radius,
		half_height = height / 2
	}
end

local function create_cylinder(radius: number, height: number): CylinderShape
	return {
		type = shape_map.CYLINDER,
		radius = radius,
		half_height = height / 2
	}
end

local function create_wedge(size: Vector3): WedgeShape
	local half_extents = size / 2	

	local hx, hy, hz = half_extents.X, half_extents.Y, half_extents.Z

	local sr = hx * RIGHT
	local su = hy * UP
	local sl = hz * LOOK

	local v1 = sr + sl - su
	local v2 = sr - sl - su
	local v3 = sr + sl + su

	return {
		type = shape_map.WEDGE,
		vertices = {v1, v2, v3},
		local_slope = vector.normalize(vector.create(0, hz, -hy)) :: any,
		local_edge = vector.normalize(vector.create(0, hy, hz)) :: any,
		half_extents = half_extents
	}
end

local function create_corner_wedge(size: Vector3): CornerWedgeShape
	local half_extents = size / 2	

	local hx, hy, hz = half_extents.X, half_extents.Y, half_extents.Z

	local sr = hx * RIGHT
	local su = hy * UP
	local sl = hz * LOOK

	local v1 = sr + sl - su
	local v2 = sr - sl - su
	local v3 = sr - sl + su
	local v4 = -sr - sl - su
	local v5 = -sr + sl - su

	return {
		type = shape_map.CORNER_WEDGE,
		vertices = {v1, v2, v3, v4, v5},
		local_slope1 = vector.normalize(vector.create(0, hz, hy)) :: any,
		local_slope2 = vector.normalize(vector.create(-hy, hx, 0)) :: any,
		local_edge1 = vector.normalize(vector.create(0, hy, -hz)) :: any,
		local_edge2 = vector.normalize(vector.create(hx, hy, 0)) :: any,
		local_edge3 = vector.normalize(vector.create(hx, hy, -hz)) :: any,
		half_extents = half_extents
	}
end

--a composite whose children never move

--its tree is built once with the static tree's binned SAH, which is the better tree
local function create_static_composite(children: {Child}): StaticComposite
	local local_tree = aabb_tree.new_static()
	for i, child in children do
		local_tree:insert(i, child.cf, child.shape)
	end
	local_tree:full_rebuild()

	return {
		type = shape_map.COMPOSITE,
		children = children,
		local_tree = local_tree,
		tree_margin = 0
	}
end

--a composite whose children move, an animated rig being the obvious one

--its tree is dynamic so a child can be moved without rebuilding, and set_child is the only thing that may move one
local function create_dynamic_composite(children: {Child}, config: DynamicTreeConfig?): DynamicComposite
	local local_tree = aabb_tree.new_dynamic(config or {aabb_padding = 0})
	for i, child in children do
		local_tree:insert(i, child.cf, child.shape)
	end

	return {
		type = shape_map.COMPOSITE,
		children = children,
		local_tree = local_tree,
		tree_margin = 0,
		dirty = false
	}
end

--moves one child inside its composite, the composite is marked so anything cached off its overall size knows to look again
local function set_child(composite: DynamicComposite, index: number, cf: CFrame)
	local child = composite.children[index]
	child.cf = cf

	composite.local_tree:move(index, cf)
	composite.dirty = true
end

--convex decomposition data describes a static composite: one hull per child, each at a fixed offset
local function create_mesh(mesh_info: {hulls: {Hull}, size: Vector3}, size: Vector3): StaticComposite
	local scale = size / mesh_info.size
	local original_half_extents = mesh_info.size / 2

	local children = table.create(#mesh_info.hulls) :: {Child}
	for i, v in mesh_info.hulls do
		children[i] = {
			cf = CFrame.new(v.offset * scale),
			shape = {
				type = shape_map.HULL,
				vertices = v.vertices,
				offset = v.offset,
				adjacency = v.adjacency,
				scale = scale,
				original_half_extents = original_half_extents
			}
		}
	end

	return create_static_composite(children)
end

local function create_hull(hull_info: {vertices: {Vector3}, adjacency: {{number}}, size: Vector3}, size: Vector3): HullShape
	return {
		type = shape_map.HULL,
		vertices = hull_info.vertices,
		adjacency = hull_info.adjacency,
		--a standalone hull is placed entirely by the cframe it is queried with
		--offset exists for mesh hulls, which sit at a fixed position relative to their mesh origin
		--and nothing outside the mesh paths ever use it
		offset = Vector3.zero,
		scale = size / hull_info.size,
		original_half_extents = hull_info.size / 2
	}
end

local function resize_hull(hull: HullShape, size: Vector3)
	--a hull has no local tree or cached extents to rebuild, its bounds come from the scaled
	--vertices, so the scale is the only thing a resize has to touch
	hull.scale = (size / 2) / hull.original_half_extents
end

--the radius of the smallest sphere about a shape's origin that still contains it, whatever its orientation

--an AABB grows and shrinks as a shape turns, this does not, which is what a bound has
--to be built from when it must hold across rotations rather than at one of them

--this is exact for spheres, capsules, cylinders, boxes, ellipsoids, hulls and composites

--wedges are bounded by the box their half extents describe and take that box's diagonal, which is conservative
local function circumradius(shape: Shape): number
	local shape_type = shape.type
	local base

	if shape_type == shape_map.SPHERE then
		base = (shape :: SphereShape).radius
	elseif shape_type == shape_map.CAPSULE then
		local capsule = shape :: CapsuleShape
		base = capsule.half_height + capsule.radius
	elseif shape_type == shape_map.CYLINDER then
		local cylinder = shape :: CylinderShape
		base = math.sqrt(cylinder.half_height * cylinder.half_height + cylinder.radius * cylinder.radius)
	elseif shape_type == shape_map.COMPOSITE then
		--measured from the composite's own tree, so it follows its children
		local composite = shape :: Composite
		local tree = composite.local_tree
		local root = tree.root

		if root == 0 then
			base = 0
		else
			local applied = vector.one * composite.tree_margin
			local local_min = tree.aabb_min[root] + applied
			local local_max = tree.aabb_max[root] - applied

			--the furthest corner from the composite's origin, which is what it spins about
			local furthest = vector.max(vector.abs(local_min), vector.abs(local_max))
			base = vector.magnitude(furthest)
		end
	elseif shape_type == shape_map.ELLIPSOID then
		--an ellipsoid reaches furthest along its longest axis, the box diagonal would overshoot it
		local half_extents = (shape :: EllipsoidShape).half_extents
		base = math.max(half_extents.X, half_extents.Y, half_extents.Z)
	elseif shape_type == shape_map.HULL then
		--the vertices are measured rather than the declared size, so this agrees with the bounds an
		--aabb tree computes for the same hull
		local hull = shape :: HullShape
		local vertices = hull.vertices
		local scale = hull.scale

		local furthest_sq = 0
		for i = 1, #vertices do
			local scaled = vertices[i] * scale
			local distance_sq = vector.dot(scaled :: any, scaled :: any)
			if distance_sq > furthest_sq then
				furthest_sq = distance_sq
			end
		end

		base = math.sqrt(furthest_sq)
	else
		--box, wedge and corner wedge are all bounded by their half extents
		base = vector.magnitude((shape :: BoxShape).half_extents :: any)
	end

	--a margin inflates the shape in every direction, so it adds to the radius directly,
	--negatives are ignored here exactly as gjk and mpr ignore them
	return base + math.max(0, shape.margin or 0)
end

--rescales every hull of a composite built from mesh data, and rebuilds the tree around the new
--offsets, only meaningful for composites create_mesh produced, since it assumes hull children
local function resize_mesh(mesh: StaticComposite, size: Vector3)
	local children = mesh.children
	local local_tree = mesh.local_tree

	local first = children[1]
	if first == nil then
		return
	end

	local hull = first.shape :: HullShape
	local scale = (size / 2) / hull.original_half_extents

	for _, child in children do
		local child_hull = child.shape :: HullShape
		child_hull.scale = scale
		child.cf = CFrame.new(child_hull.offset * scale)
	end

	local_tree:clear()
	for i, child in children do
		local_tree:insert(i, child.cf, child.shape)
	end
	local_tree:full_rebuild()

	--the children carry whatever margin they were last synced to, so the rebuilt bounds already
	--account for exactly that much and nothing further needs widening
	local child_margin = hull.margin or 0
	mesh.tree_margin = math.max(child_margin, 0)
end

local function create_from_part(part: Part): Shape
	if part:IsA("MeshPart") or part:IsA("UnionOperation") then
		error("meshes and unions cannot be created from parts")
	elseif part:IsA("Part") then
		local shape = (part :: Part).Shape
		local size = part.Size

		if shape == Enum.PartType.Block then
			return create_box(size)
		elseif shape == Enum.PartType.Ball then
			local sx, sy, sz = size.X, size.Y, size.Z
			if sx ~= sy or sx ~= sz or sy ~= sz then
				return create_ellipsoid(size)
			end
			return create_sphere(sx/2)
		elseif shape == Enum.PartType.Cylinder then
			local sx, sy, sz = size.X, size.Y, size.Z
			if sy ~= sz then
				error("cylinder does not have a consistent radius")
			end
			return create_cylinder(sy/2, sx)
		elseif shape == Enum.PartType.Wedge then
			return create_wedge(size)
		elseif shape == Enum.PartType.CornerWedge then
			return create_corner_wedge(size)
		else
			error("just so the type engine shuts up")
		end
	else
		error("got unsupported instance type " .. part.ClassName)
	end
end

return {
	create_box = create_box,
	create_sphere = create_sphere,
	create_ellipsoid = create_ellipsoid,
	create_capsule = create_capsule,
	create_cylinder = create_cylinder,
	create_wedge = create_wedge,
	create_corner_wedge = create_corner_wedge,
	create_static_composite = create_static_composite,
	create_dynamic_composite = create_dynamic_composite,
	set_child = set_child,
	create_mesh = create_mesh,
	create_hull = create_hull,
	create_from_part = create_from_part,

	resize_mesh = resize_mesh,
	resize_hull = resize_hull,

	circumradius = circumradius,

	collision = {
		box_box = box.box_box,
		box_sphere = box.box_sphere,
		box_capsule = box.box_capsule,
		sphere_sphere = sphere.sphere_sphere,
		sphere_capsule = sphere.sphere_capsule,
		capsule_capsule = capsule.capsule_capsule
	},

	raycast = {
		box = ray.ray_box,
		sphere = ray.ray_sphere,
		capsule = ray.ray_capsule
	},

	gjk = {
		intersects = gjk.intersects,
		raycast = gjk.raycast,
		shapecast_simple = gjk.shapecast_simple,
		shapecast = gjk.shapecast
	},

	aabb_tree = {
		new = aabb_tree.new_dynamic,
		new_static = aabb_tree.new_static
	},

	shape_aabb = aabb_tree.shape_aabb,

	mpr = {
		intersects = mpr.intersects,
		is_separated = mpr.is_separated
	},

	sat = {
		box_box = sat.box_box,
		box_wedge = sat.box_wedge,
		wedge_wedge = sat.wedge_wedge,
		wedge_corner_wedge = sat.wedge_corner_wedge,
		box_corner_wedge = sat.box_corner_wedge,
		corner_wedge_corner_wedge = sat.corner_wedge_corner_wedge
	},

	dispatch = {
		gjk = {
			intersects = dispatch.dispatch_gjk_intersects,
			raycast = dispatch.dispatch_gjk_raycast,
			shapecast_simple = dispatch.dispatch_gjk_shapecast_simple,
			shapecast = dispatch.dispatch_gjk_shapecast
		},
		mpr = {
			mesh_primitive = dispatch.dispatch_mpr_mesh_primitive,
			mesh_mesh = dispatch.dispatch_mpr_mesh_mesh
		}
	}
}