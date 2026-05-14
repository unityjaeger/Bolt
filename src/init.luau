--!strict

local types = require(script.types)
local shape_map = require(script.shape_map)
local box = require(script.box)
local sphere = require(script.sphere)
local capsule = require(script.capsule)
local ray = require(script.ray)
local gjk = require(script.gjk)

local UP = Vector3.yAxis
local RIGHT = Vector3.xAxis
local LOOK = -Vector3.zAxis

local function create_box(size: Vector3): types.BoxShape
	return {
		type = shape_map.BOX,
		half_extents = size / 2
	}	
end

local function create_sphere(radius: number): types.SphereShape
	return {
		type = shape_map.SPHERE,
		radius = radius
	}
end

local function create_capsule(radius: number, height: number): types.CapsuleShape
	return {
		type = shape_map.CAPSULE,
		radius = radius,
		half_height = height / 2
	}
end

local function create_cylinder(radius: number, height: number): types.CylinderShape
	return {
		type = shape_map.CYLINDER,
		radius = radius,
		half_height = height / 2
	}
end

local function create_wedge(size: Vector3): types.WedgeShape
	local half_extents = size / 2	
	local sx, sy, sz = half_extents.X, half_extents.Y, half_extents.Z

	local v1 = RIGHT * sx + LOOK * sz - UP * sy
	local v2 = v1 - LOOK * sz * 2
	local v3 = v2 + UP * sy * 2
	
	return {
		type = shape_map.WEDGE,
		vertices = {v1, v2, v3},
		half_extents = half_extents
	}
end

local function create_corner_wedge(size: Vector3): types.CornerWedgeShape
	local half_extents = size / 2	
	local sx, sy, sz = half_extents.X, half_extents.Y, half_extents.Z
	
	local v1 = RIGHT * sx + LOOK * sz - UP * sy
	local v2 = v1 - LOOK * sz * 2
	local v3 = v1 + UP * sy * 2
	local v4 = v2 - RIGHT * sx * 2
	local v5 = v4 + LOOK * sz * 2
	
	return {
		type = shape_map.CORNER_WEDGE,
		vertices = {v1, v2, v3, v4, v5},
		half_extents = half_extents
	}
end

local function create_mesh(part: MeshPart): types.MeshShape
	return {
		type = shape_map.MESH,
		part = part
	}
end

local function create_from_part(part: BasePart): types.Shape
	if part:IsA("MeshPart") then
		return create_mesh(part)
	elseif part:IsA("Part") then
		local shape = (part :: Part).Shape
		local size = part.Size
		
		if shape == Enum.PartType.Block then
			return create_box(size)
		elseif shape == Enum.PartType.Ball then
			local sx, sy, sz = size.X, size.Y, size.Z
			if sx ~= sy or sx ~= sz or sy ~= sz then
				error("sphere does not have a consistent size")
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
	}
}