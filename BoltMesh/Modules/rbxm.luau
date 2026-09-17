--!strict
--!optimize 2

export type ModelClass = {
	name: string,
	instance_count: number,
	-- per property name, one value per instance of the class in file order
	-- only String properties (Name among them) are decoded
	strings: { [string]: { string } },
	-- per property name, one 1-based index into `shared_strings` per instance
	shared_string_indices: { [string]: { number } },
}

export type Model = {
	shared_strings: { buffer },
	classes: { [number]: ModelClass },
}

const SIGNATURE = "<roblox!\137\255\r\n\26\n"
const ZSTD_MAGIC = "\40\181\47\253"
const TYPE_STRING = 1
const TYPE_SHARED_STRING = 28

-- one LZ4 block
const function decompress_lz4_block(source: buffer, offset: number, length: number, output_length: number): buffer
	local output = buffer.create(output_length)
	local input_position = offset
	local input_end = offset + length
	local output_position = 0

	while input_position < input_end do
		local token = buffer.readu8(source, input_position)
		input_position += 1

		local literal_length = bit32.rshift(token, 4)
		if literal_length == 15 then
			local extra = 255
			while extra == 255 do
				extra = buffer.readu8(source, input_position)
				input_position += 1
				literal_length += extra
			end
		end

		buffer.copy(output, output_position, source, input_position, literal_length)

		output_position += literal_length
		input_position += literal_length
		if input_position >= input_end then
			break
		end

		local match_offset = buffer.readu16(source, input_position)
		input_position += 2

		assert(match_offset > 0 and match_offset <= output_position, "corrupt LZ4 block: match offset out of range")

		local match_length = bit32.band(token, 15)
		if match_length == 15 then
			local extra = 255
			while extra == 255 do
				extra = buffer.readu8(source, input_position)
				input_position += 1
				match_length += extra
			end
		end
		match_length += 4

		-- a match may overlap its own output, copying one offset's worth at a time replicates the pattern the way a byte loop would
		local match_position = output_position - match_offset
		while match_length > match_offset do
			buffer.copy(output, output_position, output, match_position, match_offset)
			output_position += match_offset
			match_length -= match_offset
		end

		buffer.copy(output, output_position, output, match_position, match_length)
		output_position += match_length
	end

	assert(output_position == output_length, "corrupt LZ4 block: decompressed length mismatch")

	return output
end

const function read_chunk_content(
	bytes: buffer,
	position: number,
	compressed_length: number,
	uncompressed_length: number,
	decompress_zstd: ((buffer) -> buffer)?
): buffer
	if compressed_length == 0 then
		local content = buffer.create(uncompressed_length)
		buffer.copy(content, 0, bytes, position, uncompressed_length)
		return content
	elseif compressed_length >= 4 and buffer.readstring(bytes, position, 4) == ZSTD_MAGIC then
		assert(decompress_zstd ~= nil, "the model has zstd-compressed chunks and no zstd decompressor was supplied")
		local frame = buffer.create(compressed_length)
		buffer.copy(frame, 0, bytes, position, compressed_length)
		return (decompress_zstd :: (buffer) -> buffer)(frame)
	end

	return decompress_lz4_block(bytes, position, compressed_length, uncompressed_length)
end

const function read_shared_string_chunk(content: buffer, shared_strings: { buffer })
	local count = buffer.readu32(content, 4)
	local offset = 8

	for _ = 1, count do
		local string_length = buffer.readu32(content, offset + 16)
		local value = buffer.create(string_length)
		buffer.copy(value, 0, content, offset + 20, string_length)
		table.insert(shared_strings, value)
		offset += 20 + string_length
	end
end

const function read_instance_chunk(content: buffer, classes: { [number]: ModelClass })
	local class_id = buffer.readu32(content, 0)
	local name_length = buffer.readu32(content, 4)

	classes[class_id] = {
		name = buffer.readstring(content, 8, name_length),
		-- u8 object format sits between the name and the count
		instance_count = buffer.readu32(content, 9 + name_length),
		strings = {},
		shared_string_indices = {},
	}
end

const function read_property_chunk(content: buffer, classes: { [number]: ModelClass })
	local class_id = buffer.readu32(content, 0)
	local name_length = buffer.readu32(content, 4)
	local property_name = buffer.readstring(content, 8, name_length)
	local type_id = buffer.readu8(content, 8 + name_length)
	local offset = 9 + name_length
	local class = classes[class_id]

	assert(class ~= nil, "Roblox binary model property chunk precedes its instance chunk")

	local count = class.instance_count
	if type_id == TYPE_STRING then
		local values = table.create(count) :: { string }
		for index = 1, count do
			local value_length = buffer.readu32(content, offset)
			values[index] = buffer.readstring(content, offset + 4, value_length)
			offset += 4 + value_length
		end

		class.strings[property_name] = values
	elseif type_id == TYPE_SHARED_STRING then
		-- byte-interleaved big-endian u32: all first bytes, then all second bytes, and so on
		local values = table.create(count) :: { number }
		for index = 0, count - 1 do
			values[index + 1] = buffer.readu8(content, offset + index) * 16777216
				+ buffer.readu8(content, offset + count + index) * 65536
				+ buffer.readu8(content, offset + 2 * count + index) * 256
				+ buffer.readu8(content, offset + 3 * count + index)
				+ 1
		end

		class.shared_string_indices[property_name] = values
	end
end

-- the shared strings of the model in SSTR order, each as its own buffer, and per class the String and SharedString properties of its instances
const function read_model(bytes: buffer, decompress_zstd: ((buffer) -> buffer)?): Model
	local length = buffer.len(bytes)
	assert(length >= 32 and buffer.readstring(bytes, 0, 14) == SIGNATURE, "not a Roblox binary model")
	assert(buffer.readu16(bytes, 14) == 0, "unsupported Roblox binary model version")

	local model: Model = {
		shared_strings = {},
		classes = {},
	}

	local position = 32
	while true do
		assert(position + 16 <= length, "truncated Roblox binary model")
		local name = buffer.readstring(bytes, position, 4)
		local compressed_length = buffer.readu32(bytes, position + 4)
		local uncompressed_length = buffer.readu32(bytes, position + 8)
		position += 16

		if name == "END\0" then
			break
		end

		local data_length = if compressed_length == 0 then uncompressed_length else compressed_length
		assert(position + data_length <= length, "truncated Roblox binary model chunk")

		if name == "SSTR" or name == "INST" or name == "PROP" then
			local content = read_chunk_content(bytes, position, compressed_length, uncompressed_length, decompress_zstd)
			if name == "SSTR" then
				read_shared_string_chunk(content, model.shared_strings)
			elseif name == "INST" then
				read_instance_chunk(content, model.classes)
			else
				read_property_chunk(content, model.classes)
			end
		end
		position += data_length
	end

	return model
end

const function read_shared_strings(bytes: buffer, decompress_zstd: ((buffer) -> buffer)?): { buffer }
	return read_model(bytes, decompress_zstd).shared_strings
end

local internal = {
	decompress_lz4_block = decompress_lz4_block,
}
table.freeze(internal)

return {
	read_model = read_model,
	read_shared_strings = read_shared_strings,
	internal = internal,
}