--!strict

-- packed layout, little endian:
--   "BLTH" u32 version
--   f32 x 3 size
--   u32 hull_count
--   per hull:
--     f32 x 3 offset      the hull's centre in the part's object space
--     u32 vertex_count
--     u32 triangle_count
--     f32 x 3 x vertex_count      vertices about the offset
--     u16 x 3 x triangle_count    zero-based vertex indices

local EncodingService = game:GetService("EncodingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type Hull = {
	offset: Vector3,
	vertices: { Vector3 },
	adjacency: { { number } },
	-- three 1-based vertex indices per triangle, flat
	triangles: { number },
}

export type HullData = {
	size: Vector3,
	hulls: { Hull },
}

-- a hull needs no adjacency to be stored, it is rebuilt from the triangles on the way out
export type PackableHull = {
	offset: Vector3,
	vertices: { Vector3 },
	triangles: { number },
}

export type PackableHullData = {
	size: Vector3,
	hulls: { PackableHull },
}

local MAGIC = "BLTH"
local FORMAT_VERSION = 1
local STORAGE_FORMAT = "BoltHulls"
-- 75,000 bytes become exactly 100,000 Base64 characters
local CHUNK_BYTES = 75_000
local MAX_CHUNK_CHARACTERS = 100_000
local MAX_VERTICES_PER_HULL = 65_536

