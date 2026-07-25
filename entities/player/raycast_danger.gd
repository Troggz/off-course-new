extends Area2D

@onready var raycast = $RayCast2D
@onready var player = $".."

@export var radius: float = 9
@export var point_count: int = 8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	print("point_count = ", point_count)

func _physics_process(_delta: float) -> void:
	
	if player.invulnerable == false:
		for i in range(point_count):
			var theta = (TAU / point_count) * i
			var x = radius * cos(theta)
			var y = radius * sin(theta)
		
			raycast.set_target_position(Vector2(x,y))
			raycast.force_raycast_update()
			
			if raycast.is_colliding():
				player.invulnerable = true
				print(raycast.get_target_position())
				player.raycast_trigger(raycast.get_target_position())
