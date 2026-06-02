local supports = require("./supports")
local shape_map = require("./shape_map")

return {
	[shape_map.BOX] = supports.box,
	[shape_map.SPHERE] = supports.sphere,
	[shape_map.CYLINDER] = supports.cylinder,
	[shape_map.WEDGE] = supports.wedge,
	[shape_map.CORNER_WEDGE] = supports.corner_wedge,
	[shape_map.HULL] = supports.hull,
	[shape_map.CAPSULE] = supports.capsule,
	[shape_map.ELLIPSOID] = supports.ellipsoid
}