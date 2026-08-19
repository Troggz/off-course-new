extends TileMapLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cell_group: Array[Vector2i]
	
	var used_cells: Array[Vector2i] = get_used_cells() # Find every cell placed
	
	for cell in used_cells:
		if get_cell_atlas_coords(cell) == Vector2i(0, 0):
			cell_group.append(cell)
			
	for cell in cell_group:
		print(cell)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
