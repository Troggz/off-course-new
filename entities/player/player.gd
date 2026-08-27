class_name Player
extends Orb

@export var max_speed := 600

@export_group("Orb Properties")
@export var rotation_factor: float = 0.95
@export var trajectory_steps: int = 96
@export var trajectory_step_size: float = 1.0 / 60.0
@export var trajectory_line_steps: int = 4
@export var unlatched_gravitation: float = 0.15
@export var unlatching_boost: float = 1.1
@export var unlatching_time: float = 2.0
@export var arcs: int = 12
@export var arc_divisions: int = 8

@export_group("Health Properties")
# Related to hurtbox
@export var invulnerable_time: float = 3 # Invulnerability time in seconds
@export var hurt_radius: float = 9 # Length of the raycast
@export var point_count: int = 16 # Precision of the raycast, more points = more precise redirection (but potentially more buggy)
@export var Can_NWSE: bool # Determines whether the player can be redirected in true north, west, etc.
# Set "Can_NWSE" to true if "point_count" = 4
@export var lives: int = 3
@export var knockback_type: int
@export var knockback_multiplier = 1.5 # Bigger multi = Bigger reaction to hits
@export var knockback_speed = 10

# Related to dash mechanics
@export_group("Dash Properties")
@export var dash_type: int # 1 = simple dash, 2 = orbit dash
@export var dash_application: int # 1 = multiply speed, 2 = replace speed with dash speed
@export var dash_multiplier: float
@export var dash_speed: float
@export var dash_cooldown: float = 3.0 # Time taken before dash is available again
@export_subgroup("For Dash Type 2")
@export var dash_orbit_time: float = 3.0 # Time taken for arrow to fully orbit the player
@export var slow_application: int # 1 = use multiplier, 2 = replace speed with slow speed
@export var slow_multiplier: float = 0.90 # Multiplier for slowing down player during dash moment
@export var slow_speed: float = 5 # Slow Speed when player charging up a dash

@export_group("Wall Break Properties")
@export var break_speed: int
@export var break_time: float = 0.05

@onready var trajectory_probe: Orb = $TrajectoryProbe

var unlatched_trajlines := []
var latched_trajlines := []
var dead := false

var invulnerable := false
var can_dash := true
var circle: Tween
var latchable := true
var old_velocity : float

var in_station := false
var current_station : Orb = null

var spritearray : Array[DiffSprite]
var fade: Tween
var active_fades: Array[Tween] = []

@export_group("Trail Properties")
@export var trail_interval: float = 0.1
var trail_timer := 0.0

func _ready() -> void:
	if Global.lupin == 3:
		$Sprites/Lupin.play("third")

	for trajlines in [unlatched_trajlines, latched_trajlines]:
		for i in range(trajectory_line_steps, trajectory_steps, trajectory_line_steps * 2):
			var line := Line2D.new()
			add_child(line)
			trajlines.append(line)
			
	SetupSprites()

func SetupSprites() -> void:
	
	for i in 10:
		var diff : DiffSprite = DiffSprite.new()
		
		#var back : Sprite2D = $Sprites/Back.duplicate()
		#var lupin : AnimatedSprite2D = $Sprites/Lupin.duplicate()
		#var front : AnimatedSprite2D = $Sprites/Front.duplicate()
		
		diff.back = $Sprites/Back.duplicate()
		diff.lupin = $Sprites/Lupin.duplicate()
		diff.front = $Sprites/Front.duplicate()
		
		diff.lupin.stop()
		diff.front.stop()
		diff.lupin.z_index = 0
		diff.front.z_index = 0
		
		diff.back.modulate.a = 0
		diff.lupin.modulate.a = 0
		diff.front.modulate.a = 0
		get_tree().root.add_child.call_deferred(diff.back)
		get_tree().root.add_child.call_deferred(diff.lupin)
		get_tree().root.add_child.call_deferred(diff.front)
		spritearray.append(diff)
		

