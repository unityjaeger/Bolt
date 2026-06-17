--!strict
--!optimize 2

local run_service = game:GetService("RunService")

local bolt = require(game.ReplicatedStorage.bolt)

const PARENT = workspace.Terrain :: Terrain

do
	local existing_immediate = PARENT:FindFirstChild("IMMEDIATE_WIREFRAME")
	if existing_immediate then
		existing_immediate:Destroy()
	end
end

const IMMEDIATE_WIREFRAME = Instance.new("WireframeHandleAdornment")
IMMEDIATE_WIREFRAME.Name = "IMMEDIATE_WIREFRAME"
IMMEDIATE_WIREFRAME.AlwaysOnTop = true
IMMEDIATE_WIREFRAME.Adornee = PARENT
IMMEDIATE_WIREFRAME.Parent = PARENT

const EPSILON = 1e-6

const SPHERE_SEGMENTS = 16
const HEMISPHERE_SEGMENTS = SPHERE_SEGMENTS / 2

const DEBUG_SPHERE_RADIUS = .25
const DEBUG_ARROW_HEIGHT = .4
const DEBUG_ARROW_RADIUS = .2

const CIRCLE_COS = table.create(SPHERE_SEGMENTS) :: {number}
const CIRCLE_SIN = table.create(SPHERE_SEGMENTS) :: {number}

const Y_AXIS = Vector3.yAxis
const X_AXIS = Vector3.xAxis
const Z_AXIS = Vector3.zAxis

const DEFAULT_THEME = {
	intersection = Color3.new(0, 1, 0),
	no_intersection = Color3.new(1, 0, 0),
	passive = Color3.new(0, 0, 1),
	arrow = Color3.new(0, 0, 1),
	contact_point = Color3.new(0, 1, 0),
	ray_hit = Color3.new(0, 1, 0),
	ray_miss = Color3.new(1, 0, 0)
}

const THEMES = {
	default = DEFAULT_THEME
}

local active_theme = THEMES.default

do
	for i = 1, SPHERE_SEGMENTS do
		local t = (i - 1) / SPHERE_SEGMENTS * math.tau

		CIRCLE_COS[i] = math.cos(t)
		CIRCLE_SIN[i] = math.sin(t)
	end
end

const defaults = {
	color = IMMEDIATE_WIREFRAME.Color3,
	transparency = IMMEDIATE_WIREFRAME.Transparency,
	thickness = IMMEDIATE_WIREFRAME.Thickness
}

const current = table.clone(defaults)

const pending: {
	color: Color3?,
	transparency: number?,
	thickness: number?,
} = {
	color = nil,
	transparency = nil,
	thickness = nil,
}

const changed = {
	color = false,
	transparency = false,
	thickness = false,
}

const function next_color(color: Color3)
	pending.color = color
	changed.color = true
end

const function next_transparency(transparency: number)
	pending.transparency = transparency
	changed.transparency = true
end

const function next_thickness(thickness: number)
	pending.thickness = thickness
	changed.thickness = true
end

const function consume_properties(): (boolean, Color3, boolean, number, boolean, number)
	local restore_color = false
	local restore_transparency = false
	local restore_thickness = false

	local old_color = current.color
	local old_transparency = current.transparency
	local old_thickness = current.thickness

	if changed.color then
		local color = pending.color :: Color3
		pending.color = nil
		changed.color = false
		
		if color ~= old_color then
			restore_color = true
			IMMEDIATE_WIREFRAME.Color3 = color
			current.color = color
		end
	end

	if changed.transparency then
		local transparency = pending.transparency :: number
		pending.transparency = nil
		changed.transparency = false

		if transparency ~= old_transparency then
			restore_transparency = true
			IMMEDIATE_WIREFRAME.Transparency = transparency
			current.transparency = transparency
		end
	end

	if changed.thickness then
		local thickness = pending.thickness :: number
		pending.thickness = nil
		changed.thickness = false

		if thickness ~= old_thickness then
			restore_thickness = true
			IMMEDIATE_WIREFRAME.Thickness = thickness
			current.thickness = thickness
		end
	end

	return restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness
end

const function reset_properties(
	restore_color: boolean,
	old_color: Color3,
	restore_transparency: boolean,
	old_transparency: number,
	restore_thickness: boolean,
	old_thickness: number
)
	if restore_color then
		IMMEDIATE_WIREFRAME.Color3 = old_color :: Color3
		current.color = old_color :: Color3
	end

	if restore_transparency then
		IMMEDIATE_WIREFRAME.Transparency = old_transparency
		current.transparency = old_transparency
	end

	if restore_thickness then
		IMMEDIATE_WIREFRAME.Thickness = old_thickness
		current.thickness = old_thickness
	end
