--!strict

local EPSILON = 1e-4
local DELTA = 1e-3

local function assert_miss(t: any, point: Vector3?, distance: number?, normal: Vector3?, message: string?)
	t.is_nil(point, message)
	t.is_nil(distance, message)
	t.is_nil(normal, message)
end

local function assert_start_hit(t: any, point: Vector3?, distance: number?, normal: Vector3?, origin: Vector3)
	t.vector_near(t.non_nil(point), origin)
	t.near(t.non_nil(distance), 0)
	t.vector_near(t.non_nil(normal), Vector3.zero)
end

local function assert_cast_hit(
	t: any,
	point: Vector3?,
	distance: number?,
	normal: Vector3?,
	origin: Vector3,
	direction: Vector3,
	expected_distance: number?
)
	local hit_point = t.non_nil(point)
	local hit_distance = t.non_nil(distance)
	local hit_normal = t.non_nil(normal)

	t.vector_finite(hit_point)
	t.finite(hit_distance)
	t.vector_finite(hit_normal)
	t.truthy(hit_distance >= -EPSILON)
	t.truthy(hit_distance <= direction.Magnitude + EPSILON)

	if expected_distance ~= nil then
		t.near(hit_distance, expected_distance, EPSILON)
	end

	if direction.Magnitude > 0 then
		local expected_point = origin + direction * (hit_distance / direction.Magnitude)
		t.vector_near(hit_point, expected_point, EPSILON)
	end
end

local function assert_unit_vector(t: any, value: Vector3, epsilon: number?)
	t.vector_finite(value)
	t.near(value.Magnitude, 1, epsilon or EPSILON)
end

local function random_cframe(random: Random, position_range: number): CFrame
	local p = Vector3.new(
		random:NextNumber(-position_range, position_range),
		random:NextNumber(-position_range, position_range),
		random:NextNumber(-position_range, position_range)
	)
	return CFrame.new(p) * CFrame.fromOrientation(
		random:NextNumber(-math.pi, math.pi),
		random:NextNumber(-math.pi, math.pi),
		random:NextNumber(-math.pi, math.pi)
	)
end

local function make_box_hull(offset: Vector3, half_extents: Vector3): any
	local hx, hy, hz = half_extents.X, half_extents.Y, half_extents.Z
	local vertices = {
		Vector3.new(-hx, -hy, -hz),
		Vector3.new(-hx, -hy, hz),
		Vector3.new(-hx, hy, -hz),
		Vector3.new(-hx, hy, hz),
		Vector3.new(hx, -hy, -hz),
		Vector3.new(hx, -hy, hz),
		Vector3.new(hx, hy, -hz),
		Vector3.new(hx, hy, hz),
	}

	--complete adjacency is intentionally simple and guarantees that the hill-climbing support function can reach the global support vertex
	local adjacency = table.create(#vertices)
	for i = 1, #vertices do
		local neighbors = {}
		for j = 1, #vertices do
			if i ~= j then
				table.insert(neighbors, j)
			end
		end
		adjacency[i] = neighbors
	end

	return {
		offset = offset,
		vertices = vertices,
		adjacency = adjacency,
	}
end

local function make_two_hull_mesh(bolt: any, size: Vector3?): any
	local original_size = Vector3.new(6, 2, 2)
	local mesh_info = {
		size = original_size,
		hulls = {
			make_box_hull(Vector3.new(-2, 0, 0), Vector3.new(0.5, 0.5, 0.5)),
			make_box_hull(Vector3.new(2, 0, 0), Vector3.new(0.5, 0.5, 0.5)),
		},
	}

	return bolt.create_mesh(mesh_info, size or original_size)
end

local function pair_key(a: number, b: number): string
	return `{a}:{b}`
end

return {
	EPSILON = EPSILON,
	DELTA = DELTA,
	assert_miss = assert_miss,
	assert_start_hit = assert_start_hit,
	assert_cast_hit = assert_cast_hit,
	assert_unit_vector = assert_unit_vector,
	random_cframe = random_cframe,
	make_box_hull = make_box_hull,
	make_two_hull_mesh = make_two_hull_mesh,
	pair_key = pair_key,
}