var latch_time := 0.0
var spritebunch : DiffSprite = DiffSprite.new()
func _process(delta: float) -> void:
	
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	
	#print(linear_velocity.normalized())
	#print(linear_velocity.length())
	#print(linear_velocity)
	
	super(delta)
	handle_rotation(delta)

	# Because 7 8 9
	if Global.lupin == 7:
		$Sprites/Lupin.scale = Vector2(1.45, 1.45)

	clear_arcs()
	if latchable:
		draw_trajectories()
		draw_arcs()

		if check_collisions([trajectory_probe]):
			pass 
			#die.emit()
		if Input.is_action_just_pressed("latch"):
			latched = true
			latch_time = time
			
			#$DangerArea.monitoring = true

			# var strength := gravitate().length() / 18.0
			$LatchAudio.volume_db = 10.0 # log(strength) * 3.5
			$LatchAudio.pitch_scale = randf_range(0.95, 1.20)
			$LatchAudio.play()
			$Sprites/LatchSmoke.emitting = true
			$Sprites/Front.modulate = Color(1.0, 0.0, 0.0)
			$Sprites/Back.modulate = Color(1.0, 0.0, 0.0)
		if Input.is_action_just_released("latch"):
			var boost := get_unlatch_boost()
			#print("boost ", boost)
			latched = false
			#$DangerArea.monitoring = false
			linear_velocity *= boost
			
			unlatch_appearence()
	else:
		latched = false
		clear_arcs()
		
	if Input.is_action_just_pressed("dash") && latched == false:
		if in_station == true:
			in_station = false
			
			latchable = true
			for trajlines in [latched_trajlines, unlatched_trajlines]:
				for line in trajlines:
					line.show()
			
			player_direction($Arrow.rotation, 3)
			circle.kill()
			circle = null
			$Arrow.rotation = 0
			current_station = null
		
		elif dash_type == 1 && can_dash == true:
			can_dash = false
			dash_processor(dash_application)
			await get_tree().create_timer(dash_cooldown, true, false, false).timeout
			can_dash = true
			
		elif dash_type == 2 && can_dash == true:
			if circle == null:
				gravity_switch(false)
				if slow_application == 1:
					linear_velocity *= slow_multiplier
				elif slow_application == 2:
					old_velocity = linear_velocity.length()
					linear_velocity = linear_velocity.normalized() * slow_speed
				circle = create_tween()
				circle.tween_property($Arrow, "rotation", deg_to_rad(360), dash_orbit_time)
				circle.finished.connect(_on_orbit_finished)
					
			else:
				if circle.is_running():
					can_dash = false
					circle.pause()
					
					if slow_application == 1:
						linear_velocity /= slow_multiplier
					elif slow_application == 2:
						linear_velocity = linear_velocity.normalized() * old_velocity
						
					player_direction($Arrow.rotation, dash_application)
					$Arrow.rotation = 0
					circle.kill()
					gravity_switch(true)
					circle = null
					await get_tree().create_timer(dash_cooldown, true, false, false).timeout
					can_dash = true
					
	# Code for dash_type 3
	elif Input.is_action_just_pressed("up"):
		third_dash(deg_to_rad(270))
	elif Input.is_action_just_pressed("down"):
		third_dash(deg_to_rad(90))
	elif Input.is_action_just_pressed("left"):
		third_dash(deg_to_rad(180))
	elif Input.is_action_just_pressed("right"):
		third_dash(deg_to_rad(0))
	
	#if (get_tree().get_frame() % 6) == 0:
		#print
		
	trail_timer -= delta
	if trail_timer <= 0.0:
		trail_timer = trail_interval
		
		if spritearray.is_empty() == false:
			#print(spritearray)
			#print("stes")
			#var spritebunch : DiffSprite = DiffSprite.new()
			
			spritebunch = spritearray.pop_front() as DiffSprite
			spritebunch.back.visible = true
			spritebunch.lupin.visible = true
			spritebunch.front.visible = true
			
			spritebunch.back.rotation = $Sprites.rotation
			spritebunch.lupin.rotation = $Sprites.rotation
			spritebunch.front.rotation = $Sprites.rotation
			#print(spritebunch.back)
			
			spritebunch.lupin.animation = $Sprites/Lupin.animation
			spritebunch.lupin.frame = $Sprites/Lupin.frame
			spritebunch.front.animation = $Sprites/Front.animation
			spritebunch.front.frame = $Sprites/Front.frame
		
			spritebunch.back.global_position = global_position #+ spritebunch.back.position
			spritebunch.lupin.global_position = global_position #+ spritebunch.lupin.position
			spritebunch.front.global_position = global_position #+ spritebunch.front.position
			
			if linear_velocity.length() > 250:
				fade = get_tree().create_tween()
				fade.tween_method(adjust_alpha.bind(spritebunch), 0.5, 0.0, 0.5)
			
			spritearray.append(spritebunch)
	#else:
		#trail_timer = 0.0
	
	#if linear_velocity.length() > 100:
		##if (get_tree().get_frame() % 6) == 0:
		#if true:
			##print("test")
			#if spritearray.is_empty() == false:
				##print("stes")
				##var spritebunch : DiffSprite = DiffSprite.new()
				#
				#spritebunch = spritearray.pop_front() as DiffSprite
				#spritebunch.back.visible = true
				#spritebunch.lupin.visible = true
				#spritebunch.front.visible = true
				#
				#spritebunch.back.rotation = $Sprites.rotation
				#spritebunch.lupin.rotation = $Sprites.rotation
				#spritebunch.front.rotation = $Sprites.rotation
				##print(spritebunch.back)
				#
				#spritebunch.lupin.animation = $Sprites/Lupin.animation
				#spritebunch.lupin.frame = $Sprites/Lupin.frame
				#spritebunch.front.animation = $Sprites/Front.animation
				#spritebunch.front.frame = $Sprites/Front.frame
				#
				#spritebunch.back.global_position = global_position #+ spritebunch.back.position
				#spritebunch.lupin.global_position = global_position #+ spritebunch.lupin.position
				#spritebunch.front.global_position = global_position #+ spritebunch.front.position
				#
				##spritebunch.back.modulate.a = 1
				##spritebunch.lupin.modulate.a = 1
				##spritebunch.front.modulate.a = 1
				#
				##var fade = get_tree().create_tween()
				##fade.set_parallel(true)
				##fade.tween_property(spritebunch.back, "modulate:a", 0.0, 0.5)
				##fade.tween_property(spritebunch.lupin, "modulate:a", 0.0, 0.5)
				##fade.tween_property(spritebunch.front, "modulate:a", 0.0, 0.5)
				#
				#fade = get_tree().create_tween()
				#active_fades.append(fade)
				#fade.tween_method(adjust_alpha.bind(spritebunch), 0.5, 0.0, 0.5)
				#fade.finished.connect(func(): active_fades.erase(fade))
				#
				##print(spritebunch.back.global_position)
				#
				##await get_tree().create_timer(1.0).timeout
				#spritearray.append(spritebunch)
	#else:
		#for i in active_fades:
			#if i.is_valid():
				#i.kill()
		#active_fades.clear()
		#
		##if fade && fade.is_valid() && fade.is_playing():
			##fade.kill()
		#
		#for i in spritearray:
			#i.back.modulate.a = 0
			#i.lupin.modulate.a = 0
			#i.front.modulate.a = 0
			#
			#i.back.visible = false
			#i.lupin.visible = false
			#i.front.visible = false