local function pack(data: PackableHullData): buffer
	local size = 4 + 4 + 12 + 4
	for _, hull in data.hulls do
		assert(#hull.vertices <= MAX_VERTICES_PER_HULL, "a hull holds more vertices than the format can index")
		assert(#hull.triangles % 3 == 0, "hull triangles must come in threes")
		size += 12 + 4 + 4 + #hull.vertices * 12 + #hull.triangles * 2
	end

	local packed = buffer.create(size)
	buffer.writestring(packed, 0, MAGIC)
	buffer.writeu32(packed, 4, FORMAT_VERSION)
	buffer.writef32(packed, 8, data.size.X)
	buffer.writef32(packed, 12, data.size.Y)
	buffer.writef32(packed, 16, data.size.Z)
	buffer.writeu32(packed, 20, #data.hulls)
	local offset = 24
	for _, hull in data.hulls do
		buffer.writef32(packed, offset, hull.offset.X)
		buffer.writef32(packed, offset + 4, hull.offset.Y)
		buffer.writef32(packed, offset + 8, hull.offset.Z)
		buffer.writeu32(packed, offset + 12, #hull.vertices)
		buffer.writeu32(packed, offset + 16, #hull.triangles // 3)
		offset += 20
		for _, vertex in hull.vertices do
			buffer.writef32(packed, offset, vertex.X)
			buffer.writef32(packed, offset + 4, vertex.Y)
			buffer.writef32(packed, offset + 8, vertex.Z)
			offset += 12
		end
		for _, index in hull.triangles do
			assert(index >= 1 and index <= #hull.vertices and index % 1 == 0, "hull triangle index out of range")
			buffer.writeu16(packed, offset, index - 1)
			offset += 2
		end
	end
	return packed
end

-- the edge graph of a triangle list: every triangle edge links its two
-- vertices both ways, once
local function build_adjacency(vertex_count: number, triangles: { number }): { { number } }
	local seen = table.create(vertex_count) :: { { [number]: boolean } }
	local adjacency = table.create(vertex_count) :: { { number } }
	for index = 1, vertex_count do
		seen[index] = {}
		adjacency[index] = {}
	end

	local function link(a: number, b: number)
		if a ~= b and not seen[a][b] then
			seen[a][b] = true
			seen[b][a] = true
			table.insert(adjacency[a], b)
			table.insert(adjacency[b], a)
		end
	end

	for triangle = 0, #triangles // 3 - 1 do
		local a, b, c = triangles[triangle * 3 + 1], triangles[triangle * 3 + 2], triangles[triangle * 3 + 3]
		link(a, b)
		link(b, c)
		link(c, a)
	end

	return adjacency
end

local function unpack(packed: buffer): HullData
	assert(buffer.len(packed) >= 24 and buffer.readstring(packed, 0, 4) == MAGIC, "not packed bolt hull data")
	local version = buffer.readu32(packed, 4)

	assert(version == FORMAT_VERSION, `unsupported bolt hull format version {version}, re-export the mesh`)

	local size = Vector3.new(buffer.readf32(packed, 8), buffer.readf32(packed, 12), buffer.readf32(packed, 16))
	local hull_count = buffer.readu32(packed, 20)
	local hulls = table.create(hull_count) :: { Hull }
	local offset = 24

	for hull_index = 1, hull_count do
		assert(offset + 20 <= buffer.len(packed), "truncated bolt hull data")
		local hull_offset = Vector3.new(
			buffer.readf32(packed, offset),
			buffer.readf32(packed, offset + 4),
			buffer.readf32(packed, offset + 8)
		)

		local vertex_count = buffer.readu32(packed, offset + 12)
		local triangle_count = buffer.readu32(packed, offset + 16)
		offset += 20

		assert(offset + vertex_count * 12 + triangle_count * 6 <= buffer.len(packed), "truncated bolt hull data")

		local vertices = table.create(vertex_count) :: { Vector3 }
		for index = 1, vertex_count do
			vertices[index] = Vector3.new(
				buffer.readf32(packed, offset),
				buffer.readf32(packed, offset + 4),
				buffer.readf32(packed, offset + 8)
			)
			offset += 12
		end

		local triangles = table.create(triangle_count * 3) :: { number }
		for index = 1, triangle_count * 3 do
			local vertex = buffer.readu16(packed, offset) + 1
			assert(vertex <= vertex_count, "bolt hull triangle index out of range")
			triangles[index] = vertex
			offset += 2
		end

		hulls[hull_index] = {
			offset = hull_offset,
			vertices = vertices,
			adjacency = build_adjacency(vertex_count, triangles),
			triangles = triangles,
		}
	end

	assert(offset == buffer.len(packed), "bolt hull data has trailing bytes")

	return { size = size, hulls = hulls }
end

local function hex_digest(digest: buffer): string
	local parts = table.create(buffer.len(digest))
	for index = 0, buffer.len(digest) - 1 do
		parts[index + 1] = string.format("%02x", buffer.readu8(digest, index))
	end
	return table.concat(parts)
end

local function hash(data: buffer): string
	return hex_digest(EncodingService:ComputeBufferHash(data, Enum.HashAlgorithm.Blake3))
end

-- stores hull data as a Folder named `name` under `parent`, replacing any previous export of that name
local function write(parent: Instance, name: string, data: PackableHullData): Folder
	local packed = pack(data)
	local frame = EncodingService:CompressBuffer(packed, Enum.CompressionAlgorithm.Zstd)
	local stored_length = buffer.len(frame)

	local previous = parent:FindFirstChild(name)
	if previous ~= nil then
		previous:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("Format", STORAGE_FORMAT)
	folder:SetAttribute("Version", FORMAT_VERSION)
	folder:SetAttribute("ByteLength", buffer.len(packed))
	folder:SetAttribute("StoredLength", stored_length)
	folder:SetAttribute("Hash", hash(packed))
	local chunk_count = math.ceil(stored_length / CHUNK_BYTES)
	folder:SetAttribute("ChunkCount", chunk_count)

	for chunk_index = 0, chunk_count - 1 do
		local offset = chunk_index * CHUNK_BYTES
		local length = math.min(CHUNK_BYTES, stored_length - offset)
		local slice = frame

		if length < stored_length then
			slice = buffer.create(length)
			buffer.copy(slice, 0, frame, offset, length)
		end

		local chunk = Instance.new("StringValue")
		chunk.Name = string.format("%06d", chunk_index)
		chunk.Value = buffer.tostring(EncodingService:Base64Encode(slice))
		chunk.Parent = folder
	end

	folder.Parent = parent
	return folder
end

local function read_count(folder: Instance, attribute: string): number
	local value = folder:GetAttribute(attribute)
	assert(
		type(value) == "number" and value >= 0 and value % 1 == 0,
		`{folder:GetFullName()}: attribute {attribute} is invalid`
	)
	return value
end

local function read(folder: Instance): HullData
	local name = folder:GetFullName()
	assert(folder:GetAttribute("Format") == STORAGE_FORMAT, `{name} is not an exported bolt hull folder`)
	local byte_length = read_count(folder, "ByteLength")
	local stored_length = read_count(folder, "StoredLength")
	local chunk_count = read_count(folder, "ChunkCount")
	local expected_hash = folder:GetAttribute("Hash")
	assert(type(expected_hash) == "string", `{name}: attribute Hash is invalid`)

	local stream = buffer.create(stored_length)
	local write_offset = 0
	for chunk_index = 0, chunk_count - 1 do
		local chunk = folder:FindFirstChild(string.format("%06d", chunk_index))
		assert(chunk ~= nil and chunk:IsA("StringValue"), `{name}: chunk {chunk_index} is missing`)
		local value = chunk.Value
		assert(#value > 0 and #value <= MAX_CHUNK_CHARACTERS and #value % 4 == 0, `{name}: chunk {chunk_index} length is invalid`)
		local decoded = EncodingService:Base64Decode(buffer.fromstring(value))
		assert(write_offset + buffer.len(decoded) <= stored_length, `{name}: chunk {chunk_index} exceeds StoredLength`)
		buffer.copy(stream, write_offset, decoded)
		write_offset += buffer.len(decoded)
	end
	assert(write_offset == stored_length, `{name}: chunks do not fill StoredLength`)

	local packed = EncodingService:DecompressBuffer(stream, Enum.CompressionAlgorithm.Zstd)
	assert(buffer.len(packed) == byte_length, `{name}: payload does not decompress to ByteLength`)
	local actual_hash = hash(packed)
	assert(actual_hash == expected_hash, `{name}: payload hash mismatch`)
	return unpack(packed)
end

local function decode(name: string): HullData
	local collisions = ReplicatedStorage:FindFirstChild("Collisions")
	local hulls = if collisions ~= nil then collisions:FindFirstChild("Hulls") else nil
	local folder = if hulls ~= nil then hulls:FindFirstChild(name) else nil
	assert(folder ~= nil, `no exported hulls named "{name}" under ReplicatedStorage.Collisions.Hulls`)
	return read(folder :: Instance)
end

return {
	FORMAT_VERSION = FORMAT_VERSION,
	pack = pack,
	unpack = unpack,
	write = write,
	read = read,
	decode = decode,
}