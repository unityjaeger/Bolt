--!strict
--!optimize 2

-- layout, as reverse engineered by krakow10's rbx_mesh:
--   "CSGPHS" u32 version
--   version 0: the literal "BLOCK"
--   version 8: u8 geometry_type, u8 0, then ONE zstd frame whose payload is
--     u32 hull_count            edgebreaker-coded hulls
--     u32 position_count        vertices of those hulls, all together
--     u32 face_count            triangles of those hulls, all together
--     u32 x 2                   first hull's vertex and triangle counts (unused)
--     u32 raw_hulls_length      bytes of the raw section, 0 when absent
--     u32 clers_bit_count       valid bits of the edgebreaker symbol stream
--     u32 clers_buffer_length   bytes of that stream, a multiple of four
--     u32 positions_length      bytes of the f32 vertex block
--     f32 x 6                   aabb min, aabb max
--     raw hulls                 u32 count, u32 face_ranges[count], u32 faces[last range], u32 count, u32 pos_ranges[count], f32 positions[last range]
--     u8 x clers_buffer_length  the symbol stream
--     f32 x 3 x position_count  the edgebreaker hulls' vertices, hull by hull
--   versions 3, 5, 6 and 7 are older layouts, re-unioning a part rewrites its data as version 8

export type CollisionHull = {
	-- XYZ per vertex, tightly packed f32, in the serialized part's local space
	positions: buffer,
	vertex_count: number,
	-- three zero-based u32 vertex indices per triangle
	indices: buffer,
	triangle_count: number,
}

export type CollisionGeometry = {
	-- "block" collides as the part's bounding box
	kind: "block" | "hulls",
	version: number,
	-- Hull 1, PreciseConvexDecomposition 3, Default 6 and a Box that cannot be a centred block (mesh built off its origin) writes its box as a hull with 1
	hulls: { CollisionHull },
	-- version 8: how many leading hulls came from the raw (indexed) section
	raw_hull_count: number,
}

const HEADER = "CSGPHS"

const function is_collision_blob(bytes: buffer): boolean
	return buffer.len(bytes) >= 10 and buffer.readstring(bytes, 0, 6) == HEADER
end

type BitReader = {
	bytes: buffer,
	word_offset: number,
	word_end: number,
	cache_value: number,
	cache_bits: number,
	remaining_bits: number,
}

const function create_bit_reader(bytes: buffer, offset: number, length: number, bit_count: number): BitReader
	assert(length % 4 == 0, "CSGPHS clers buffer length must be a multiple of four")
	assert(bit_count <= length * 8, "CSGPHS clers bit count exceeds its buffer")

	return {
		bytes = bytes,
		word_offset = offset,
		word_end = offset + length,
		cache_value = 0,
		cache_bits = 0,
		remaining_bits = bit_count,
	}
end

const function low_mask(bits: number): number
	return if bits >= 32 then 0xFFFFFFFF else bit32.lshift(1, bits) - 1
end

const function read_bits(reader: BitReader, bits: number): number
	local value, value_bits = 0, 0

	if reader.cache_bits < bits then
		-- hand out whatever the cache still holds, then refill it with the next word, or with nothing past the end of the stream
		value, value_bits = reader.cache_value, reader.cache_bits
		local draw = math.min(reader.remaining_bits, 32)
		reader.remaining_bits -= draw

		local word = 0
		if reader.word_offset < reader.word_end then
			word = bit32.band(buffer.readu32(reader.bytes, reader.word_offset), low_mask(draw))
			reader.word_offset += 4
		end

		reader.cache_value, reader.cache_bits = word, draw
	end

	local draw = bits - value_bits
	if reader.cache_bits < draw then
		error("CSGPHS clers stream ended early")
	end

	local shift = reader.cache_bits - draw
	local popped = bit32.rshift(reader.cache_value, shift)
	reader.cache_value = bit32.band(reader.cache_value, low_mask(shift))
	reader.cache_bits = shift

	return bit32.bor(bit32.lshift(value, draw), popped)
end

-- C is the single bit 0
-- S, L, R and E are a 1 followed by 00, 01, 10, 11
const SYMBOL_CONTINUE = 0
const SYMBOL_SPLIT = 1
const SYMBOL_LEFT = 2
const SYMBOL_RIGHT = 3
-- E is 4, the last branch of decode_faces