func adjust_alpha(value: float, spritebunch: DiffSprite):
	if is_instance_valid(spritebunch.back):
		spritebunch.back.modulate.a = value
	if is_instance_valid(spritebunch.lupin):
		spritebunch.lupin.modulate.a = value
	if is_instance_valid(spritebunch.front):
		spritebunch.front.modulate.a = value

func _on_orbit_finished() -> void:
	can_dash = false
	circle.kill()
	gravity_switch(true)
	circle = null
	$Arrow.rotation = 0
	
	if slow_application == 1:
		linear_velocity /= slow_multiplier
	elif slow_application == 2:
		linear_velocity = linear_velocity.normalized() * old_velocity
		
	await get_tree().create_timer(dash_cooldown, true, false, false).timeout
	can_dash = true

func interrupt_dash_2() -> void:
	if dash_type == 2 && circle != null:
		if circle.is_running():
			circle.kill()
			circle = null
			$Arrow.rotation = 0

func third_dash(rad: float) -> void:
	if dash_type == 3 && can_dash == true:
		can_dash = false
		player_direction(rad, dash_application)
		await get_tree().create_timer(dash_cooldown, true, false, false).timeout
		can_dash = true

# Apply a direction on the player depending on given rotation
func player_direction(rad: float, dash_apply: int) -> void:
	linear_velocity = Vector2(cos(rad), sin(rad)).normalized()
	dash_processor(dash_apply)

# Apply the dash boost on player and what type of boost
func dash_processor(type: int) -> void:
	if type == 1: # Current Speed is multiplied
		linear_velocity *= dash_multiplier
	elif type == 2: # Replace current speed with dash speed
		linear_velocity = linear_velocity.normalized() * dash_speed
	elif type == 3: # For station dash speed
		linear_velocity = linear_velocity.normalized() * current_station.station_speed
	$Sprites/BoostSmoke.emitting = true

