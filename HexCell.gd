"""
	A single cell of a hexagonal grid.
	
	There are many ways to orient a hex grid, this library was written
	with the following assumptions:
	
	* The hexes use a flat-topped orientation;
	* Axial coordinates use +x => NE; +y => N;
	* Offset coords have odd rows shifted up half a step.
	
	Using x,y instead of the reference's preferred x,z for axial coords makes
	following along with the reference a little more tricky, but is less confusing
	when using Godot's Vector2(x, y) objects.
	
	
	## Usage:
	
	#### var cube_coords; var axial_coords; var offset_coords

		Cube coordinates are used internally as the canonical representation, but
		both axial and offset coordinates can be read and modified through these
		properties.
	
	#### func get_adjacent(direction)
	
		Returns the neighbouring HexCell in the given direction.
		
		The direction should be one of the DIR_N, DIR_NE, DIR_SE, DIR_S, DIR_SW, or
		DIR_NW constants provided by the HexCell class.
	
	#### func get_all_adjacent()
	
		Returns an array of the six HexCell instances neighbouring this one.
	
	#### func get_all_within(distance)
	
		Returns an array of all the HexCells within the given number of steps,
		including the current hex.
	
	#### func get_ring(distance)
	
		Returns an array of all the HexCells at the given distance from the current.
	
	#### func distance_to(target)
	
		Returns the number of hops needed to get from this hex to the given target.
		
		The target can be supplied as either a HexCell instance, cube or axial
		coordinates.
	
	#### func line_to(target)
	
		Returns an array of all the hexes crossed when drawing a straight line
		between this hex and another.
		
		The target can be supplied as either a HexCell instance, cube or axial
		coordinates.
		
		The items in the array will be in the order of traversal, and include both
		the start (current) hex, as well as the final target.

"""
extends Resource
class_name HexCell
#warning-ignore-all:unused_class_variable

# Directions of neighbouring cells
const DIR_N = Vector3(0, 1, -1)
const DIR_NE = Vector3(1, 0, -1)
const DIR_SE = Vector3(1, -1, 0)
const DIR_S = Vector3(0, -1, 1)
const DIR_SW = Vector3(-1, 0, 1)
const DIR_NW = Vector3(-1, 1, 0)
const DIR_ALL = [DIR_N, DIR_NE, DIR_SE, DIR_S, DIR_SW, DIR_NW]


# Cube coords are canonical
var cube_coords: Vector3 = Vector3(0, 0, 0) setget set_cube_coords, get_cube_coords
# but other coord systems can be used
var axial_coords: Vector2 setget set_axial_coords, get_axial_coords
var offset_coords: Vector2 setget set_offset_coords, get_offset_coords


func _init(coords=null) -> void:
	# HexCells can be created with coordinates
	if coords:
		self.cube_coords = obj_to_coords(coords)

func new_hex(coords):
	# Returns a new HexCell instance
	return get_script().new(coords)

"""
	Handle coordinate access and conversion
"""
func obj_to_coords(val):
	# Returns suitable cube coordinates for the given object
	# The given object can an be one of:
	# * Vector3 of standard cube coords;
	# * Vector2 of offset coords;
	# * HexCell instance
	# Any other type of value will return null
	#
	# NB that axial coords are NOT supported, as they are
	# indistinguishable from offset coords.
	
	if typeof(val) == TYPE_VECTOR3:
		return val
	elif typeof(val) == TYPE_VECTOR2:
		return offset_to_cube_coords(val)
	elif typeof(val) == TYPE_OBJECT and val.has_method("get_cube_coords"):
		return val.get_cube_coords()
	# Fall through to nothing
	return
	
func axial_to_cube_coords(val) -> Vector3:
	# Returns the Vector3 cube coordinates for an axial Vector2
	var x = val.x
	var y = val.y
	return Vector3(x, y, -x - y)
	
func offset_to_cube_coords(val) -> Vector3:
	# Returns the Vector3 cube coordinates for an offset Vector2
	var x = int(val.x)
	var z = int(val.y) - (x - (x & 1)) / 2
	var y = -x-z
	return Vector3(x, y, z)
	