const function read_symbol(reader: BitReader): number
	if read_bits(reader, 1) == 0 then
		return SYMBOL_CONTINUE
	end

	return read_bits(reader, 2) + 1
end

-- adjacency holds the twin edge per face corner edge, or one of these
const EDGE_UNINITIALIZED = -3
const EDGE_PROCESSING = -2
const EDGE_BOUNDARY = -1

type HullDecoder = {
	reader: BitReader,
	-- i32 per edge
	adjacency: buffer,
	-- u32 vertex id per edge (the corner the edge starts at)
	indices: buffer,
	edge_capacity: number,
	current_face: number,
	-- vertices of the hull being decoded, then the running total
	vertex_count: number,
	vertex_offset: number,
}

-- edges are numbered 3 * face + corner, next and prev rotate within the face
const function edge_next(edge: number): number
	return edge - edge % 3 + (edge + 1) % 3
end

const function edge_prev(edge: number): number
	return edge - edge % 3 + (edge + 2) % 3
end

-- pairs the boundary edges left open by L, R and E symbols and merges the vertex ids of the corners those pairings declare as together
const function zip_boundary(decoder: HullDecoder, current_edge: number): number
	local adjacency, indices = decoder.adjacency, decoder.indices

	while buffer.readi32(adjacency, current_edge * 4) == EDGE_PROCESSING do
		-- walk the fan around the corner via twin then next until it ends
		local candidate_edge = edge_next(current_edge)
		while true do
			local opposite_edge = buffer.readi32(adjacency, candidate_edge * 4)
			if opposite_edge < 0 then
				break
			end
			candidate_edge = edge_next(opposite_edge)
		end

		if buffer.readi32(adjacency, candidate_edge * 4) ~= EDGE_BOUNDARY then
			break
		end

		-- link the two boundary edges as twins
		buffer.writei32(adjacency, current_edge * 4, candidate_edge)
		buffer.writei32(adjacency, candidate_edge * 4, current_edge)

		current_edge = edge_prev(current_edge)

		-- the merged corner uses the surviving vertex id, as does the rest of the fan already connected to it
		local prev_edge = current_edge
		local candidate_prev_edge = edge_prev(candidate_edge)
		buffer.writeu32(indices, edge_prev(current_edge) * 4, buffer.readu32(indices, candidate_prev_edge * 4))

		local connected_edge = buffer.readi32(adjacency, current_edge * 4)
		while connected_edge >= 0 and candidate_edge ~= prev_edge do
			prev_edge = edge_prev(connected_edge)
			buffer.writeu32(indices, edge_prev(prev_edge) * 4, buffer.readu32(indices, candidate_prev_edge * 4))
			connected_edge = buffer.readi32(adjacency, prev_edge * 4)
		end

		-- hop along the connected fan to the next edge still waiting
		while true do
			local linked_edge = buffer.readi32(adjacency, current_edge * 4)
			if linked_edge < 0 or current_edge == candidate_edge then
				break
			end

			current_edge = edge_prev(linked_edge)
		end
	end
	return current_edge
end

-- emits faces along the gate edge `cursor` until an E closes this branch, S symbols recurse, so S and E pair up like parentheses
const function decode_faces(decoder: HullDecoder, cursor: number)
	local adjacency, indices = decoder.adjacency, decoder.indices

	while true do
		local face = decoder.current_face
		local edge_0 = 3 * face
		if edge_0 + 3 > decoder.edge_capacity then
			error("malformed CSGPHS hull: more triangles than declared")
		end

		local edge_1, edge_2 = edge_0 + 1, edge_0 + 2

		buffer.writei32(adjacency, edge_0 * 4, cursor)
		buffer.writei32(adjacency, edge_1 * 4, EDGE_UNINITIALIZED)
		buffer.writei32(adjacency, edge_2 * 4, EDGE_UNINITIALIZED)
		decoder.current_face = face + 1

		buffer.writei32(adjacency, cursor * 4, edge_0)
		buffer.writeu32(indices, edge_1 * 4, buffer.readu32(indices, edge_prev(cursor) * 4))
		buffer.writeu32(indices, edge_2 * 4, buffer.readu32(indices, edge_next(cursor) * 4))
		cursor = edge_1

		local symbol = read_symbol(decoder.reader)
		if symbol == SYMBOL_CONTINUE then
			-- a brand new vertex
			buffer.writeu32(indices, edge_0 * 4, decoder.vertex_count)
			buffer.writei32(adjacency, edge_next(cursor) * 4, EDGE_BOUNDARY)
			decoder.vertex_count += 1
		elseif symbol == SYMBOL_SPLIT then
			decode_faces(decoder, cursor)
			cursor = edge_next(cursor)
		elseif symbol == SYMBOL_LEFT then
			buffer.writei32(adjacency, cursor * 4, EDGE_PROCESSING)
			cursor = edge_next(cursor)
		elseif symbol == SYMBOL_RIGHT then
			local next_edge = edge_next(cursor)
			buffer.writei32(adjacency, next_edge * 4, EDGE_PROCESSING)
			zip_boundary(decoder, next_edge)
		else
			-- E closes this branch
			buffer.writei32(adjacency, cursor * 4, EDGE_PROCESSING)
			local next_edge = edge_next(cursor)
			buffer.writei32(adjacency, next_edge * 4, EDGE_PROCESSING)
			zip_boundary(decoder, next_edge)
			return
		end
	end