func unlatch_appearence() -> void:
	if not is_inside_tree():
		return
		
	var strength := linear_velocity.length() / 32.0
	$DelatchAudio.volume_db = log(strength) * 5.0 - 5.0
	$DelatchAudio.play()
	$Sprites/DelatchSmoke.emitting = true
	$Sprites/Front.modulate = Color(1.0, 1.0, 1.0)
	$Sprites/Back.modulate = Color(1.0, 1.0, 1.0)

func gravity_switch(switch: bool) -> void:
	if switch == true:
		active = true
		latchable = true
		for trajlines in [latched_trajlines, unlatched_trajlines]:
			for line in trajlines:
				line.show()
	else:
		active = false
		latchable = false
		for trajlines in [latched_trajlines, unlatched_trajlines]:
			for line in trajlines:
				line.hide()

func handle_rotation(delta: float) -> void:
	var rot := atan2(linear_velocity.y, linear_velocity.x)
	$Sprites.rotation = lerp_angle($Sprites.rotation, rot, rotation_factor * delta)


func get_unlatch_boost() -> float:
	if not latched:
		return 1.0

	var time_latched := clampf(time - latch_time, 0.0, unlatching_time)
	var boost := lerpf(1.0, unlatching_boost, time_latched / unlatching_time)
	return boost ** 2


static func calc_latch(force: Vector2, velocity: Vector2, latching: bool, unlatched_grav: float) -> Vector2:
	if latching:
		return force
	else:
		var dotted := force.normalized().dot(velocity.normalized())
		if dotted > 0:
			return force * unlatched_grav * dotted * 3
		else:
			return Vector2(0.0, 0.0)


func gravitate(exclusions: Array = []) -> Vector2:
	if in_station == true:
		var strength: float = 500
		var damping: float = 50
			
		var to_target = current_station.global_position - global_position
		var forcee = to_target * strength - linear_velocity * damping
		#print(forcee)
		return(forcee)
	
	return calc_latch(super (exclusions + [trajectory_probe]), linear_velocity, latched, unlatched_gravitation)

signal bounced(impact_speed: float)
func bounce(normal: Vector2, incidence: Vector2) -> void:
	super (normal, incidence)
	if not dead:
		bounced.emit(incidence.length())

func map_trajectory(latching: bool) -> PackedVector2Array:
	trajectory_probe.position = Vector2(0.0, 0.0)
	trajectory_probe.mass = mass
	trajectory_probe.linear_velocity = linear_velocity * (1.0 if latching else get_unlatch_boost())
	trajectory_probe.radius = radius

	var path: PackedVector2Array = [Vector2(0.0, 0.0)]
	for _i in range(trajectory_steps):
		trajectory_probe.position += trajectory_probe.linear_velocity * trajectory_step_size

		var accel := trajectory_probe.gravitate([ self ]) / trajectory_probe.mass
		trajectory_probe.linear_velocity += calc_latch(accel, trajectory_probe.linear_velocity,
													   latching, unlatched_gravitation) * trajectory_step_size

		if trajectory_probe.check_collisions([ self ], 1.0):
			break

		path.append(trajectory_probe.position)

	return path


func draw_trajectories() -> void:
	var unlatched_traj := map_trajectory(false)
	var latched_traj := map_trajectory(true)

	for tuple in [[unlatched_trajlines, unlatched_traj, Color(1.0, 1.0, 1.0)],
				  [latched_trajlines, latched_traj, Color(1.0, 0.0, 0.0)]]:
		var lines: Array = tuple[0]
		var traj: PackedVector2Array = tuple[1]
		var tint: Color = tuple[2]

		for i in range(trajectory_line_steps, trajectory_steps, trajectory_line_steps * 2):
			@warning_ignore("integer_division")
			var j := i / (trajectory_line_steps * 2)

			lines[j].width = 1.0
			lines[j].default_color = Color(tint.r, tint.g, tint.b, 1.0 - float(i) / trajectory_steps)
			lines[j].points = traj.slice(i, i + trajectory_line_steps)


# I can't be bothered to optimize and create a recycling system for this.
var orb_arcs := []
func clear_arcs() -> void:
	for arc: Line2D in orb_arcs:
		arc.queue_free()
	orb_arcs = []