end

const function draw_box_internal(cframe: CFrame, shape: bolt.BoxShape)
	local center = cframe.Position
	local right, up, look = cframe.RightVector, cframe.UpVector, cframe.LookVector

	local half = shape.half_extents

	local r = right * half.X
	local u = up * half.Y
	local l = look * half.Z

	--start at one corner
	local vert1 = center + r + u + l

	local rr = r + r
	local uu = u + u
	local ll = l + l

	--walk to adjacent corners by flipping one axis at a time
	local vert2 = vert1 - ll -- +r +u -l
	local vert4 = vert2 - uu -- +r -u -l
	local vert3 = vert4 + ll -- +r -u +l
	local vert7 = vert3 - rr -- -r -u +l
	local vert8 = vert7 - ll -- -r -u -l
	local vert6 = vert8 + uu -- -r +u -l
	local vert5 = vert6 + ll -- -r +u +l

	IMMEDIATE_WIREFRAME:AddPath({
		vert1, vert2, vert4, vert3,
		vert1, vert5, vert6, vert2,
		vert8, vert7, vert5, vert8,
		vert6, vert1, vert4, vert8,
		vert3, vert7
	}, true)
end

const function draw_box(cframe: CFrame, shape: bolt.BoxShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	draw_box_internal(cframe, shape)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const _sphere_points = table.create(SPHERE_SEGMENTS)
const function draw_circle(center: Vector3, u: Vector3, v: Vector3, radius: number)
	for i = 1, SPHERE_SEGMENTS do
		local offset = (u * CIRCLE_COS[i] + v * CIRCLE_SIN[i]) * radius

		_sphere_points[i] = center + offset
	end

	IMMEDIATE_WIREFRAME:AddPath(_sphere_points, true)
end

const function draw_sphere_internal(center: Vector3, radius: number)
	draw_circle(center, X_AXIS, Y_AXIS, radius)
	draw_circle(center, Y_AXIS, Z_AXIS, radius)
	draw_circle(center, X_AXIS, Z_AXIS, radius)
end

const function draw_sphere(center: Vector3, shape: bolt.SphereShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()

	local radius = shape.radius
	draw_sphere_internal(center, radius)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const _cylinder_lines = table.create(SPHERE_SEGMENTS * 2)
const function draw_cylinder_internal(cframe: CFrame, shape: bolt.CylinderShape)
	local center = cframe.Position
	local axis = cframe.RightVector
	local half_height = shape.half_height
	local radius = shape.radius
	
	local start_point = center - axis * half_height
	local end_point = center + axis * half_height
	
	local u = cframe.UpVector
	local v = cframe.LookVector
	
	draw_circle(start_point, u, v, radius)
	draw_circle(end_point, u, v, radius)
	
	local cursor = 1
	
	for i = 1, SPHERE_SEGMENTS do
		local offset = (u * CIRCLE_COS[i] + v * CIRCLE_SIN[i]) * radius
		
		_cylinder_lines[cursor] = start_point + offset
		cursor += 1
		_cylinder_lines[cursor] = end_point + offset
		cursor += 1
	end
	
	IMMEDIATE_WIREFRAME:AddLines(_cylinder_lines)
end

const function draw_cylinder(cframe: CFrame, shape: bolt.CylinderShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	draw_cylinder_internal(cframe, shape)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const _hemisphere_lines = table.create(HEMISPHERE_SEGMENTS * SPHERE_SEGMENTS)
const function draw_hemisphere(center: Vector3, axis: Vector3, u: Vector3, v: Vector3, radius: number)
	local cursor = 1

	for arc = 1, SPHERE_SEGMENTS do
		local side = u * CIRCLE_COS[arc] + v * CIRCLE_SIN[arc]

		local previous = center + side * radius

		for i = 1, HEMISPHERE_SEGMENTS do
			local t = i / HEMISPHERE_SEGMENTS * (math.pi * 0.5)

			local current = center
				+ side * (math.cos(t) * radius)
				+ axis * (math.sin(t) * radius)

			_hemisphere_lines[cursor] = previous
			cursor += 1
			_hemisphere_lines[cursor] = current
			cursor += 1

			previous = current
		end
	end

	IMMEDIATE_WIREFRAME:AddLines(_hemisphere_lines)
end

const function draw_capsule(cframe: CFrame, shape: bolt.CapsuleShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	draw_cylinder_internal(cframe, shape)
	
	local center = cframe.Position
	local axis = cframe.RightVector
	local half_height = shape.half_height
	local radius = shape.radius

	local start_point = center - axis * half_height
	local end_point = center + axis * half_height

	local u = cframe.UpVector
	local v = cframe.LookVector
	
	draw_hemisphere(start_point, -axis, u, v, radius)
	draw_hemisphere(end_point, axis, u, v, radius)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_ellipse(center: Vector3, axis_a: Vector3, axis_b: Vector3)
	local points = table.create(SPHERE_SEGMENTS)

	for i = 1, SPHERE_SEGMENTS do
		points[i] = center
			+ axis_a * CIRCLE_COS[i]
			+ axis_b * CIRCLE_SIN[i]
	end

	IMMEDIATE_WIREFRAME:AddPath(points, true)
end

const function draw_ellipsoid(cframe: CFrame, shape: bolt.EllipsoidShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()

	local center = cframe.Position
	local radii = shape.half_extents

	local x = cframe.RightVector * radii.X
	local y = cframe.UpVector * radii.Y
	local z = cframe.LookVector * radii.Z

	draw_ellipse(center, x, y)
	draw_ellipse(center, y, z)
	draw_ellipse(center, x, z)

	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_wedge(cframe: CFrame, shape: bolt.WedgeShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	local center = cframe.Position
	local right = cframe.RightVector
	local up = cframe.UpVector
	local look = cframe.LookVector

	local half = shape.half_extents

	local r = right * half.X
	local u = up * half.Y
	local l = look * half.Z

	local uu = u + u
	local ll = l + l

	--right-angle corner is at -up, -look
	local m = center - u - l

	local v1 = m - r
	local v4 = m + r

	local v2 = v1 + uu
	local v3 = v1 + ll

	local v5 = v4 + uu
	local v6 = v4 + ll

	IMMEDIATE_WIREFRAME:AddPath({
		v1, v2, v3, v1,
		v4, v5, v2, v6,
		v3, v6, v5, v1,
		v6, v4,
	}, false)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_corner_wedge(cframe: CFrame, shape: bolt.CornerWedgeShape)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	local center = cframe.Position
	local right = cframe.RightVector
	local up = cframe.UpVector
	local look = cframe.LookVector

	local half = shape.half_extents

	local r = right * half.X
	local u = up * half.Y
	local l = look * half.Z

	local v1 = center + r - l - u
	local ll = l + l
	local rr = r + r
	local uu = u + u

	local v2 = v1 + ll -- +r +l -u
	local v3 = v2 + uu -- +r +l +u
	local v4 = v2 - rr -- -r +l -u
	local v5 = v1 - rr -- -r -l -u
	
	IMMEDIATE_WIREFRAME:AddPath({
		v1, v2, v3, v4,
		v5, v1, v3, v5,
		v4, v2, v4, v1,
	}, false)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const _cone_points = table.create(SPHERE_SEGMENTS)
const _cone_lines = table.create(SPHERE_SEGMENTS * 2)
const function draw_cone(base_center: Vector3, tip: Vector3, u: Vector3, v: Vector3, radius: number)
	local cursor = 1
	
	for i = 1, SPHERE_SEGMENTS do
		local offset = (u * CIRCLE_COS[i] + v * CIRCLE_SIN[i]) * radius
		local point = base_center + offset

		_cone_points[i] = point

		_cone_lines[cursor] = point
		cursor += 1
		_cone_lines[cursor] = tip
		cursor += 1
	end

	IMMEDIATE_WIREFRAME:AddPath(_cone_points, true)
	IMMEDIATE_WIREFRAME:AddLines(_cone_lines)
end

const function draw_ray(from: Vector3, to: Vector3)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	IMMEDIATE_WIREFRAME:AddLine(from, to)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function basis_from_axis(axis: Vector3): (Vector3, Vector3)
	local helper = if math.abs(axis.Y) < .99 then Y_AXIS else X_AXIS
	
	local u = vector.normalize(vector.cross(axis :: any, helper :: any))
	local v = vector.normalize(vector.cross(axis :: any, u :: any))

	return u :: any, v :: any
end

const function draw_arrow(from: Vector3, to: Vector3, head_length: number, head_radius: number)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	local delta = to - from
	local length = vector.magnitude(delta :: any)

	if length < EPSILON then
		reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
		return
	end

	local axis = delta / length
	local u, v = basis_from_axis(axis)

	local base_center = to - axis * head_length

	IMMEDIATE_WIREFRAME:AddLine(from, to)

	draw_cone(base_center, to, u, v, head_radius)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_primitive(cframe: CFrame, shape: bolt.Shape)
	if shape.type == 2^0 then
		draw_box(cframe, shape :: bolt.BoxShape)
	elseif shape.type == 2^1 then
		draw_sphere(cframe.Position, shape :: bolt.SphereShape)
	elseif shape.type == 2^2 then
		draw_cylinder(cframe, shape :: bolt.CylinderShape)
	elseif shape.type == 2^3 then
		draw_wedge(cframe, shape :: bolt.WedgeShape)
	elseif shape.type == 2^4 then
		draw_corner_wedge(cframe, shape :: bolt.CornerWedgeShape)
	elseif shape.type == 2^6 then
		draw_capsule(cframe, shape :: bolt.CapsuleShape)
	elseif shape.type == 2^8 then
		draw_ellipsoid(cframe, shape :: bolt.EllipsoidShape)
	else
		error("shape not supported")
	end
end

const function draw_primitive_primitive(cframe_a: CFrame, shape_a: bolt.Shape, cframe_b: CFrame, shape_b: bolt.Shape, hit: boolean)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	if hit then
		next_color(active_theme.intersection)
	else
		next_color(active_theme.no_intersection)
	end
	
	draw_primitive(cframe_a, shape_a)
	
	next_color(active_theme.passive)
	draw_primitive(cframe_b, shape_b)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_raycast_primitive(ray_origin: Vector3, ray_direction: Vector3, cframe: CFrame, shape: bolt.Shape, point: Vector3?, distance: number?, normal: Vector3?)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()

	if not point then
		next_color(active_theme.ray_miss)
		draw_ray(ray_origin, ray_origin + ray_direction)

		next_color(active_theme.passive)
		draw_primitive(cframe, shape)

		reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
		return
	end

	local unit_direction = vector.normalize(ray_direction :: any)

	next_color(active_theme.ray_hit)
	draw_ray(ray_origin, ray_origin + (unit_direction :: any * distance :: number))

	next_color(active_theme.intersection)
	draw_primitive(cframe, shape)

	next_color(active_theme.contact_point)
	draw_sphere_internal(point :: Vector3, DEBUG_SPHERE_RADIUS)

	next_color(active_theme.arrow)
	draw_arrow(point :: Vector3, point :: Vector3 + normal :: Vector3, DEBUG_ARROW_HEIGHT, DEBUG_ARROW_RADIUS)

	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_mpr_intersects(cframe_a: CFrame, shape_a: bolt.Shape, cframe_b: CFrame, shape_b: bolt.Shape, hit: boolean, mtv: Vector3, depth: number?, point_a: Vector3?, point_b: Vector3?)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	if not hit then
		next_color(active_theme.no_intersection)
		draw_primitive(cframe_a, shape_a)
		
		next_color(active_theme.passive)
		draw_primitive(cframe_b, shape_b)
		
		next_color(active_theme.arrow)
		local a_pos = cframe_a.Position
		draw_arrow(a_pos, a_pos + mtv, DEBUG_ARROW_HEIGHT, DEBUG_ARROW_RADIUS)
		
		reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
		return
	end
	
	next_color(active_theme.intersection)
	draw_primitive(cframe_a, shape_a)

	next_color(active_theme.passive)
	draw_primitive(cframe_b, shape_b)
	
	next_color(active_theme.contact_point)
	draw_sphere_internal(point_a :: Vector3, DEBUG_SPHERE_RADIUS)
	next_color(active_theme.contact_point)
	draw_sphere_internal(point_b :: Vector3, DEBUG_SPHERE_RADIUS)	
	
	next_color(active_theme.arrow)
	draw_arrow(point_b :: Vector3, point_b :: Vector3 + (mtv :: Vector3 * depth :: number), DEBUG_ARROW_HEIGHT, DEBUG_ARROW_RADIUS)
	
	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_sat_intersects(cframe_a: CFrame, shape_a: bolt.Shape, cframe_b: CFrame, shape_b: bolt.Shape, hit: boolean, mtv: Vector3?, depth: number?)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()

	if not hit then
		next_color(active_theme.no_intersection)
		draw_primitive(cframe_a, shape_a)

		next_color(active_theme.passive)
		draw_primitive(cframe_b, shape_b)

		reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
		return
	end
	
	local center_a = cframe_a.Position
	
	next_color(active_theme.intersection)
	draw_primitive(cframe_a, shape_a)

	next_color(active_theme.passive)
	draw_primitive(cframe_b, shape_b)	

	next_color(active_theme.arrow)
	draw_arrow(center_a, center_a + (mtv :: Vector3 * depth :: number), DEBUG_ARROW_HEIGHT, DEBUG_ARROW_RADIUS)

	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_gjk_shapecast_simple(cframe_a: CFrame, direction: Vector3, shape_a: bolt.Shape, cframe_b: CFrame, shape_b: bolt.Shape, hit: boolean, distance: number?)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()
	
	local ray_origin = cframe_a.Position
	
	if not hit then
		next_color(active_theme.ray_miss)
		draw_ray(ray_origin, ray_origin + direction)
		
		next_color(active_theme.passive)
		draw_primitive(cframe_a, shape_a)
		
		next_color(active_theme.ray_miss)
		draw_primitive(cframe_a + direction, shape_a)

		next_color(active_theme.passive)
		draw_primitive(cframe_b, shape_b)

		reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
		return
	end
	
	local unit_direction = vector.normalize(direction :: any)
	
	next_color(active_theme.ray_hit)
	draw_ray(ray_origin, ray_origin + (unit_direction :: any * distance :: number))

	next_color(active_theme.passive)
	draw_primitive(cframe_a, shape_a)

	next_color(active_theme.ray_hit)
	draw_primitive(cframe_a + (unit_direction :: any * distance :: number), shape_a)

	next_color(active_theme.passive)
	draw_primitive(cframe_b, shape_b)

	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

const function draw_gjk_shapecast(cframe_a: CFrame, direction: Vector3, shape_a: bolt.Shape, cframe_b: CFrame, shape_b: bolt.Shape, point: Vector3?, distance: number?, normal: Vector3?)
	local restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness = consume_properties()

	local ray_origin = cframe_a.Position

	if not point then
		next_color(active_theme.ray_miss)
		draw_ray(ray_origin, ray_origin + direction)

		next_color(active_theme.passive)
		draw_primitive(cframe_a, shape_a)

		next_color(active_theme.ray_miss)
		draw_primitive(cframe_a + direction, shape_a)

		next_color(active_theme.passive)
		draw_primitive(cframe_b, shape_b)

		reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
		return
	end

	local unit_direction = vector.normalize(direction :: any)

	next_color(active_theme.ray_hit)
	draw_ray(ray_origin, ray_origin + (unit_direction :: any * distance :: number))

	next_color(active_theme.passive)
	draw_primitive(cframe_a, shape_a)

	next_color(active_theme.ray_hit)
	draw_primitive(cframe_a + (unit_direction :: any * distance :: number), shape_a)

	next_color(active_theme.passive)
	draw_primitive(cframe_b, shape_b)
	
	next_color(active_theme.contact_point)
	draw_sphere_internal(point :: Vector3, DEBUG_SPHERE_RADIUS)

	next_color(active_theme.arrow)
	draw_arrow(point :: Vector3, point :: Vector3 + normal :: Vector3, DEBUG_ARROW_HEIGHT, DEBUG_ARROW_RADIUS)

	reset_properties(restore_color, old_color, restore_transparency, old_transparency, restore_thickness, old_thickness)
end

local connection: RBXScriptConnection?
const function init(event: RBXScriptSignal?)
	if connection then
		connection:Disconnect()
		return
	end
	
	event = event or run_service.PreSimulation
	
	connection = event:Connect(function()
		IMMEDIATE_WIREFRAME:Clear()
	end)
end

init()

return {
	init = init,
	
	next_color = next_color,
	next_transparency = next_transparency,
	next_thickness = next_thickness,
	
	components = {
		box = draw_box,
		sphere = draw_sphere,
		cylinder = draw_cylinder,
		capsule = draw_capsule,
		ellipsoid = draw_ellipsoid,
		wedge = draw_wedge,
		corner_wedge = draw_corner_wedge,
		
		ray = draw_ray,
		arrow = draw_arrow
	},
	
	mpr_intersects = draw_mpr_intersects,
	sat_intersects = draw_sat_intersects,
	primitive_primitive = draw_primitive_primitive,
	raycast_primitive = draw_raycast_primitive,
	gjk_shapecast_simple = draw_gjk_shapecast_simple,
	gjk_shapecast = draw_gjk_shapecast
}