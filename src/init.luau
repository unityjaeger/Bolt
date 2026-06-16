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

local DEFAULT_CONVEX_RADIUS = .05

export type Shape = types.Shape
export type BoxShape = types.BoxShape
export type SphereShape = types.SphereShape
export type EllipsoidShape = types.EllipsoidShape
export type CapsuleShape = types.CapsuleShape
export type CylinderShape = types.CylinderShape
export type WedgeShape = types.WedgeShape
export type CornerWedgeShape = types.CornerWedgeShape
export type MeshShape = types.MeshShape
export type Hull = types.Hull
export type HullShape = types.HullShape
export type Support<T = Shape> = types.Support<T>

export type TreeNode = types.TreeNode
export type Tree = types.Tree
export type DynamicTree = types.DynamicTree
export type StaticTree = types.StaticTree
export type DynamicTreeConfig = types.DynamicTreeConfig

local function create_box(size: Vector3, convex_radius: number?): types.BoxShape
	return {
		type = shape_map.BOX,
		half_extents = size / 2,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}	
end

local function create_sphere(radius: number, convex_radius: number?): types.SphereShape
	return {
		type = shape_map.SPHERE,
		radius = radius,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_ellipsoid(size: Vector3, convex_radius: number?): types.EllipsoidShape
	return {
		type = shape_map.ELLIPSOID,
		half_extents = size / 2,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_capsule(radius: number, height: number, convex_radius: number?): types.CapsuleShape
	return {
		type = shape_map.CAPSULE,
		radius = radius,
		half_height = height / 2,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_cylinder(radius: number, height: number, convex_radius: number?): types.CylinderShape
	return {
		type = shape_map.CYLINDER,
		radius = radius,
		half_height = height / 2,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_wedge(size: Vector3, convex_radius: number?): types.WedgeShape
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
		half_extents = half_extents,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_corner_wedge(size: Vector3, convex_radius: number?): types.CornerWedgeShape
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
		half_extents = half_extents,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_mesh(mesh_info: {hulls: {Hull}, size: Vector3}, size: Vector3, convex_radius: number?): types.MeshShape
	local hull_shapes = {}

	local scale = size / mesh_info.size

	for i, v in mesh_info.hulls do
		hull_shapes[i] = {
			type = shape_map.HULL,
			vertices = v.vertices,
			offset = v.offset,
			adjacency = v.adjacency,
			scale = scale,
			convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
		}
	end

	local local_tree = aabb_tree.new_static()
	for i, hull in hull_shapes do
		local_tree:insert(i, CFrame.new(hull.offset), hull)
	end
	local_tree:full_rebuild()

	return {
		type = shape_map.MESH,
		hulls = hull_shapes,
		local_tree = local_tree,
		half_extents = size / 2,
		original_half_extents = mesh_info.size / 2,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function resize_mesh(mesh: MeshShape, size: Vector3)
	local hulls = mesh.hulls
	local local_tree = mesh.local_tree

	local new_half_extents = size / 2
	local scale = new_half_extents / mesh.original_half_extents

	for _, hull in hulls do
		hull.scale = scale
	end

	mesh.half_extents = size / 2

	local_tree:clear()
	for i, hull in hulls do
		local_tree:insert(i, CFrame.new(hull.offset), hull)
	end
	local_tree:full_rebuild()
end

local function create_from_part(part: BasePart, convex_radius: number?): types.Shape
	if part:IsA("MeshPart") or part:IsA("UnionOperation") then
		error("meshes and unions cannot be created from parts")
	elseif part:IsA("Part") then
		local shape = (part :: Part).Shape
		local size = part.Size

		if shape == Enum.PartType.Block then
			return create_box(size, convex_radius)
		elseif shape == Enum.PartType.Ball then
			local sx, sy, sz = size.X, size.Y, size.Z
			if sx ~= sy or sx ~= sz or sy ~= sz then
				return create_ellipsoid(size, convex_radius)
			end
			return create_sphere(sx/2, convex_radius)
		elseif shape == Enum.PartType.Cylinder then
			local sx, sy, sz = size.X, size.Y, size.Z
			if sy ~= sz then
				error("cylinder does not have a consistent radius")
			end
			return create_cylinder(sy/2, sx, convex_radius)
		elseif shape == Enum.PartType.Wedge then
			return create_wedge(size, convex_radius)
		elseif shape == Enum.PartType.CornerWedge then
			return create_corner_wedge(size, convex_radius)
		else
			error("just so the type engine shuts up")
		end
	else
		error("got unsupported instance type" .. part.ClassName)
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
	create_mesh = create_mesh,
	create_from_part = create_from_part,

	resize_mesh = resize_mesh,

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