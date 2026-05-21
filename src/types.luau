export type Shape = {
	type: number,
	convex_radius: number
}

export type BoxShape = Shape & {
	half_extents: Vector3
}

export type SphereShape = Shape & {
	radius: number
}

export type CapsuleShape = Shape & {
	radius: number,
	half_height: number
}

export type CylinderShape = Shape & {
	radius: number,
	half_height: number
}

export type WedgeShape = Shape & {
	half_extents: Vector3,
	vertices: {Vector3}
}

export type CornerWedgeShape = Shape & {
	half_extents: Vector3,
	vertices: {Vector3}
}

export type MeshShape = Shape & {
	part: MeshPart
}

export type Support<T = Shape> = (shape: T, direction: Vector3) -> Vector3

return {}