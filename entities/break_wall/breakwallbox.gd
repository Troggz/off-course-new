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
		
		$CPUParticles2D.position = Vector2(((float(tile_size.x) + 1) * 16) / 2, ((float(tile_size.y) + 1) * 16) / 2)
		$CPUParticles2D.emission_rect_extents = Vector2((float(tile_size.x) + 1) * 8, (float(tile_size.y) + 1) * 8)
		#$IgnoreBox.position = Vector2(((float(tile_size.x) + 1) * 16) / 2, ((float(tile_size.y) + 1) * 16) / 2)
		#$IgnoreBox.shape.size = Vector2((float(tile_size.x) + 1) * 16, (float(tile_size.y) + 1) * 16)
		#print("tilex ", (float(tile_size.x) + 1) * 16)
		#print("part posx ", $CPUParticles2D.position.x)
		
		tile_map.clear()
		
		$Outline.set_point_position(1, Vector2(0, (tile_size.y + 1) * 16))
		$Outline.set_point_position(2, Vector2((tile_size.x + 1) * 16, (tile_size.y + 1) * 16))
		$Outline.set_point_position(3, Vector2((tile_size.x + 1) * 16, 0))
		
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
	$Outline.clear_points()
	$CPUParticles2D.emitting = true
	await $CPUParticles2D.finished

	if is_instance_valid(self):
		queue_free()
	#get_tree().create_timer(0.025, true, false, false).timeout
	return
	
