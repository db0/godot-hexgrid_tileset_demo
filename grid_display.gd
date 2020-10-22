# Script to attach to a node which represents a hex grid
extends Node2D

onready var highlight = get_node("Highlight")
onready var area_coords = get_node("Highlight/AreaCoords")
onready var hex_coords = get_node("Highlight/HexCoords")

func update_labels(offset: Vector2, cube: Vector3, world_pos: Vector2) -> void:
		if area_coords != null:
			area_coords.text = str(offset)
		if hex_coords != null:
			hex_coords.text = str(cube)
		# Snap the highlight to the nearest grid cell
		if highlight != null:
			highlight.position = world_pos
