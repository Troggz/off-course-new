@tool
extends StaticBody2D

@onready var tile_map := $TileMapLayer

#@export var tile_size: Vector2i
# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#tile_map.clear()
#
	## Draw top cells
	#tile_map.set_cell(Vector2i(0, 0), 0, Vector2i(0,0))
	#for x in range(tile_size.x):
		#print("put")
		#tile_map.set_cell(Vector2i(x, 0), 0, Vector2i(0,0))
	#tile_map.set_cell(Vector2i(tile_size.x, 0), 0, Vector2i(0,0))
	#
	## Draw middle cells (all cells between top and bottom
	#for y in range(tile_size.y):
		#tile_map.set_cell(Vector2i(0, y), 0, Vector2i(0,0))
		#for x in range(tile_size.x):
			#tile_map.set_cell(Vector2i(x,y), 0, Vector2i(0,0))
		#tile_map.set_cell(Vector2i(tile_size.x,y), 0, Vector2i(0,0))
		#
	## Draw bottom cells
	#tile_map.set_cell(Vector2i(0, tile_size.y), 0, Vector2i(0,0))
	#for x in range(tile_size.x):
		#tile_map.set_cell(Vector2i(x, tile_size.y), 0, Vector2i(0,0))
	#tile_map.set_cell(Vector2i(tile_size.x, tile_size.y), 0, Vector2i(0,0))


@export var tile_size: Vector2i:
	set(value):
		tile_size = value
		
		if not is_inside_tree():
			await ready
		
		tile_map.clear()
		
		# Draw top cells
		tile_map.set_cell(Vector2i(0, 0), 0, Vector2i(0,0))
		for x in range(tile_size.x):
			tile_map.set_cell(Vector2i(x, 0), 0, Vector2i(0,0))
		tile_map.set_cell(Vector2i(tile_size.x, 0), 0, Vector2i(0,0))
		
		# Draw middle cells (all cells between top and bottom
		for y in range(tile_size.y):
			tile_map.set_cell(Vector2i(0, y), 0, Vector2i(0,0))
			for x in range(tile_size.x):
				tile_map.set_cell(Vector2i(x,y), 0, Vector2i(0,0))
			tile_map.set_cell(Vector2i(tile_size.x,y), 0, Vector2i(0,0))
			
		# Draw bottom cells
		tile_map.set_cell(Vector2i(0, tile_size.y), 0, Vector2i(0,0))
		for x in range(tile_size.x):
			tile_map.set_cell(Vector2i(x, tile_size.y), 0, Vector2i(0,0))
		tile_map.set_cell(Vector2i(tile_size.x, tile_size.y), 0, Vector2i(0,0))

var broke := false:
	set(value):
		broke = value
		tile_map.clear()
		

func break_wall() -> void:
	tile_map.clear()
	get_tree().create_timer(0.025, true, false, false).timeout
	return
