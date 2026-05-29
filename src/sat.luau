--!strict
--!native
--!optimize 2

local types = require("./types")
local constants = require("./constants")

local HUGE = constants.HUGE
local FLT_EPSILON = constants.FLT_EPSILON

local CF_IDENT = CFrame.identity

local ptws = CF_IDENT.PointToWorldSpace :: (CFrame, ...Vector3) -> ...Vector3
local vtws = CF_IDENT.VectorToWorldSpace :: (CFrame, ...Vector3) -> ...Vector3

local function box_box(cframe_a: CFrame, shape_a: types.BoxShape, cframe_b: CFrame, shape_b: types.BoxShape): (boolean, Vector3?, number?)
	local right_a, up_a, look_a = cframe_a.RightVector, cframe_a.UpVector, cframe_a.LookVector
	local right_b, up_b, look_b = cframe_b.RightVector, cframe_b.UpVector, cframe_b.LookVector
	
	local half_extents_a = shape_a.half_extents
	local half_extents_b = shape_b.half_extents
	
	local hsx_a, hsy_a, hsz_a = half_extents_a.X, half_extents_a.Y, half_extents_a.Z
	local hsx_b, hsy_b, hsz_b = half_extents_b.X, half_extents_b.Y, half_extents_b.Z
	
	local translation = cframe_b.Position - cframe_a.Position
	
	local best_axis = nil
	local best_overlap = HUGE
	
	local axis = right_a; local len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = up_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = look_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = right_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = up_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = look_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = vector.cross(right_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = vector.cross(right_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = vector.cross(right_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = vector.cross(up_b :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end

	axis = vector.cross(up_b :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end

	axis = vector.cross(up_b :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	axis = vector.cross(look_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end

	axis = vector.cross(look_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end

	axis = vector.cross(look_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(right_a :: any, axis :: any)) * hsx_a + math.abs(vector.dot(up_a :: any, axis :: any)) * hsy_a + math.abs(vector.dot(look_a :: any, axis :: any)) * hsz_a
		local rb = math.abs(vector.dot(right_b :: any, axis :: any)) * hsx_b + math.abs(vector.dot(up_b :: any, axis :: any)) * hsy_b + math.abs(vector.dot(look_b :: any, axis :: any)) * hsz_b
		local d = vector.dot(translation :: any, axis :: any)
		local overlap = ra + rb - math.abs(d)
		if overlap <= 0 then return false, nil, nil end
		if overlap < best_overlap then best_overlap = overlap; best_axis = if d < 0 then axis else -axis end
	end
	
	return true, best_axis :: any, best_overlap
end

local function box_wedge(box_cf: CFrame, box_shape: types.BoxShape, wedge_cf: CFrame, wedge_shape: types.WedgeShape): (boolean, Vector3?, number?)
	local box_right, box_up, box_look = box_cf.RightVector, box_cf.UpVector, box_cf.LookVector
	local wedge_right, wedge_up, wedge_look = wedge_cf.RightVector, wedge_cf.UpVector, wedge_cf.LookVector
	
	local half_extents_box = box_shape.half_extents
	local half_extents_wedge = wedge_shape.half_extents

	local hsx_box, hsy_box, hsz_box = half_extents_box.X, half_extents_box.Y, half_extents_box.Z

	local box_pos = box_cf.Position
	
	local vert1, vert2, vert3 = ptws(wedge_cf, unpack(wedge_shape.vertices))
	local x = -wedge_right * half_extents_wedge.X * 2
	local wedge_slope, wedge_edge = vtws(wedge_cf, wedge_shape.local_slope, wedge_shape.local_edge)
	
	local best_axis = nil
	local best_overlap = HUGE
	
	local axis = box_right; local len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = box_up; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = box_look; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_right; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_up; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_look; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_slope; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_right :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_up :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_look :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_edge :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_up :: any, wedge_right :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_up :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_look :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_edge :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_look :: any, wedge_right :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_up :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_look :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_edge :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, xn = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(x :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3) + math.min(xn, 0), math.max(p1, p2, p3) + math.max(xn, 0)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	return true, best_axis :: any, best_overlap
end

local function wedge_wedge(cframe_a: CFrame, shape_a: types.WedgeShape, cframe_b: CFrame, shape_b: types.WedgeShape): (boolean, Vector3?, number?)
	local right_a, up_a, look_a = cframe_a.RightVector, cframe_a.UpVector, cframe_a.LookVector
	local right_b, up_b, look_b = cframe_b.RightVector, cframe_b.UpVector, cframe_b.LookVector

	local half_extents_a = shape_a.half_extents
	local half_extents_b = shape_b.half_extents

	local vert1_a, vert2_a, vert3_a = ptws(cframe_a, unpack(shape_a.vertices))
	local x_a = -right_a * half_extents_a.X * 2
	local slope_a, edge_a = vtws(cframe_a, shape_a.local_slope, shape_a.local_edge)
	
	local vert1_b, vert2_b, vert3_b = ptws(cframe_b, unpack(shape_b.vertices))
	local x_b = -right_b * half_extents_b.X * 2
	local slope_b, edge_b = vtws(cframe_b, shape_b.local_slope, shape_b.local_edge)

	local best_axis = nil
	local best_overlap = HUGE

	local axis = right_a; local len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = up_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = look_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = slope_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = right_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = up_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = look_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = slope_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, edge_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(up_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, edge_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(look_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, edge_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(edge_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, edge_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, xn_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(x_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b) + math.min(xn_b, 0), math.max(p1_b, p2_b, p3_b) + math.max(xn_b, 0)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	return true, best_axis :: any, best_overlap
end

local function wedge_corner_wedge(wedge_cf: CFrame, wedge_shape: types.WedgeShape, corner_wedge_cf: CFrame, corner_wedge_shape: types.CornerWedgeShape): (boolean, Vector3?, number?)
	local right_a, up_a, look_a = wedge_cf.RightVector, wedge_cf.UpVector, wedge_cf.LookVector
	local right_b, up_b, look_b = corner_wedge_cf.RightVector, corner_wedge_cf.UpVector, corner_wedge_cf.LookVector

	local half_extents_a = wedge_shape.half_extents
	local half_extents_b = corner_wedge_shape.half_extents

	local vert1_a, vert2_a, vert3_a = ptws(wedge_cf, unpack(wedge_shape.vertices))
	local x_a = -right_a * half_extents_a.X * 2
	local slope_a, edge_a = vtws(wedge_cf, wedge_shape.local_slope, wedge_shape.local_edge)

	local vert1_b, vert2_b, vert3_b, vert4_b, vert5_b = ptws(corner_wedge_cf, unpack(corner_wedge_shape.vertices))
	local slope1_b, slope2_b = vtws(corner_wedge_cf, corner_wedge_shape.local_slope1, corner_wedge_shape.local_slope2)
	local edge1_b, edge2_b, edge3_b = vtws(corner_wedge_cf, corner_wedge_shape.local_edge1, corner_wedge_shape.local_edge2, corner_wedge_shape.local_edge3)

	local best_axis = nil
	local best_overlap = HUGE

	local axis = right_a; local len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = up_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = look_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = slope_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = right_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = up_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = look_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = slope1_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = slope2_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(right_a :: any, edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(up_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(up_a :: any, edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(look_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(look_a :: any, edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(edge_a :: any, right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(edge_a :: any, edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, xn_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(x_a :: any, axis :: any)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a) + math.min(xn_a, 0), math.max(p1_a, p2_a, p3_a) + math.max(xn_a, 0)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	return true, best_axis :: any, best_overlap
end

local function box_corner_wedge(box_cf: CFrame, box_shape: types.BoxShape, corner_wedge_cf: CFrame, corner_wedge_shape: types.CornerWedgeShape): (boolean, Vector3?, number?)
	local box_right, box_up, box_look = box_cf.RightVector, box_cf.UpVector, box_cf.LookVector
	local wedge_right, wedge_up, wedge_look = corner_wedge_cf.RightVector, corner_wedge_cf.UpVector, corner_wedge_cf.LookVector

	local half_extents_box = box_shape.half_extents
	local half_extents_wedge = corner_wedge_shape.half_extents

	local hsx_box, hsy_box, hsz_box = half_extents_box.X, half_extents_box.Y, half_extents_box.Z

	local box_pos = box_cf.Position

	local vert1, vert2, vert3, vert4, vert5 = ptws(corner_wedge_cf, unpack(corner_wedge_shape.vertices))
	local wedge_slope1, wedge_slope2 = vtws(corner_wedge_cf, corner_wedge_shape.local_slope1, corner_wedge_shape.local_slope2)
	local wedge_edge1, wedge_edge2, wedge_edge3 = vtws(corner_wedge_cf, corner_wedge_shape.local_edge1, corner_wedge_shape.local_edge2, corner_wedge_shape.local_edge3)

	local best_axis = nil
	local best_overlap = HUGE
	
	local axis = box_right; local len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = box_up; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = box_look; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_right; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_up; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_look; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_slope1; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_slope2; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_right :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_up :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_look :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_edge1 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_edge2 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_right :: any, wedge_edge3 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_up :: any, wedge_right :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_up :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_look :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_edge1 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_edge2 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_up :: any, wedge_edge3 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(box_look :: any, wedge_right :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_up :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_look :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_edge1 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_edge2 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(box_look :: any, wedge_edge3 :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local ra = math.abs(vector.dot(box_right :: any, axis :: any)) * hsx_box + math.abs(vector.dot(box_up :: any, axis :: any)) * hsy_box + math.abs(vector.dot(box_look :: any, axis :: any)) * hsz_box
		local p1, p2, p3, p4, p5 = vector.dot(vert1 :: any, axis :: any), vector.dot(vert2 :: any, axis :: any), vector.dot(vert3 :: any, axis :: any), vector.dot(vert4 :: any, axis :: any), vector.dot(vert5 :: any, axis :: any)
		local minb, maxb = math.min(p1, p2, p3, p4, p5), math.max(p1, p2, p3, p4, p5)
		local d = vector.dot(box_pos :: any, axis :: any)
		local overlap_pos, overlap_neg = (d + ra) - minb, maxb - (d - ra)
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	return true, best_axis :: any, best_overlap
end

local function corner_wedge_corner_wedge(corner_wedge_cf_a: CFrame, corner_wedge_shape_a: types.CornerWedgeShape, corner_wedge_cf_b: CFrame, corner_wedge_shape_b: types.CornerWedgeShape): (boolean, Vector3?, number?)
	local wedge_right_a, wedge_up_a, wedge_look_a = corner_wedge_cf_a.RightVector, corner_wedge_cf_a.UpVector, corner_wedge_cf_a.LookVector
	local wedge_right_b, wedge_up_b, wedge_look_b = corner_wedge_cf_b.RightVector, corner_wedge_cf_b.UpVector, corner_wedge_cf_b.LookVector

	local half_extents_wedge_a = corner_wedge_shape_a.half_extents
	local half_extents_wedge_b = corner_wedge_shape_b.half_extents

	local vert1_a, vert2_a, vert3_a, vert4_a, vert5_a = ptws(corner_wedge_cf_a, unpack(corner_wedge_shape_a.vertices))
	local wedge_slope1_a, wedge_slope2_a = vtws(corner_wedge_cf_a, corner_wedge_shape_a.local_slope1, corner_wedge_shape_a.local_slope2)
	local wedge_edge1_a, wedge_edge2_a, wedge_edge3_a = vtws(corner_wedge_cf_a, corner_wedge_shape_a.local_edge1, corner_wedge_shape_a.local_edge2, corner_wedge_shape_a.local_edge3)
	
	local vert1_b, vert2_b, vert3_b, vert4_b, vert5_b = ptws(corner_wedge_cf_b, unpack(corner_wedge_shape_b.vertices))
	local wedge_slope1_b, wedge_slope2_b = vtws(corner_wedge_cf_b, corner_wedge_shape_b.local_slope1, corner_wedge_shape_b.local_slope2)
	local wedge_edge1_b, wedge_edge2_b, wedge_edge3_b = vtws(corner_wedge_cf_b, corner_wedge_shape_b.local_edge1, corner_wedge_shape_b.local_edge2, corner_wedge_shape_b.local_edge3)
	
	local best_axis = nil
	local best_overlap = HUGE
	
	local axis = wedge_right_a; local len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_up_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_look_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_slope1_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_slope2_a; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = wedge_right_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = wedge_up_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = wedge_look_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = wedge_slope1_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = wedge_slope2_b; len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_right_a :: any, wedge_right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_right_a :: any, wedge_up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_right_a :: any, wedge_look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_right_a :: any, wedge_edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_right_a :: any, wedge_edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_right_a :: any, wedge_edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_up_a :: any, wedge_right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_up_a :: any, wedge_up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_up_a :: any, wedge_look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_up_a :: any, wedge_edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_up_a :: any, wedge_edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_up_a :: any, wedge_edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_look_a :: any, wedge_right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_look_a :: any, wedge_up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_look_a :: any, wedge_look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_look_a :: any, wedge_edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_look_a :: any, wedge_edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_look_a :: any, wedge_edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_edge1_a :: any, wedge_right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge1_a :: any, wedge_up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge1_a :: any, wedge_look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge1_a :: any, wedge_edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge1_a :: any, wedge_edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge1_a :: any, wedge_edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_edge2_a :: any, wedge_right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge2_a :: any, wedge_up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge2_a :: any, wedge_look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge2_a :: any, wedge_edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge2_a :: any, wedge_edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge2_a :: any, wedge_edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	axis = vector.cross(wedge_edge3_a :: any, wedge_right_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge3_a :: any, wedge_up_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge3_a :: any, wedge_look_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge3_a :: any, wedge_edge1_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge3_a :: any, wedge_edge2_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end

	axis = vector.cross(wedge_edge3_a :: any, wedge_edge3_b :: any); len = vector.magnitude(axis :: any); if len >= FLT_EPSILON then
		axis /= len
		local p1_a, p2_a, p3_a, p4_a, p5_a = vector.dot(vert1_a :: any, axis :: any), vector.dot(vert2_a :: any, axis :: any), vector.dot(vert3_a :: any, axis :: any), vector.dot(vert4_a :: any, axis :: any), vector.dot(vert5_a :: any, axis :: any)
		local minb_a, maxb_a = math.min(p1_a, p2_a, p3_a, p4_a, p5_a), math.max(p1_a, p2_a, p3_a, p4_a, p5_a)
		local p1_b, p2_b, p3_b, p4_b, p5_b = vector.dot(vert1_b :: any, axis :: any), vector.dot(vert2_b :: any, axis :: any), vector.dot(vert3_b :: any, axis :: any), vector.dot(vert4_b :: any, axis :: any), vector.dot(vert5_b :: any, axis :: any)
		local minb_b, maxb_b = math.min(p1_b, p2_b, p3_b, p4_b, p5_b), math.max(p1_b, p2_b, p3_b, p4_b, p5_b)
		local overlap_pos, overlap_neg = maxb_a - minb_b, maxb_b - minb_a
		if overlap_pos <= 0 or overlap_neg <= 0 then return false, nil, nil end
		local overlap = math.min(overlap_pos, overlap_neg)
		if overlap < best_overlap then best_overlap = overlap; best_axis = if overlap_pos < overlap_neg then -axis else axis end
	end
	
	return true, best_axis :: any, best_overlap
end

return {
	box_box = box_box,
	box_wedge = box_wedge,
	wedge_wedge = wedge_wedge,
	wedge_corner_wedge = wedge_corner_wedge,
	box_corner_wedge = box_corner_wedge,
	corner_wedge_corner_wedge = corner_wedge_corner_wedge
}