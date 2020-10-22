extends HexMap

func _unhandled_input(event) -> void:
	# A simple code to show how to you can manipulate hexes using the mouse.
	var mouse_offset: Vector2 = Vector2(-11,-6) 
		# Due to the compressed cells of the TileMap (in order to make the hexes appear to border each other)
		# the mouse cursor appears to move the highlight hex too early on neighboring hexes
		# This setting allows the mouse cursor to move the highlight hex a bit closer to their actual visible hex borders. 
		# In any case however, this cannot be perfect as the godot only understands square dimentions for the tilemap.
	var grid_pos: Vector2 = world_to_map(get_global_mouse_position() + mouse_offset) 
		# The tilemap position of approximately where the mouse cursos if pointing at.
	var hexCell: HexCell = get_hex_at(grid_pos)
		# We create a new hex cell object at the mouse position from which we can grab hexmap coordinates
	var hexWorldPos: Vector2 = map_to_world(hexCell.get_offset_coords())
		# The objective position on the viewport of the starting point of the tile on which this hex is drawn.
	if event.is_action_pressed("ui_select"): 
		# Left-click converts current hex to Water.
		self.set_cellv(hexCell.offset_coords, 19)
	elif event.is_action_pressed("ui_cancel"):
		# Right-click, converts everyone adjacent to current hex to Mountains
		for neighbourHex in hexCell.get_all_adjacent():
			self.set_cellv(neighbourHex.offset_coords, 1)
	$HexGrid/Area2D.update_labels(grid_pos,hexCell.get_cube_coords(),hexWorldPos)
		# Update the highlight label with the location of the hex on the godot tilemap and the hexmap
