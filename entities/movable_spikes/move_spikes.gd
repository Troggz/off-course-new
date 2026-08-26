@tool
extends StaticBody2D

@export var loop_to_start := false

@onready var tile_map := $TileMapLayer
@export var tile_size: Vector2i:
	set(value):
		tile_size = value
		
		if not is_inside_tree():
			await ready
		
		tile_map.clear()
		
		# Draw top cells
		tile_map.set_cell(Vector2i(0, 0), 2, Vector2i(22,6))
		#tile_map.set_cell(Vector2i(-1, 0), 2, Vector2i(17,1))
		tile_map.set_cell(Vector2i(0, -1), 2, Vector2i(17,1))
		for x in range(tile_size.x):
			tile_map.set_cell(Vector2i(x+1, -1), 2, Vector2i(17,1))
			tile_map.set_cell(Vector2i(x, 0), 2, Vector2i(22,6))
		tile_map.set_cell(Vector2i(tile_size.x, 0), 2, Vector2i(22,6))
		
		# Draw middle cells (all cells between top and bottom
		for y in range(tile_size.y):
			tile_map.set_cell(Vector2i(0, y), 2, Vector2i(22,6))
			tile_map.set_cell(Vector2i(-1, y), 2, Vector2i(16,2))
			for x in range(tile_size.x):
				tile_map.set_cell(Vector2i(x,y), 2, Vector2i(22,6))
			tile_map.set_cell(Vector2i(tile_size.x,y), 2, Vector2i(22,6))
			tile_map.set_cell(Vector2i(tile_size.x+1, y), 2, Vector2i(16,1))
		tile_map.set_cell(Vector2i(-1, tile_size.y), 2, Vector2i(16,2))
		tile_map.set_cell(Vector2i(tile_size.x+1, tile_size.y), 2, Vector2i(16,1))
		
		# Draw bottom cells
		tile_map.set_cell(Vector2i(0, tile_size.y), 2, Vector2i(22,6))
		for x in range(tile_size.x):
			tile_map.set_cell(Vector2i(x, tile_size.y), 2, Vector2i(22,6))
			tile_map.set_cell(Vector2i(x, tile_size.y+1), 2, Vector2i(17,2))
		tile_map.set_cell(Vector2i(tile_size.x, tile_size.y), 2, Vector2i(22,6))
		tile_map.set_cell(Vector2i(tile_size.x, tile_size.y+1), 2, Vector2i(17,2))

@export var coords_time: Array[VectorFloat] = []:
	set(value):
		for i in value.size():
			if value[i] == null:
				var vf := VectorFloat.new()
				vf.resource_local_to_scene = true
				vf.position = position
				value[i] = vf
		coords_time = value

var motion: Tween
func _ready() -> void:
	#set_notify_transform(true)
	
	if Engine.is_editor_hint():
		return
	if coords_time.is_empty():
		push_warning("coords_time array in a MoveSpikes node is empty, skipping tween")
		return
	
	motion = create_tween()
	motion.set_loops()
	motion.tween_property(self, "position", coords_time[0].position, 0)
	for i in coords_time.size():
		motion.tween_property(self, "position", coords_time[i].position, coords_time[i].seconds)
	
	if loop_to_start == true:
		motion.tween_property(self, "position", coords_time[0].position, coords_time[0].seconds)

#func _notification(_signal) -> void:
	#if NOTIFICATION_TRANSFORM_CHANGED:
		#coords_time[0].position = position