end

const function decode_hull(decoder: HullDecoder)
	local edge = 3 * decoder.current_face
	if edge + 3 > decoder.edge_capacity then
		error("malformed CSGPHS hull: more triangles than declared")
	end

	local adjacency, indices = decoder.adjacency, decoder.indices
	buffer.writei32(adjacency, edge * 4, EDGE_BOUNDARY)
	buffer.writei32(adjacency, (edge + 1) * 4, EDGE_UNINITIALIZED)
	buffer.writei32(adjacency, (edge + 2) * 4, EDGE_BOUNDARY)
	decoder.current_face += 1

	buffer.writeu32(indices, edge * 4, 0)
	buffer.writeu32(indices, (edge + 1) * 4, 1)
	buffer.writeu32(indices, (edge + 2) * 4, 2)
	decoder.vertex_count = 3

	decode_faces(decoder, edge + 1)

	decoder.vertex_offset += decoder.vertex_count
end

const function slice_hull(
	positions: buffer,
	position_offset: number,
	vertex_count: number,
	indices: buffer,
	index_offset: number,
	triangle_count: number
): CollisionHull
	local hull_positions = buffer.create(vertex_count * 12)
	buffer.copy(hull_positions, 0, positions, position_offset, vertex_count * 12)
	local hull_indices = buffer.create(triangle_count * 12)
	buffer.copy(hull_indices, 0, indices, index_offset, triangle_count * 12)

	for index_position = 0, triangle_count * 12 - 4, 4 do
		if buffer.readu32(hull_indices, index_position) >= vertex_count then
			error("malformed CSGPHS hull: triangle index out of range")
		end
	end

	return {
		positions = hull_positions,
		vertex_count = vertex_count,
		indices = hull_indices,
		triangle_count = triangle_count,
	}
end