func round_coords(val) -> Vector3:
	# Rounds floaty coordinate to the nearest whole number cube coords
	if typeof(val) == TYPE_VECTOR2:
		val = axial_to_cube_coords(val)
	
	# Straight round them
	var rounded: Vector3 = Vector3(round(val.x), round(val.y), round(val.z))
	
	# But recalculate the one with the largest diff so that x+y+z=0
	var diffs = (rounded - val).abs()
	if diffs.x > diffs.y and diffs.x > diffs.z:
		rounded.x = -rounded.y - rounded.z
	elif diffs.y > diffs.z:
		rounded.y = -rounded.x - rounded.z
	else:
		rounded.z = -rounded.x - rounded.y
	
	return rounded
	

func get_cube_coords() -> Vector3:
	# Returns a Vector3 of the cube coordinates
	return cube_coords
	
func set_cube_coords(val) -> void:
	# Sets the position from a Vector3 of cube coordinates
	if abs(val.x + val.y + val.z) > 0.0001:
		print("WARNING: Invalid cube coordinates for hex (x+y+z!=0): ", val)
		return
	cube_coords = round_coords(val)
	
func get_axial_coords() -> Vector2:
	# Returns a Vector2 of the axial coordinates
	return Vector2(cube_coords.x, cube_coords.y)
	
func set_axial_coords(val) -> void:
	# Sets position from a Vector2 of axial coordinates
	set_cube_coords(axial_to_cube_coords(val))
	
func get_offset_coords() -> Vector2:
	# Returns a Vector2 of the offset coordinates
	var x = int(cube_coords.x)
	var z = int(cube_coords.z)
	var y = z + (x - (x & 1)) / 2
	return Vector2(x, y)
	
func set_offset_coords(val) -> void:
	# Sets position from a Vector2 of offset coordinates
	var x = int(val.x)
	var y = int(val.y)
	var cube_y = y - (x - (x & 1)) / 2
	self.set_axial_coords(Vector2(x, cube_y))
	

"""
	Finding our neighbours
"""
func get_adjacent(dir) -> HexCell:
	# Returns a HexCell instance for the given direction from this.
	# Intended for one of the DIR_* consts, but really any Vector2 or x+y+z==0 Vector3 will do.
	if typeof(dir) == TYPE_VECTOR2:
		dir = axial_to_cube_coords(dir)
	return new_hex(self.cube_coords + dir)
	
func get_all_adjacent() -> Array:
	# Returns an array of HexCell instances representing adjacent locations
	var cells: Array = Array()
	for coord in DIR_ALL:
		cells.append(new_hex(self.cube_coords + coord))
	return cells
	
func get_all_within(distance) -> Array:
	# Returns an array of all HexCell instances within the given distance
	var cells: Array = Array()
	for dx in range(-distance, distance+1):
		for dy in range(max(-distance, -distance - dx), min(distance, distance - dx) + 1):
			cells.append(new_hex(self.axial_coords + Vector2(dx, dy)))
	return cells
	
func get_ring(distance) -> Array:
	# Returns an array of all HexCell instances at the given distance
	if distance < 1:
		return [new_hex(self.cube_coords)]
	# Start at the top (+y) and walk in a clockwise circle
	var cells: Array = Array()
	var current = new_hex(self.cube_coords + (DIR_N * distance))
	for dir in [DIR_SE, DIR_S, DIR_SW, DIR_NW, DIR_N, DIR_NE]:
		for _step in range(distance):
			cells.append(current)
			current = current.get_adjacent(dir)
	return cells
	
func distance_to(target) -> int:
	# Returns the number of hops from this hex to another
	# Can be passed cube or axial coords, or another HexCell instance
	target = obj_to_coords(target)
	return int((
			abs(cube_coords.x - target.x)
			+ abs(cube_coords.y - target.y)
			+ abs(cube_coords.z - target.z)
			) / 2)
	
func line_to(target) -> Array:
	# Returns an array of HexCell instances representing
	# a straight path from here to the target, including both ends
	target = obj_to_coords(target)
	# End of our lerp is nudged so it never lands exactly on an edge
	var nudged_target = target + Vector3(1e-6, 2e-6, -3e-6)
	var steps = distance_to(target)
	var path: Array = []
	for dist in range(steps):
		var lerped = cube_coords.linear_interpolate(nudged_target, float(dist) / steps)
		path.append(new_hex(round_coords(lerped)))
	path.append(new_hex(target))
	return path
	
