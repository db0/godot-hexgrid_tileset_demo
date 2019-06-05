extends TileMap

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var HexGrid = preload("./HexGrid.gd").new()

# Called when the node enters the scene tree for the first time.
func _ready():
	HexGrid.hex_scale = Vector2(57.4, 56.7) # Scale found via trial and error :)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _unhandled_input(event):
	# A simple code to show how to you can manipulate hexes using the mouse.
	# left-click converts to water, right-click, to earth
	var relative_pos = $"HexGrid/Area2D".transform.affine_inverse() * event.position
	var hexCell = HexGrid.get_hex_at(relative_pos)
	if event.is_action_pressed("ui_select"): 
		self.set_cellv(hexCell.offset_coords, 19)
	elif event.is_action_pressed("ui_cancel"): 
		self.set_cellv(hexCell.offset_coords, 0)