const function parse_version_8(payload: buffer, geometry_type: number): CollisionGeometry
	assert(buffer.len(payload) >= 60, "truncated CSGPHS payload")

	local hull_count = buffer.readu32(payload, 0)
	local position_count = buffer.readu32(payload, 4)
	local face_count = buffer.readu32(payload, 8)
	local raw_hulls_length = buffer.readu32(payload, 20)
	local clers_bit_count = buffer.readu32(payload, 24)
	local clers_buffer_length = buffer.readu32(payload, 28)
	local positions_length = buffer.readu32(payload, 32)

	assert(positions_length == position_count * 12, "CSGPHS position block length disagrees with its count")

	local hulls: { CollisionHull } = {}
	local offset = 60

	-- raw hulls: cumulative index and position ranges over two flat arrays
	local raw_hull_count = 0
	if raw_hulls_length ~= 0 then
		local raw_start = offset
		local face_range_count = buffer.readu32(payload, offset)
		local face_ranges_offset = offset + 4
		local face_total = if face_range_count == 0
			then 0
			else buffer.readu32(payload, face_ranges_offset + (face_range_count - 1) * 4)
		local faces_offset = face_ranges_offset + face_range_count * 4
		offset = faces_offset + face_total * 4

		local position_range_count = buffer.readu32(payload, offset)
		local position_ranges_offset = offset + 4
		local position_total = if position_range_count == 0
			then 0
			else buffer.readu32(payload, position_ranges_offset + (position_range_count - 1) * 4)
		local raw_positions_offset = position_ranges_offset + position_range_count * 4
		offset = raw_positions_offset + position_total * 4

		assert(offset - raw_start == raw_hulls_length, "CSGPHS raw hull section length mismatch")

		raw_hull_count = math.max(0, math.min(face_range_count, position_range_count) - 1)
		for hull_index = 0, raw_hull_count - 1 do
			local face_start = buffer.readu32(payload, face_ranges_offset + hull_index * 4)
			local face_end = buffer.readu32(payload, face_ranges_offset + (hull_index + 1) * 4)
			local position_start = buffer.readu32(payload, position_ranges_offset + hull_index * 4)
			local position_end = buffer.readu32(payload, position_ranges_offset + (hull_index + 1) * 4)
			assert(
				face_end >= face_start and (face_end - face_start) % 3 == 0,
				"CSGPHS raw hull face range is not whole triangles"
			)

			assert(
				position_end >= position_start and (position_end - position_start) % 3 == 0,
				"CSGPHS raw hull position range is not whole vertices"
			)

			table.insert(
				hulls,
				slice_hull(
					payload,
					raw_positions_offset + position_start * 4,
					(position_end - position_start) // 3,
					payload,
					faces_offset + face_start * 4,
					(face_end - face_start) // 3
				)
			)
		end
	end

	local clers_offset = offset
	local positions_offset = clers_offset + clers_buffer_length
	assert(positions_offset + positions_length <= buffer.len(payload), "truncated CSGPHS payload")

	-- edgebreaker hulls share one vertex block and one symbol stream
	local edge_capacity = face_count * 3
	local decoder: HullDecoder = {
		reader = create_bit_reader(payload, clers_offset, clers_buffer_length, clers_bit_count),
		adjacency = buffer.create(edge_capacity * 4),
		indices = buffer.create(edge_capacity * 4),
		edge_capacity = edge_capacity,
		current_face = 0,
		vertex_count = 0,
		vertex_offset = 0,
	}

	for edge = 0, edge_capacity - 1 do
		buffer.writei32(decoder.adjacency, edge * 4, EDGE_UNINITIALIZED)
	end

	for _ = 1, hull_count do
		local face_start = decoder.current_face
		local vertex_start = decoder.vertex_offset

		decode_hull(decoder)

		table.insert(
			hulls,
			slice_hull(
				payload,
				positions_offset + vertex_start * 12,
				decoder.vertex_offset - vertex_start,
				decoder.indices,
				face_start * 12,
				decoder.current_face - face_start
			)
		)
	end

	assert(decoder.current_face == face_count, "CSGPHS hulls decoded to a different triangle count than declared")
	assert(decoder.vertex_offset == position_count, "CSGPHS hulls decoded to a different vertex count than declared")

	return {
		kind = "hulls",
		version = 8,
		geometry_type = geometry_type,
		hulls = hulls,
		raw_hull_count = raw_hull_count,
	}
end

-- `decompress_zstd` receives one complete zstd frame and returns its payload
const function parse(blob: buffer, decompress_zstd: (buffer) -> buffer): CollisionGeometry
	assert(is_collision_blob(blob), "not a CSGPHS collision blob")

	local version = buffer.readu32(blob, 6)
	if version == 0 then
		assert(buffer.len(blob) >= 15 and buffer.readstring(blob, 10, 5) == "BLOCK", "unrecognized CSGPHS version 0 blob")
		return {
			kind = "block",
			version = 0,
			geometry_type = 0,
			hulls = {},
			raw_hull_count = 0,
		}
	elseif version == 8 then
		assert(buffer.len(blob) >= 12, "truncated CSGPHS blob")
		local geometry_type = buffer.readu8(blob, 10)
		local frame = buffer.create(buffer.len(blob) - 12)
		buffer.copy(frame, 0, blob, 12)
		return parse_version_8(decompress_zstd(frame), geometry_type)
	end

	error(
		`unsupported CSGPHS version {version}: only version 0 (BLOCK) and 8 are read, ` .. "re-union the part with GeometryService:UnionAsync to rewrite it as version 8"
	)
end

return {
	HEADER = HEADER,
	is_collision_blob = is_collision_blob,
	parse = parse,
}