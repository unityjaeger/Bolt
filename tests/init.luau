--!strict

local framework = require(script.framework)

local function run(bolt: any): number
	framework.reset()

	local specs = script.specs:GetChildren() :: {ModuleScript}
	table.sort(specs, function(a: ModuleScript, b)
		return a.Name < b.Name
	end)

	for _, spec in specs do
		local register = require(spec)
		register(framework, bolt)
	end

	return framework.run()
end

return {
	run = run,
}