--!strict

local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AssetService = game:GetService("AssetService")
local GeometryService = game:GetService("GeometryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bolt = require(ReplicatedStorage:WaitForChild("bolt")) :: any
local collision_geometry = require(ReplicatedStorage:WaitForChild("BoltMesh"):WaitForChild("collision_geometry")) :: any
local CollisionParser = require(ReplicatedStorage:WaitForChild("BoltMesh"):WaitForChild("CollisionParser")) :: any

local TOLERANCE = 1e-4

-- the fidelity goes in at creation: it cannot be changed once a part carries mesh geometry here, and CreateMeshPartAsync turns Box into Hull

-- a 2 x 2 x 2 cube with outward-facing triangles
local function create_cube_mesh_part(fidelity: Enum.CollisionFidelity?): MeshPart
	local mesh = AssetService:CreateEditableMesh()
	local corners = {}
	for index, corner in
		{
			Vector3.new(-1, -1, -1),
			Vector3.new(1, -1, -1),
			Vector3.new(1, 1, -1),
			Vector3.new(-1, 1, -1),
			Vector3.new(-1, -1, 1),
			Vector3.new(1, -1, 1),
			Vector3.new(1, 1, 1),
			Vector3.new(-1, 1, 1),
		}
	do
		corners[index] = mesh:AddVertex(corner)
	end

	for _, face in
		{
			{ 1, 3, 2 },
			{ 1, 4, 3 },
			{ 5, 6, 7 },
			{ 5, 7, 8 },
			{ 1, 2, 6 },
			{ 1, 6, 5 },
			{ 2, 3, 7 },
			{ 2, 7, 6 },
			{ 3, 4, 8 },
			{ 3, 8, 7 },
			{ 4, 1, 5 },
			{ 4, 5, 8 },
		}
	do
		mesh:AddTriangle(corners[face[1]], corners[face[2]], corners[face[3]])
	end

	return AssetService:CreateMeshPartAsync(Content.fromObject(mesh), { CollisionFidelity = fidelity })
end

-- an L-shaped prism (concave), footprint in XY extruded one unit along Z, built off its origin so its bounds are not centred on the part's CFrame
local function create_l_mesh_part(fidelity: Enum.CollisionFidelity?): MeshPart
	local mesh = AssetService:CreateEditableMesh()
	local outline = { { 0, 0 }, { 2, 0 }, { 2, 1 }, { 1, 1 }, { 1, 2 }, { 0, 2 }, { 0, 1 } }
	local bottom, top = {}, {}

	for index, point in outline do
		bottom[index] = mesh:AddVertex(Vector3.new(point[1], point[2], 0))
		top[index] = mesh:AddVertex(Vector3.new(point[1], point[2], 1))
	end

	for _, triangle in { { 1, 2, 3 }, { 1, 3, 4 }, { 1, 4, 7 }, { 7, 4, 5 }, { 7, 5, 6 } } do
		mesh:AddTriangle(top[triangle[1]], top[triangle[2]], top[triangle[3]])
		mesh:AddTriangle(bottom[triangle[1]], bottom[triangle[3]], bottom[triangle[2]])
	end

	for index = 1, #outline do
		local next_index = index % #outline + 1
		mesh:AddTriangle(bottom[index], bottom[next_index], top[next_index])
		mesh:AddTriangle(bottom[index], top[next_index], top[index])
	end

	return AssetService:CreateMeshPartAsync(Content.fromObject(mesh), { CollisionFidelity = fidelity })
end

-- a base slab with a tower on it, as a real union
local function create_union(): UnionOperation
	local base = Instance.new("Part")
	base.Size = Vector3.new(4, 1, 4)
	base.CFrame = CFrame.new(0, 0, 0)

	local tower = Instance.new("Part")
	tower.Size = Vector3.new(1, 4, 1)
	tower.CFrame = CFrame.new(0, 2, 0)

	local union = GeometryService:UnionAsync(base, { tower }, {
		CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition,
		SplitApart = false,
	})[1]

	base:Destroy()
	tower:Destroy()

	return union :: UnionOperation
end

local function block_bounds(cframe: CFrame, size: Vector3): (Vector3, Vector3)
	local half = size / 2
	local min, max = Vector3.one * math.huge, Vector3.one * -math.huge

	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = cframe * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
				min = min:Min(corner)
				max = max:Max(corner)
			end
		end
	end

	return min, max
end

local function expect_near(actual: Vector3, expected: Vector3, tolerance: number)
	expect((actual - expected).Magnitude).toBeLessThanOrEqual(tolerance)
end

local function expect_bounds(cframe: CFrame, mesh: any, expected_min: Vector3, expected_max: Vector3, tolerance: number)
	local min, max = bolt.shape_aabb(cframe, mesh)
	expect_near(min, expected_min, tolerance)
	expect_near(max, expected_max, tolerance)
end

local function expect_same_data(actual: any, expected: any)
	expect(actual.size).toBe(expected.size)
	expect(#actual.hulls).toBe(#expected.hulls)

	for index, hull in expected.hulls do
		local other = actual.hulls[index]
		expect(other.offset).toBe(hull.offset)
		expect(#other.vertices).toBe(#hull.vertices)

		for vertex_index, vertex in hull.vertices do
			expect(other.vertices[vertex_index]).toBe(vertex)
		end

		expect(#other.triangles).toBe(#hull.triangles)

		for triangle_index, vertex in hull.triangles do
			expect(other.triangles[triangle_index]).toBe(vertex)
		end
	end
end

-- the support function hill climbs the adjacency graph, so the graph has to lead from any vertex to the true support point in every direction
local function expect_climbable(hull: any)
	local vertices, adjacency = hull.vertices, hull.adjacency

	expect(#adjacency).toBe(#vertices)
	for index, neighbours in adjacency do
		-- every stored vertex sits on a triangle, so it has that triangle's two other corners at least
		expect(#neighbours).toBeGreaterThanOrEqual(2)

		for _, neighbour in neighbours do
			expect(table.find(adjacency[neighbour], index) ~= nil).toBe(true)
		end
	end

	local random = Random.new(11)
	for _ = 1, 50 do
		local direction = random:NextUnitVector()
		local best = -math.huge

		for _, vertex in vertices do
			best = math.max(best, vertex:Dot(direction))
		end

		local current = 1
		local current_dot = vertices[1]:Dot(direction)
		local improved = true
		while improved do
			improved = false
			for _, neighbour in adjacency[current] do
				local dot = vertices[neighbour]:Dot(direction)
				if dot > current_dot then
					current, current_dot, improved = neighbour, dot, true
					break
				end
			end
		end

		expect(math.abs(current_dot - best)).toBeLessThanOrEqual(1e-5)
	end
end

-- a lumpy sphere with many faces, so a single hull carries a long edgebreaker stream with splits
local function create_lumpy_sphere_mesh_part(rings: number, segments: number, fidelity: Enum.CollisionFidelity?): MeshPart
	local mesh = AssetService:CreateEditableMesh()
	local random = Random.new(5)
	local top = mesh:AddVertex(Vector3.new(0, 1, 0))
	local bottom = mesh:AddVertex(Vector3.new(0, -1, 0))
	local grid = {}
	
	for ring = 1, rings - 1 do
		local phi = math.pi * ring / rings
		grid[ring] = {}
		for segment = 0, segments - 1 do
			local theta = 2 * math.pi * segment / segments
			local radius = 1 + random:NextNumber(-0.05, 0.05)
			grid[ring][segment] = mesh:AddVertex(Vector3.new(
				math.sin(phi) * math.cos(theta) * radius,
				math.cos(phi) * radius,
				math.sin(phi) * math.sin(theta) * radius
			))
		end
	end

	for segment = 0, segments - 1 do
		local next_segment = (segment + 1) % segments

		mesh:AddTriangle(top, grid[1][next_segment], grid[1][segment])
		mesh:AddTriangle(bottom, grid[rings - 1][segment], grid[rings - 1][next_segment])

		for ring = 1, rings - 2 do
			local a, b = grid[ring][segment], grid[ring][next_segment]
			local c, d = grid[ring + 1][segment], grid[ring + 1][next_segment]
			mesh:AddTriangle(a, b, d)
			mesh:AddTriangle(a, d, c)
		end
	end

	return AssetService:CreateMeshPartAsync(Content.fromObject(mesh), { CollisionFidelity = fidelity })
end

-- a decoded hull has to be a closed convex surface: every edge shared by exactly two triangles,
-- Euler's formula holding, and no vertex on the far side of any face's plane
local function expect_closed_convex(hull: any)
	local vertices, triangles = hull.vertices, hull.triangles
	local edge_uses: { [number]: number } = {}

	local extent = 0
	for _, vertex in vertices do
		extent = math.max(extent, vertex.Magnitude)
	end

	local tolerance = 1e-3 * extent
	for triangle = 0, #triangles // 3 - 1 do
		local a, b, c = triangles[triangle * 3 + 1], triangles[triangle * 3 + 2], triangles[triangle * 3 + 3]

		for _, pair in { { a, b }, { b, c }, { c, a } } do
			local lo, hi = math.min(pair[1], pair[2]), math.max(pair[1], pair[2])
			local key = lo * 65536 + hi
			edge_uses[key] = (edge_uses[key] or 0) + 1
		end

		local va, vb, vc = vertices[a], vertices[b], vertices[c]
		local normal = (vb - va):Cross(vc - va)
		if normal.Magnitude > 1e-9 then
			normal = normal.Unit
			local lowest, highest = math.huge, -math.huge
			for _, vertex in vertices do
				local side = (vertex - va):Dot(normal)
				lowest, highest = math.min(lowest, side), math.max(highest, side)
			end
			-- every other vertex sits on one side of the face plane
			expect(math.min(-lowest, highest)).toBeLessThanOrEqual(tolerance)
		end
	end

	local edge_count = 0
	for _, uses in edge_uses do
		expect(uses).toBe(2)
		edge_count += 1
	end
	expect(#vertices - edge_count + #triangles // 3).toBe(2)
end

-- the engine's own raycasts against the part, compared with bolt's against the exported mesh,
-- from random directions all around it, the two must match whether and where they hit
local function expect_raycasts_agree(label: string, part: BasePart, mesh: any, count: number)
	local cframe = part.CFrame
	local reach = part.ExtentsSize.Magnitude * 1.5
	local centre = part.ExtentsCFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { part }

	local random = Random.new(23)
	local hits, engine_only, bolt_only, far = 0, 0, 0, 0
	local examples: { string } = {}

	for _ = 1, count do
		local direction = random:NextUnitVector()
		-- aimed near the centre but not at it, so rays graze edges and corners as well as faces
		local target = centre + random:NextUnitVector() * (reach * 0.3)
		local origin = target + direction * reach
		local ray = (target - origin) * 2

		local engine = workspace:Raycast(origin, ray, params)
		local point = bolt.dispatch.gjk.raycast(origin, ray, cframe, mesh, 1e-5)
		local engine_distance = if engine then (engine.Position - origin).Magnitude else nil
		local bolt_distance = if point then ((point :: Vector3) - origin).Magnitude else nil
		local bad = false

		if engine_distance == nil and bolt_distance ~= nil then
			bolt_only += 1
			bad = true
		elseif engine_distance ~= nil and bolt_distance == nil then
			engine_only += 1
			bad = true
		elseif engine_distance ~= nil and bolt_distance ~= nil then
			hits += 1
			if math.abs(engine_distance - bolt_distance) > 0.02 then
				far += 1
				bad = true
			end
		end

		if bad and #examples < 5 then
			table.insert(examples, `engine={engine_distance} bolt={bolt_distance}`)
		end
	end

	local summary = `{label}: engine hit {hits + engine_only}, bolt hit {hits + bolt_only}, {hits} agreeing, {engine_only} engine-only, {bolt_only} bolt-only, {far} too far apart of {count}; {table.concat(examples, " | ")}`
	-- a ray grazing an edge can hit on one side and miss on the other over float differences,
	-- so a few hit-or-miss flips are allowed; where both hit, the distances have to agree
	if far > 0 or engine_only + bolt_only > count // 100 then
		error(summary, 0)
	end

	if hits < count // 5 then
		error(`{summary} (too few agreeing hits)`, 0)
	end

	return summary
end

local function probe_hits(cframe: CFrame, mesh: any, local_point: Vector3): boolean
	return bolt.dispatch.gjk.intersects(cframe, mesh, cframe * CFrame.new(local_point), bolt.create_sphere(0.05), 1e-5)
end

describe("collision extraction", function()
	it("exports a cube MeshPart as one box hull at the part's size", function()
		local part = create_cube_mesh_part(Enum.CollisionFidelity.Hull)
		local cframe = CFrame.new(10, 5, -3) * CFrame.Angles(0.2, math.rad(30), 0.1)
		local size = Vector3.new(4, 2, 2)
		part.CFrame = cframe
		part.Size = size

		local extraction = collision_geometry.extract(part)
		local mesh_size = part.MeshSize
		part:Destroy()

		expect(extraction.fidelity).toBe(Enum.CollisionFidelity.Hull)
		expect(extraction.skipped_hulls).toBe(0)
		local data = extraction.data
		-- the hulls are expressed at the mesh's own size, create_mesh scales them to the part's
		expect_near(data.size, mesh_size, 1e-5)
		expect(#data.hulls).toBe(1)

		local hull = data.hulls[1]
		expect(#hull.vertices).toBe(8)
		expect(#hull.triangles).toBe(36)
		expect_near(hull.offset, Vector3.zero, TOLERANCE)

		local mesh = bolt.create_mesh(CollisionParser.unpack(CollisionParser.pack(data)), size)
		local expected_min, expected_max = block_bounds(cframe, size)
		expect_bounds(cframe, mesh, expected_min, expected_max, 1e-3)

		local hit = bolt.dispatch.gjk.raycast(cframe * Vector3.new(0, 10, 0), cframe.UpVector * -20, cframe, mesh, 1e-4)
		expect_near(hit, cframe * Vector3.new(0, 1, 0), 1e-3)
	end)

	it("scales with the part like the engine does", function()
		local part = create_cube_mesh_part(Enum.CollisionFidelity.Hull)
		part.Size = Vector3.new(2, 2, 2)

		local data = collision_geometry.extract(part).data
		part:Destroy()

		local cframe = CFrame.new(1, 2, 3) * CFrame.Angles(0, 0.7, 0)
		local stretched = Vector3.new(8, 4, 2)
		local mesh = bolt.create_mesh(data, stretched)
		local expected_min, expected_max = block_bounds(cframe, stretched)
		expect_bounds(cframe, mesh, expected_min, expected_max, 1e-3)

		local shrunk = Vector3.new(1, 1, 1)
		bolt.resize_mesh(mesh, shrunk)
		expected_min, expected_max = block_bounds(cframe, shrunk)
		expect_bounds(cframe, mesh, expected_min, expected_max, 1e-3)
	end)

	it("decomposes a concave mesh into hulls that keep its notch open", function()
		local part = create_l_mesh_part(Enum.CollisionFidelity.PreciseConvexDecomposition)
		local cframe = CFrame.new(3, 1, 3) * CFrame.Angles(0, 0.4, 0)
		part.CFrame = cframe

		local extraction = collision_geometry.extract(part)
		local size = part.Size
		part:Destroy()

		local data = extraction.data
		expect(#data.hulls).toBeGreaterThan(1)
		local decoded = CollisionParser.unpack(CollisionParser.pack(data))
		for _, hull in decoded.hulls do
			expect_climbable(hull)
		end

		local mesh = bolt.create_mesh(decoded, size)
		-- a mesh built off its origin keeps its geometry there
		local expected_min, expected_max = block_bounds(cframe * CFrame.new(1, 1, 0.5), Vector3.new(2, 2, 1))
		expect_bounds(cframe, mesh, expected_min, expected_max, 0.05)

		expect(probe_hits(cframe, mesh, Vector3.new(0.5, 0.5, 0.5))).toBe(true)
		expect(probe_hits(cframe, mesh, Vector3.new(1.5, 0.5, 0.5))).toBe(true)
		expect(probe_hits(cframe, mesh, Vector3.new(0.5, 1.5, 0.5))).toBe(true)
		expect(probe_hits(cframe, mesh, Vector3.new(1.5, 1.5, 0.5))).toBe(false)
	end)

	it("fills the notch at hull fidelity", function()
		local part = create_l_mesh_part(Enum.CollisionFidelity.Hull)
		local cframe = CFrame.new(3, 1, 3)
		part.CFrame = cframe

		local data = collision_geometry.extract(part).data
		local size = part.Size
		part:Destroy()

		expect(#data.hulls).toBe(1)
		local mesh = bolt.create_mesh(CollisionParser.unpack(CollisionParser.pack(data)), size)
		expect(probe_hits(cframe, mesh, Vector3.new(1.5, 1.5, 0.5))).toBe(true)
	end)

	it("exports the extents as one hull at box fidelity without the engine", function()
		-- a bare MeshPart is the only part that takes Box here (see the helpers)
		local part = Instance.new("MeshPart")
		part.CollisionFidelity = Enum.CollisionFidelity.Box
		local cframe = CFrame.new(-4, 2, 6) * CFrame.Angles(0.3, 0.2, 0.1)
		local size = Vector3.new(2, 2, 1)
		part.CFrame = cframe
		part.Size = size

		local extraction = collision_geometry.extract(part)
		part:Destroy()

		expect(extraction.fidelity).toBe(Enum.CollisionFidelity.Box)
		local data = extraction.data
		expect(#data.hulls).toBe(1)
		expect(#data.hulls[1].vertices).toBe(8)

		local mesh = bolt.create_mesh(CollisionParser.unpack(CollisionParser.pack(data)), size)
		local expected_min, expected_max = block_bounds(cframe, size)
		expect_bounds(cframe, mesh, expected_min, expected_max, 1e-3)
		expect(probe_hits(cframe, mesh, Vector3.new(0.5, 0.5, 0.25))).toBe(true)
	end)

	it("exports a union like a MeshPart", function()
		local union = create_union()
		local cframe = CFrame.new(5, 0, -2) * CFrame.Angles(0, 0.3, 0)
		union.CFrame = cframe
	
		expect(union.CollisionFidelity).toBe(Enum.CollisionFidelity.PreciseConvexDecomposition)
		local extraction = collision_geometry.extract(union)
		expect(extraction.fidelity).toBe(Enum.CollisionFidelity.PreciseConvexDecomposition)
		local size = union.Size
		union:Destroy()

		local data = extraction.data
		expect(#data.hulls).toBeGreaterThanOrEqual(2)
		local decoded = CollisionParser.unpack(CollisionParser.pack(data))
		for _, hull in decoded.hulls do
			expect_climbable(hull)
		end

		local mesh = bolt.create_mesh(decoded, size)
		expect_near(size, Vector3.new(4, 4.5, 4), 1e-3)
		local expected_min, expected_max = block_bounds(cframe * CFrame.new(0, 1.75, 0), size)
		expect_bounds(cframe, mesh, expected_min, expected_max, 0.05)

		-- inside the slab, inside the tower, in the air beside the tower
		expect(probe_hits(cframe, mesh, Vector3.new(1.5, 0, 1.5))).toBe(true)
		expect(probe_hits(cframe, mesh, Vector3.new(0, 3.5, 0))).toBe(true)
		expect(probe_hits(cframe, mesh, Vector3.new(1.5, 2, 1.5))).toBe(false)
	end)

	it("rejects an Instance that is not a MeshPart or Union", function()
		local part = Instance.new("Part")
		expect(function()
			collision_geometry.extract(part)
		end).toThrow("MeshPart")
		part:Destroy()
	end)
end)

describe("collision parser storage", function()
	local function random_hull_data(vertex_count: number): any
		local random = Random.new(3)
		local vertices = table.create(vertex_count)

		for index = 1, vertex_count do
			vertices[index] = Vector3.new(random:NextNumber(-5, 5), random:NextNumber(-5, 5), random:NextNumber(-5, 5))
		end

		return {
			size = Vector3.new(3, 4, 5),
			hulls = {
				{ offset = Vector3.new(1, -2, 0.5), vertices = vertices, triangles = { 1, 2, 3, 2, 3, 4, 1, 3, 4, 1, 2, 4 } },
				{
					offset = Vector3.zero,
					vertices = { Vector3.new(0, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1) },
					triangles = { 1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 4, 3 },
				},
			},
		}
	end

	it("writes chunked StringValues and reads the same data back", function()
		-- random vertices do not compress, so this spans several chunks
		local data = random_hull_data(20_000)
		local parent = Instance.new("Folder")
		local folder = CollisionParser.write(parent, "Example", data)

		expect(folder.Parent).toBe(parent)
		expect(folder:GetAttribute("Format")).toBe("BoltHulls")
		expect(folder:GetAttribute("ChunkCount")).toBeGreaterThan(1)

		local chunks = folder:GetChildren()
		expect(#chunks).toBe(folder:GetAttribute("ChunkCount"))
		for _, chunk in chunks do
			expect(chunk:IsA("StringValue")).toBe(true)
			expect(#(chunk :: StringValue).Value).toBeLessThanOrEqual(100_000)
		end

		local decoded = CollisionParser.read(folder)
		expect_same_data(decoded, data)
		-- the tetrahedron's every vertex touches every other
		for _, neighbours in decoded.hulls[2].adjacency do
			expect(#neighbours).toBe(3)
		end

		-- a second export of the same name replaces the first
		local replacement = CollisionParser.write(parent, "Example", random_hull_data(4))
		expect(folder.Parent).toBe(nil)
		expect(#parent:GetChildren()).toBe(1)
		expect(#CollisionParser.read(replacement).hulls[1].vertices).toBe(4)
		parent:Destroy()
	end)

	it("decodes by name from ReplicatedStorage.Collisions.Hulls", function()
		local collisions = Instance.new("Folder")
		collisions.Name = "Collisions"

		local hulls = Instance.new("Folder")
		hulls.Name = "Hulls"
		hulls.Parent = collisions
		collisions.Parent = ReplicatedStorage

		local data = random_hull_data(10)
		CollisionParser.write(hulls, "Named", data)
		expect_same_data(CollisionParser.decode("Named"), data)
		expect(function()
			CollisionParser.decode("Missing")
		end).toThrow("Missing")

		collisions:Destroy()
	end)

	it("refuses tampered chunks", function()
		local parent = Instance.new("Folder")
		local folder = CollisionParser.write(parent, "Example", random_hull_data(200))
		local chunk = folder:FindFirstChild("000000") :: StringValue
		local value = chunk.Value
		chunk.Value = string.rep("A", 8) .. string.sub(value, 9)
		
		expect(function()
			CollisionParser.read(folder)
		end).toThrow()
		parent:Destroy()
	end)
end)

describe("hull geometry against the engine", function()
	it("decodes closed convex hulls at every fidelity", function()
		for _, fidelity in { Enum.CollisionFidelity.Default, Enum.CollisionFidelity.Hull, Enum.CollisionFidelity.PreciseConvexDecomposition } do
			local part = create_lumpy_sphere_mesh_part(12, 24, fidelity)
			local extraction = collision_geometry.extract(part)
			part:Destroy()

			expect(extraction.fidelity).toBe(fidelity)

			local data = extraction.data
			local decoded = CollisionParser.unpack(CollisionParser.pack(data))
			for _, hull in decoded.hulls do
				expect_closed_convex(hull)
				expect_climbable(hull)
			end
		end

		local l_part = create_l_mesh_part()
		for _, hull in collision_geometry.extract(l_part).data.hulls do
			expect_closed_convex(hull)
		end
		l_part:Destroy()
	end)

	it("raycasts like the engine at Default fidelity", function()
		local cframe = CFrame.new(40, 10, -20) * CFrame.Angles(0.4, 1.1, -0.3)
		-- the same meshes at their own size, scaled uniformly, and scaled per axis: an approximate
		-- decomposition of the scaled geometry doesn't need to equal the scaled decomposition of the mesh
		local cases = {
			{ label = "lumpy sphere unscaled", make = create_lumpy_sphere_mesh_part, size = nil },
			{ label = "lumpy sphere uniform x3", make = create_lumpy_sphere_mesh_part, size = Vector3.new(6, 6, 6) },
			{ label = "lumpy sphere non-uniform", make = create_lumpy_sphere_mesh_part, size = Vector3.new(6, 4, 5) },
			{ label = "L prism unscaled", make = create_l_mesh_part, size = nil },
			{ label = "L prism non-uniform", make = create_l_mesh_part, size = Vector3.new(6, 6, 3) },
			{ label = "union", make = create_union, size = nil },
		}

		local failures: { string } = {}
		for _, case in cases do
			local part = if case.make == create_lumpy_sphere_mesh_part then create_lumpy_sphere_mesh_part(12, 24) else (case.make :: any)()
			if part:IsA("PartOperation") then
				part.CollisionFidelity = Enum.CollisionFidelity.Default
			end

			part.CFrame = cframe
			if case.size ~= nil then
				part.Size = case.size
			end

			part.CanQuery = true
			part.Parent = workspace

			local extraction = collision_geometry.extract(part)
			local data = extraction.data
			local mesh = bolt.create_mesh(CollisionParser.unpack(CollisionParser.pack(data)), part.Size)
			local ok, message = pcall(expect_raycasts_agree, case.label, part, mesh, 300)
			if not ok then
				if type(message) == "table" then
					message = tostring((message :: any).message)
				end
				table.insert(failures, `{tostring(message)} ({#data.hulls} hulls)`)
			end

			part:Destroy()
		end

		if #failures > 0 then
			error("\n" .. table.concat(failures, "\n"), 0)
		end
	end)
end)