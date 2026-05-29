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

local UP = Vector3.yAxis
local RIGHT = Vector3.xAxis
local LOOK = -Vector3.zAxis

local DEFAULT_CONVEX_RADIUS = .05

export type Shape = types.Shape
export type BoxShape = types.BoxShape
export type SphereShape = types.SphereShape
export type CapsuleShape = types.CapsuleShape
export type CylinderShape = types.CylinderShape
export type WedgeShape = types.WedgeShape
export type CornerWedgeShape = types.CornerWedgeShape
export type MeshShape = types.MeshShape
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

	local sr = half_extents.X * RIGHT
	local su = half_extents.Y * UP
	local sl = half_extents.Z * LOOK

	local v1 = sr + sl - su
	local v2 = sr - sl - su
	local v3 = sr - sl + su

	return {
		type = shape_map.WEDGE,
		vertices = {v1, v2, v3},
		half_extents = half_extents,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_corner_wedge(size: Vector3, convex_radius: number?): types.CornerWedgeShape
	local half_extents = size / 2	

	local sr = half_extents.X * RIGHT
	local su = half_extents.Y * UP
	local sl = half_extents.Z * LOOK

	local v1 = sr + sl - su
	local v2 = sr - sl - su
	local v3 = sr + sl + su
	local v4 = -sr - sl - su
	local v5 = -sr + sl - su

	return {
		type = shape_map.CORNER_WEDGE,
		vertices = {v1, v2, v3, v4, v5},
		half_extents = half_extents,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_mesh(part: MeshPart | UnionOperation, convex_radius: number?): types.MeshShape
	return {
		type = shape_map.MESH,
		part = part,
		convex_radius = convex_radius or DEFAULT_CONVEX_RADIUS
	}
end

local function create_from_part(part: BasePart, convex_radius: number?): types.Shape
	if part:IsA("MeshPart") or part:IsA("UnionOperation") then
		return create_mesh(part, convex_radius)
	elseif part:IsA("Part") then
		local shape = (part :: Part).Shape
		local size = part.Size

		if shape == Enum.PartType.Block then
			return create_box(size, convex_radius)
		elseif shape == Enum.PartType.Ball then
			local sx, sy, sz = size.X, size.Y, size.Z
			if sx ~= sy or sx ~= sz or sy ~= sz then
				error("sphere does not have a consistent size")
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
	create_capsule = create_capsule,
	create_cylinder = create_cylinder,
	create_wedge = create_wedge,
	create_corner_wedge = create_corner_wedge,
	create_mesh = create_mesh,
	create_from_part = create_from_part,

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
	}
}