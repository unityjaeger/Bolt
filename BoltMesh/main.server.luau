--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

local Iris = require(script.Parent.Dependencies.Iris).Init(CoreGui)
local collision_geometry = require(script.Parent.Modules.collision_geometry)
local CollisionParser = require(script.Parent.Modules.CollisionParser)

type Extraction = collision_geometry.Extraction

-- vertex indices fit in a u16, so an edge key never collides
local MAX_EDGE_KEY = 65536

local COLOR_NEUTRAL = Color3.fromRGB(160, 160, 160)
local COLOR_GOOD = Color3.fromRGB(120, 255, 170)
local COLOR_WARN = Color3.fromRGB(255, 210, 120)
local COLOR_BAD = Color3.fromRGB(255, 110, 110)

-- one colour per hull, cycling
local HULL_COLORS = {
	Color3.fromRGB(255, 89, 89),
	Color3.fromRGB(89, 200, 255),
	Color3.fromRGB(120, 255, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(220, 120, 255),
	Color3.fromRGB(80, 255, 220),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(180, 200, 255),
}

local toolbar = plugin:CreateToolbar("Bolt")
local toggle_button = toolbar:CreateButton("Hulls", "Toggle the Bolt hull exporter", "rbxassetid://114184154")

local window_open = Iris.State(false)
local preview_enabled = Iris.State(false)

local target: BasePart? = nil
local status_text = "Select a MeshPart or union, then press Use Selected"
local status_color = COLOR_NEUTRAL
local busy = false

local cached: { target: BasePart, key: string, extraction: Extraction }? = nil

local preview_adornments: { WireframeHandleAdornment } = {}
local preview_connections: { RBXScriptConnection } = {}

local function set_status(text: string, color: Color3)
	status_text = text
	status_color = color
end

local function format_bytes(bytes: number): string
	if bytes >= 1024 * 1024 then
		return string.format("%.2f MB", bytes / (1024 * 1024))
	elseif bytes >= 1024 then
		return string.format("%.1f KB", bytes / 1024)
	end
	return `{bytes} B`
end

local function describe(part: BasePart): string
	return `{part.Name} [{part.ClassName}]`
end

local function extraction_key(part: BasePart): string
	local mesh = if part:IsA("MeshPart") then part.MeshId else ""
	return `{mesh}|{(part :: any).CollisionFidelity.Name}`
end

-- yields
local function get_extraction(part: BasePart): Extraction
	local key = extraction_key(part)
	if cached ~= nil and cached.target == part and cached.key == key then
		return cached.extraction
	end

	local extraction = collision_geometry.extract(part)
	cached = { target = part, key = key, extraction = extraction }
	return extraction
end

local function clear_preview()
	for _, connection in preview_connections do
		connection:Disconnect()
	end
	table.clear(preview_connections)

	for _, adornment in preview_adornments do
		adornment:Destroy()
	end
	table.clear(preview_adornments)
end

local function draw_preview(part: BasePart, extraction: Extraction)
	local data = extraction.data
	local scale = part.Size / data.size
	local cframe = part.CFrame
	for index, hull in data.hulls do
		local adornment = preview_adornments[index]
		if adornment == nil then
			adornment = Instance.new("WireframeHandleAdornment")
			adornment.Name = `BoltHull{index}`
			adornment.Adornee = workspace.Terrain
			adornment.Color3 = HULL_COLORS[(index - 1) % #HULL_COLORS + 1]
			adornment.AlwaysOnTop = true
			adornment.Thickness = 2
			adornment.Parent = CoreGui
			preview_adornments[index] = adornment
		end
		adornment:Clear()

		local origin = hull.offset * scale
		local points: { Vector3 } = {}
		local seen: { [number]: boolean } = {}

		local triangles = hull.triangles
		local vertices = hull.vertices
		for triangle = 0, #triangles // 3 - 1 do
			local a, b, c = triangles[triangle * 3 + 1], triangles[triangle * 3 + 2], triangles[triangle * 3 + 3]

			--a -> b
			local lo, hi = a, b
			if lo > hi then
				lo, hi = hi, lo
			end
			local key = lo * MAX_EDGE_KEY + hi
			if not seen[key] then
				seen[key] = true
				table.insert(points, cframe * (origin + vertices[lo] * scale))
				table.insert(points, cframe * (origin + vertices[hi] * scale))
			end

			--b -> c
			lo, hi = b, c
			if lo > hi then
				lo, hi = hi, lo
			end
			key = lo * MAX_EDGE_KEY + hi
			if not seen[key] then
				seen[key] = true
				table.insert(points, cframe * (origin + vertices[lo] * scale))
				table.insert(points, cframe * (origin + vertices[hi] * scale))
			end

			--c -> a
			lo, hi = c, a
			if lo > hi then
				lo, hi = hi, lo
			end
			key = lo * MAX_EDGE_KEY + hi
			if not seen[key] then
				seen[key] = true
				table.insert(points, cframe * (origin + vertices[lo] * scale))
				table.insert(points, cframe * (origin + vertices[hi] * scale))
			end
		end

		adornment:AddLines(points)
	end
end

local function start_preview(part: BasePart, extraction: Extraction)
	clear_preview()
	draw_preview(part, extraction)
	for _, property in { "CFrame", "Size" } do
		table.insert(preview_connections, part:GetPropertyChangedSignal(property):Connect(function()
			draw_preview(part, extraction)
		end))
	end
	table.insert(preview_connections, part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(game) then
			clear_preview()
			preview_enabled:set(false)
		end
	end))
end

local function ensure_export_folder(): Folder
	local collisions = ReplicatedStorage:FindFirstChild("Collisions")
	if collisions ~= nil and not collisions:IsA("Folder") then
		collisions:Destroy()
		collisions = nil
	end
	if collisions == nil then
		local folder = Instance.new("Folder")
		folder.Name = "Collisions"
		folder.Parent = ReplicatedStorage
		collisions = folder
	end
	local collisions_folder = collisions :: Folder

	local hulls = collisions_folder:FindFirstChild("Hulls")
	if hulls ~= nil and not hulls:IsA("Folder") then
		hulls:Destroy()
		hulls = nil
	end
	if hulls == nil then
		local folder = Instance.new("Folder")
		folder.Name = "Hulls"
		folder.Parent = collisions_folder
		hulls = folder
	end

	local previous_parser = collisions_folder:FindFirstChild("CollisionParser")
	if previous_parser ~= nil then
		previous_parser:Destroy()
	end

	local parser = script.Parent.Modules.CollisionParser:Clone()
	parser.Name = "CollisionParser"
	parser.Parent = collisions_folder

	return hulls :: Folder
end

local function fidelity_note(extraction: Extraction): string?
	local fidelity = extraction.fidelity
	if fidelity == Enum.CollisionFidelity.Box then
		return "Box fidelity: exported as a single box hull"
	elseif fidelity == Enum.CollisionFidelity.Hull then
		return "Hull fidelity: one convex hull, concavities are filled"
	elseif extraction.skipped_hulls > 0 then
		return `{extraction.skipped_hulls} degenerate hulls skipped`
	end
	return nil
end

-- yields
local function run_preview(part: BasePart)
	local ok, result = pcall(get_extraction, part)
	if not ok then
		preview_enabled:set(false)
		set_status(`Preview failed: {result}`, COLOR_BAD)
		return
	end
	local extraction = result :: Extraction
	start_preview(part, extraction)
	local note = fidelity_note(extraction)
	set_status(`Previewing {#extraction.data.hulls} hulls{if note then `. {note}` else ""}`, COLOR_GOOD)
end

-- yields
local function run_export(part: BasePart)
	local ok, result = pcall(get_extraction, part)
	if not ok then
		set_status(`Export failed: {result}`, COLOR_BAD)
		return
	end
	local extraction = result :: Extraction

	local recording = ChangeHistoryService:TryBeginRecording("Bolt hull export", `Export hulls of {part.Name}`)
	local write_ok, write_result = pcall(function(): Folder
		return CollisionParser.write(ensure_export_folder(), part.Name, extraction.data)
	end)
	if recording ~= nil then
		ChangeHistoryService:FinishRecording(
			recording,
			if write_ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end
	if not write_ok then
		set_status(`Export failed: {write_result}`, COLOR_BAD)
		return
	end

	local folder = write_result :: Folder
	local stored = folder:GetAttribute("StoredLength") :: number
	local raw = folder:GetAttribute("ByteLength") :: number
	local chunks = folder:GetAttribute("ChunkCount") :: number
	local note = fidelity_note(extraction)
	set_status(
		`Exported {#extraction.data.hulls} hulls to Collisions.Hulls.{part.Name}: {format_bytes(stored)} stored in {chunks} chunks ({format_bytes(raw)} raw){if note then `. {note}` else ""}`,
		COLOR_GOOD
	)
end

local function run(part: BasePart, work: (BasePart) -> ())
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		work(part)
		busy = false
	end)
end

toggle_button.Click:Connect(function()
	window_open:set(not window_open:get())
end)

Iris:Connect(function()
	Iris.Window({ "Bolt Hulls" }, { isOpened = window_open })

	Iris.Text({ "Source" })
	Iris.SameLine()
	if Iris.Button({ "Use Selected" }).clicked() then
		local current = Selection:Get()[1]
		if current == nil then
			target = nil
			set_status("Nothing is selected", COLOR_BAD)
		elseif collision_geometry.is_supported(current) then
			target = current :: BasePart
			set_status(`Selected {describe(target :: BasePart)}`, COLOR_GOOD)
		else
			target = nil
			set_status(`{current.Name} [{current.ClassName}] is not a MeshPart or union`, COLOR_BAD)
		end
		-- a new target invalidates a running preview of the old one
		if preview_enabled:get() then
			preview_enabled:set(false)
			clear_preview()
		end
	end
	Iris.End()

	local part = target
	if part ~= nil and part:IsDescendantOf(game) then
		Iris.Text({ describe(part), false, COLOR_GOOD })
		Iris.Text({ `Fidelity: {(part :: any).CollisionFidelity.Name}`, false, COLOR_NEUTRAL })
	else
		if part ~= nil then
			-- the target was deleted from under the plugin
			target = nil
			cached = nil
			if preview_enabled:get() then
				preview_enabled:set(false)
				clear_preview()
			end
		end
		Iris.Text({ "No source selected", false, COLOR_NEUTRAL })
	end

	Iris.Separator()

	local preview_checkbox = Iris.Checkbox({ "Preview hulls" }, { isChecked = preview_enabled })
	if preview_checkbox.checked() then
		if target == nil then
			preview_enabled:set(false)
			set_status("Nothing selected to preview", COLOR_BAD)
		elseif busy then
			preview_enabled:set(false)
			set_status("Still working on the previous request", COLOR_WARN)
		else
			set_status("Extracting...", COLOR_NEUTRAL)
			run(target :: BasePart, run_preview)
		end
	elseif preview_checkbox.unchecked() then
		clear_preview()
	end

	if Iris.Button({ "Export" }).clicked() then
		if target == nil then
			set_status("Nothing selected to export", COLOR_BAD)
		elseif busy then
			set_status("Still working on the previous request", COLOR_WARN)
		else
			set_status("Extracting...", COLOR_NEUTRAL)
			run(target :: BasePart, run_export)
		end
	end

	Iris.Separator()
	Iris.Text({ status_text, true, status_color })

	Iris.End()
end)

plugin.Unloading:Connect(function()
	clear_preview()
	Iris.Shutdown()
end)