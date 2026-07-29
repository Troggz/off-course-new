extends RayCast2D

@onready var player = $".."

var react: bool = false
var detect: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("point_count = ", player.point_count)
	#print("reaction_multiplier = ", player.reaction_multiplier)
	#print("player lives = ", player.lives)
	pass

func _physics_process(_delta: float) -> void:
	
	for i in range(player.point_count):
		var theta = (TAU / player.point_count) * i
		var x = player.hurt_radius * cos(theta)
		var y = player.hurt_radius * sin(theta)
		
		if player.NWSE == false && x != player.hurt_radius && x != -player.hurt_radius && y != player.hurt_radius && y != -player.hurt_radius:
			set_target_position(Vector2(x,y))
			force_raycast_update()
			
		if is_colliding():
			if react == true:
				react = false
				if player.invulnerable == false:
					player.invulnerable = true
					player.lives -= 1
					if player.lives == 0:
						player.die.emit()
					else:
						#print("player lives = ", player.lives)
						player.linear_velocity = ((Vector2.ZERO - Vector2(x,y)).normalized()) * (player.linear_velocity * player.reaction_multiplier)
						$"../Sprites/Front".self_modulate.a = 0.25
						$"../Sprites/Back".self_modulate.a = 0.25
						$"../Sprites/Lupin".self_modulate.a = 0.25
						#print("invulnerable")
						await get_tree().create_timer(player.invulnerable_time, true, true, false).timeout
						player.invulnerable = false
						$"../Sprites/Front".self_modulate.a = 1
						$"../Sprites/Back".self_modulate.a = 1
						$"../Sprites/Lupin".self_modulate.a = 1
						#print("vulnerable")
				else:
					player.linear_velocity = (Vector2.ZERO - Vector2(x,y)).normalized() * (player.linear_velocity * 1)	
			else:
				detect = true
			
	if detect == false:
		react = true
	detect = false
	
	#if player.invulnerable == false:
		#for i in range(player.point_count):
			#var theta = (TAU / player.point_count) * i
			#var x = player.hurt_radius * cos(theta)
			#var y = player.hurt_radius * sin(theta)
		#
			#if player.NWSE == false && x != player.hurt_radius && x != -player.hurt_radius && y != player.hurt_radius && y != -player.hurt_radius:
				#set_target_position(Vector2(x,y))
				#force_raycast_update()
#
				#if is_colliding():
					#if player.invulnerable == false:
						#player.invulnerable = true
						#player.lives -= 1
						#if player.lives == 0:
							#player.die.emit()
						#else:
							#print("player lives = ", player.lives)
							#player.linear_velocity = ((Vector2.ZERO - Vector2(x,y)).normalized()) * (player.linear_velocity * player.reaction_multiplier)
							#$"../Sprites/Front".self_modulate.a = 0.25
							#$"../Sprites/Back".self_modulate.a = 0.25
							#$"../Sprites/Lupin".self_modulate.a = 0.25
							#print("invulnerable")
							#await get_tree().create_timer(player.invulnerable_time, true, true, false).timeout
							#player.invulnerable = false
							#$"../Sprites/Front".self_modulate.a = 1
							#$"../Sprites/Back".self_modulate.a = 1
							#$"../Sprites/Lupin".self_modulate.a = 1
							#print("vulnerable")
					##else:
						##player.linear_velocity = (Vector2.ZERO - Vector2(x,y)).normalized() * (player.linear_velocity * 1)
