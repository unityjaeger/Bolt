--!strict
--!native
--!optimize 2

local types = require("./types")
local constants = require("./constants")

local FLT_EPSILON = constants.FLT_EPSILON
local HUGE_VECTOR = Vector3.one * constants.HUGE

local V_ZERO = Vector3.zero
local V_ONE = Vector3.one

local V_X = Vector3.xAxis
local V_Y = Vector3.yAxis
local V_Z = Vector3.zAxis

local function box(shape: types.BoxShape, direction: Vector3): Vector3
	local half_extents = shape.half_extents

	return Vector3.new(
		direction.X >= 0 and half_extents.X or -half_extents.X,
		direction.Y >= 0 and half_extents.Y or -half_extents.Y,
		direction.Z >= 0 and half_extents.Z or -half_extents.Z
	)
end

local function sphere(shape: types.SphereShape, direction: Vector3): Vector3
	local len = vector.magnitude(direction :: any)
	if len > FLT_EPSILON then
		return (direction / len) * shape.radius
	end
	return Vector3.new(0, shape.radius, 0)
end

local function capsule(shape: types.CapsuleShape, direction: Vector3): Vector3
	local half_height = shape.half_height

	local proj = vector.dot(direction :: any, V_X :: any)
	local pole_offset = (proj >= 0 and half_height or -half_height) * V_X
	
	local mag = vector.magnitude(direction :: any)
	if mag < FLT_EPSILON then
		return pole_offset
	end
	
	return pole_offset + shape.radius * direction / mag
end

local function cylinder(shape: types.CylinderShape, direction: Vector3): Vector3
	local half_height = shape.half_height
	local radius = shape.radius

	local dx, dy, dz = direction.X, direction.Y, direction.Z

	local len = (dy * dy + dz * dz)^.5

	if len > FLT_EPSILON then
		local scale = radius / len
		dy *= scale
		dz *= scale
	end

	local pole_x = dx >= 0 and half_height or -half_height
	return Vector3.new(pole_x, dy, dz)
end

local function wedge(shape: types.WedgeShape, direction: Vector3): Vector3
	local verts = shape.vertices

	local best_idx = 1
	local best_dot = vector.dot(verts[1] :: any, direction :: any)
	for i = 2, 3 do
		local d = vector.dot(verts[i] :: any, direction :: any)
		if d > best_dot then
			best_dot = d
			best_idx = i
		end
	end

	local best = verts[best_idx]
	if direction.X < 0 then
		best = Vector3.new(-best.X, best.Y, best.Z)
	end

	return best
end

local function corner_wedge(shape: types.CornerWedgeShape, direction: Vector3): Vector3
	local verts = shape.vertices

	local best_idx = 1
	local best_dot = vector.dot(verts[1] :: any, direction :: any)

	for i = 2, 5 do
		local d = vector.dot(verts[i] :: any, direction :: any)
		if d > best_dot then
			best_dot = d
			best_idx = i
		end
	end

	return verts[best_idx]
end

local function mesh(shape: types.MeshShape, direction: Vector3): Vector3
	local part = shape.part
	return part.CFrame:PointToObjectSpace(
		part:GetClosestPointOnSurface(direction * HUGE_VECTOR)
	)
end

return {
	box = box,
	sphere = sphere,
	cylinder = cylinder,
	wedge = wedge,
	corner_wedge = corner_wedge,
	mesh = mesh,
	capsule = capsule,
}