func draw_arcs() -> void:
	for orb: Orb in get_tree().get_nodes_in_group("orbs"):
		var orbit_audio: AudioStreamPlayer2D = orb.get_node("OrbitAudio")
		orbit_audio.volume_db = - INF;

		if orb == self or orb == trajectory_probe or not orb.active:
			continue

		var distance := (orb.global_position - global_position).length()
		if distance > orb.influence_radius:
			continue
		var strength := 1.0 - (distance / orb.influence_radius) ** 2.0
		orbit_audio.volume_db = log(strength) * 10.0

		if not latched:
			strength *= unlatched_gravitation * 4.0

		var normalized := (orb.global_position - global_position) / distance
		var perpendicular := normalized.rotated(PI / 2.0)
		var start := global_position + normalized * radius
		var end := orb.global_position - normalized * orb.radius

		for i in range(arcs):
			@warning_ignore("integer_division")
			var is_red := i >= arcs / 2

			var points := PackedVector2Array()
			points.resize(arc_divisions)
			for j in range(arc_divisions):
				var progress := float(j) / (arc_divisions - 1.0)
				points[j] = lerp(start, end, progress)

				var random := perpendicular * randf_range(-8.0, 8.0) * sqrt(strength) * progress ** 1.25
				points[j] += random * (0.25 if is_red else 1.0)

				points[j] -= global_position

			var arc := Line2D.new()
			arc.points = points
			arc.width = 1.0
			if is_red and latched:
				arc.default_color = Color(1.0, 0.0, 0.0)
			else:
				arc.default_color = orb.color
			arc.default_color.a = strength ** 2
			arc.z_index = -1
			add_child(arc)
			orb_arcs.append(arc)


signal die
func _on_die() -> void:
	call_deferred("do_death")


func do_death() -> void:
	latched = false
	dead = true
	gravity_switch(false)
	$CollisionShape.disabled = true
	linear_velocity = Vector2(0.0, 0.0)
	
	if fade && fade.is_valid():
		fade.kill()
	
	for diff in spritearray:
		if is_instance_valid(diff.back):
			diff.back.queue_free()
		if is_instance_valid(diff.lupin):
			diff.lupin.queue_free()
		if is_instance_valid(diff.front):
			diff.front.queue_free()
	
	spritearray.clear()
	
	$Sprites/Back.hide()
	$Sprites/Lupin.hide()
	$Arrow/ArrowSprite.hide()
	$Sprites/DelatchSmoke.emitting = true
	$Sprites/Front.modulate = Color(1.0, 1.0, 1.0)
	$Sprites/Front.play("pop")

	$DeathAudio.play()

func _on_death_audio_finished() -> void:
	queue_free()


func _on_danger_area_body_entered(_body) -> void:
	var wall = _body.get_parent()
	#linear_velocity = Vector2(0,0)
	var old_velocity_wall := linear_velocity
	#print(old_velocity_wall)
	
	if linear_velocity.length() >= break_speed:
		#linear_velocity = Vector2(0,0)
		
		#var old_velocity_wall := linear_velocity
		#linear_velocity = Vector2(0,0)
		#await get_tree().create_timer(0.025, true, false, false).timeout
		#wall.broke = true
		#await wall.break_wall()
		#wall.break_wall()
		##print("test")
		set_deferred("freeze", true)
		#await wall.break_wall()
		#wall.queue_free()
		#wall.tile_map.clear()
		#wall.broke = true
		wall.break_wall()
		await get_tree().create_timer(break_time, true, true, false).timeout
		#await get_tree().create_timer(0.025, true, false, false).timeout
		set_deferred("freeze", false)
		linear_velocity = old_velocity_wall
		##print(old_velocity_wall)
		##print(linear_velocity)
		##await get_tree().create_timer(1, true, false, false).timeout
		##print(linear_velocity)
		
	##if not dead:
		##die.emit()
	#pass

var enter: Tween

func _on_danger_area_area_entered(area: Area2D) -> void:
	if latched == false || in_station == true:
		return
	
	in_station = true
	current_station = area.get_parent()
	
	latchable = false
	for trajlines in [latched_trajlines, unlatched_trajlines]:
		for line in trajlines:
			line.hide()
	
	unlatch_appearence()
	circle = create_tween()
	circle.set_loops()
	circle.tween_property($Arrow, "rotation", deg_to_rad(360), current_station.orbit_time)
	circle.tween_callback(func(): $Arrow.rotation = deg_to_rad(0))
	

func _on_danger_area_area_exited(area: Area2D) -> void:
	if in_station == false:
		return
		
	in_station = false
	current_station = null
	#$DangerArea.monitoring = false
	
	latchable = true
	for trajlines in [latched_trajlines, unlatched_trajlines]:
		for line in trajlines:
			line.show()
	
	if circle:
		circle.kill()
		$Arrow.rotation = deg_to_rad(0)
