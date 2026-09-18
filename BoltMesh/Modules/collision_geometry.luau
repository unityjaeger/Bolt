--!strict

-- a part's collision data is the PhysicalConfigData shared string in its serialization, a CSGPHS blob

-- i could not find any example of a mesh or union that doesn't work with the newest CSGPHS version, so the UnionAsync coercion way of doing things
-- was removed, as it caused differences in collision data from roblox because CSG uses different convex decomposition algorithms for some fidelities

const rbxm = require("./rbxm")
const csgphs = require("./csgphs")

const SerializationService = game:GetService("SerializationService")
const EncodingService = game:GetService("EncodingService")

export type Hull = {
	-- the hull's centre in the part's object space, at the reference size
	offset: Vector3,
	-- about the offset, at the reference size
	vertices: { Vector3 },
	-- three 1-based vertex indices per triangle, flat
	triangles: { number },
}

export type HullData = {
	-- the part size the hulls are expressed at
	size: Vector3,
	hulls: { Hull },
}

export type Extraction = {
	data: HullData,
	fidelity: Enum.CollisionFidelity,
	-- hulls dropped for enclosing nothing (fewer than four vertices or no
	-- triangles), which PreciseConvexDecomposition does emit
	skipped_hulls: number,
}

const function decompress_zstd(frame: buffer): buffer
	return EncodingService:DecompressBuffer(frame, Enum.CompressionAlgorithm.Zstd)
end

const function is_supported(instance: Instance?): boolean
	return instance ~= nil and (instance:IsA("MeshPart") or instance:IsA("PartOperation"))
end

-- the twelve triangles of a box over the corner order used by box_hull
const BOX_TRIANGLES = {
	1, 3, 2, 1, 4, 3,
	5, 6, 7, 5, 7, 8,
	1, 2, 6, 1, 6, 5,
	2, 3, 7, 2, 7, 6,
	3, 4, 8, 3, 8, 7,
	4, 1, 5, 4, 5, 8,
}

const function box_hull(part: BasePart): Hull
	local local_cframe = part.CFrame:ToObjectSpace(part.ExtentsCFrame)
	local half = part.ExtentsSize / 2
	local hx, hy, hz = half.X, half.Y, half.Z
	local corners = {
		Vector3.new(-hx, -hy, -hz),
		Vector3.new(hx, -hy, -hz),
		Vector3.new(hx, hy, -hz),
		Vector3.new(-hx, hy, -hz),
		Vector3.new(-hx, -hy, hz),
		Vector3.new(hx, -hy, hz),
		Vector3.new(hx, hy, hz),
		Vector3.new(-hx, hy, hz),
	}

	local vertices = table.create(8) :: {Vector3}
	for index, corner in corners do
		vertices[index] = local_cframe.Rotation * corner
	end

	return {
		offset = local_cframe.Position,
		vertices = vertices,
		triangles = table.clone(BOX_TRIANGLES),
	}
end

const function convert_hull(hull: csgphs.CollisionHull): Hull?
	local unique: { Vector3 } = {}
	local remap = table.create(hull.vertex_count)

	local index_by_key: { [string]: number } = {}
	for index = 0, hull.vertex_count - 1 do
		local x = buffer.readf32(hull.positions, index * 12)
		local y = buffer.readf32(hull.positions, index * 12 + 4)
		local z = buffer.readf32(hull.positions, index * 12 + 8)
		local key = `{x},{y},{z}`
		local unique_index = index_by_key[key]

		if unique_index == nil then
			table.insert(unique, Vector3.new(x, y, z))
			unique_index = #unique
			index_by_key[key] = unique_index
		end

		remap[index + 1] = unique_index
	end

	local triangles: { number } = {}
	for triangle = 0, hull.triangle_count - 1 do
		local a = remap[buffer.readu32(hull.indices, triangle * 12) + 1]
		local b = remap[buffer.readu32(hull.indices, triangle * 12 + 4) + 1]
		local c = remap[buffer.readu32(hull.indices, triangle * 12 + 8) + 1]
		-- welding can collapse a triangle to an edge or a point
		if a ~= b and b ~= c and a ~= c then
			table.insert(triangles, a)
			table.insert(triangles, b)
			table.insert(triangles, c)
		end
	end

	-- a vertex no surviving triangle touches would be unreachable from the
	-- graph, and the support function could never climb to it
	local used = table.create(#unique)
	local kept: { Vector3 } = {}
	for _, index in triangles do
		if used[index] == nil then
			table.insert(kept, unique[index])
			used[index] = #kept
		end
	end

	for index, vertex in triangles do
		triangles[index] = used[vertex]
	end

	if #kept < 4 or #triangles == 0 then
		return nil
	end

	local min, max = kept[1], kept[1]
	for _, vertex in kept do
		min = min:Min(vertex)
		max = max:Max(vertex)
	end

	local offset = (min + max) / 2
	local vertices = table.create(#kept) :: {Vector3}
	for index, vertex in kept do
		vertices[index] = vertex - offset
	end

	return {
		offset = offset,
		vertices = vertices,
		triangles = triangles,
	}
end

-- the collision blob a part carries in its serialization, nil when it holds none,
-- the vertices are at the MeshSize, which a union has too, its blob stays at the size
-- it was built at through resizes
const function serialized_geometry(part: BasePart): (csgphs.CollisionGeometry?, Vector3)
	local reference_size: Vector3 = (part :: any).MeshSize
	local model = rbxm.read_model(SerializationService:SerializeInstancesAsync({ part }), decompress_zstd)

	for _, class in model.classes do
		local indices = class.shared_string_indices.PhysicalConfigData
		if indices == nil then
			continue
		end

		for _, index in indices do
			local shared_string = model.shared_strings[index]
			if shared_string ~= nil and csgphs.is_collision_blob(shared_string) then
				return csgphs.parse(shared_string, decompress_zstd), reference_size
			end
		end
	end

	return nil, reference_size
end

-- a "block" geometry is the engine writing the part off as its bounding box, which the extents
-- already describe, anything else is converted hull by hull
const function hulls_of(part: BasePart, geometry: csgphs.CollisionGeometry): ({ Hull }, number)
	local hulls: { Hull } = {}
	local skipped_hulls = 0

	if geometry.kind == "block" then
		table.insert(hulls, box_hull(part))
	else
		for _, hull in geometry.hulls do
			local converted = convert_hull(hull)
			if converted == nil then
				skipped_hulls += 1
			else
				table.insert(hulls, converted)
			end
		end
	end

	return hulls, skipped_hulls
end

-- the part's collision geometry read straight out of its serialization
const function extract(part: BasePart): Extraction
	assert(is_supported(part), "collision extraction takes MeshParts and unions")
	local fidelity: Enum.CollisionFidelity = (part :: any).CollisionFidelity

	if fidelity == Enum.CollisionFidelity.Box then
		return {
			data = { size = part.Size, hulls = { box_hull(part) } },
			fidelity = fidelity,
			skipped_hulls = 0,
		}
	end

	local geometry, reference_size = serialized_geometry(part)
	assert(geometry ~= nil, `{part:GetFullName()}: the serialized part carries no collision geometry`)
	local hulls, skipped_hulls = hulls_of(part, geometry :: csgphs.CollisionGeometry)
	assert(#hulls > 0, `{part:GetFullName()}: the collision geometry holds no usable hull`)

	return {
		data = { size = reference_size, hulls = hulls },
		fidelity = fidelity,
		skipped_hulls = skipped_hulls,
	}
end

return {
	extract = extract,
	is_supported = is_supported,
}