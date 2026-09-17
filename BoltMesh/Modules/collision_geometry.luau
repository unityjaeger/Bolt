--!strict

const rbxm = require("./rbxm")
const csgphs = require("./csgphs")

const GeometryService = game:GetService("GeometryService")
const SerializationService = game:GetService("SerializationService")
const EncodingService = game:GetService("EncodingService")
const ContentProvider = game:GetService("ContentProvider")

const COPY_NAME = "bolt_collision_copy"

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

const function extract_geometry(part: BasePart, fidelity: Enum.CollisionFidelity): (csgphs.CollisionGeometry, Vector3)
	local copy: BasePart? = nil
	local function union()
		local results = GeometryService:UnionAsync(part, {}, {
			CollisionFidelity = fidelity,
			SplitApart = false,
		})
		local result = results[1] :: BasePart
		assert(typeof(result) == "Instance" and result:IsA("BasePart"), "UnionAsync returned no part")
		result.Name = COPY_NAME
		copy = result
	end
	
	local ok, err = pcall(union)
	if not ok then
		pcall(function()
			ContentProvider:PreloadAsync({ part })
		end)
		ok, err = pcall(union)
	end

	if not ok then
		error(`{part:GetFullName()}: {tostring(err)}`, 0)
	end

	local copy_part = copy :: BasePart

	local read_ok, result, reference_size = pcall(function(): (csgphs.CollisionGeometry, Vector3)
		local offset = part.CFrame:ToObjectSpace(copy_part.CFrame)
		local size = part.Size
		local tolerance = 1e-3 * math.max(1, size.X, size.Y, size.Z)
		assert(
			offset.Position.Magnitude <= tolerance
			and (offset.RightVector - Vector3.xAxis).Magnitude <= 1e-3
			and (offset.UpVector - Vector3.yAxis).Magnitude <= 1e-3,
			"UnionAsync moved the part's geometry relative to its CFrame, collision extraction does not handle that"
		)
		-- the size the hull vertices are expressed at: the copy carries the part's size as its own MeshSize
		local reference_size = if copy_part:IsA("MeshPart") then copy_part.MeshSize else copy_part.Size

		local model = rbxm.read_model(SerializationService:SerializeInstancesAsync({ copy_part }), decompress_zstd)
		local blob: buffer? = nil
		for _, class in model.classes do
			local names = class.strings.Name
			local indices = class.shared_string_indices.PhysicalConfigData
			if names == nil or indices == nil then
				continue
			end
			for position, name in names do
				local shared_string = model.shared_strings[indices[position]]
				if name == COPY_NAME and shared_string ~= nil and csgphs.is_collision_blob(shared_string) then
					blob = shared_string
				end
			end
		end

		assert(blob ~= nil, "the serialized part carries no collision geometry")
		return csgphs.parse(blob :: buffer, decompress_zstd), reference_size
	end)

	copy_part:Destroy()
	if not read_ok then
		error(result, 0)
	end

	return result :: csgphs.CollisionGeometry, reference_size :: Vector3
end

const function extract(part: BasePart, collision_fidelity: Enum.CollisionFidelity?): Extraction
	assert(is_supported(part), "collision extraction takes MeshParts and unions")
	local fidelity: Enum.CollisionFidelity = collision_fidelity or (part :: any).CollisionFidelity

	if fidelity == Enum.CollisionFidelity.Box then
		return {
			data = { size = part.Size, hulls = { box_hull(part) } },
			fidelity = fidelity,
			skipped_hulls = 0,
		}
	end

	local geometry, reference_size = extract_geometry(part, fidelity)
	local hulls: { Hull } = {}
	local skipped_hulls = 0
	if geometry.kind == "block" then
		-- the engine wrote the part off as its bounding box, which the
		-- extents already describe
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