class_name Camera
extends Camera2D

@export var focus_radius: float = 96.0
@export var correction_factor: float = 2.5
@export var shake_decay: float = 6.0
@export var shake_max_offset: float = 3.0
@export var shake_falloff: float = 2.0
@export var shake_smoothing: float = 0.0


func move(delta: float, player: Player) -> void:
	var interest := get_interest(player)
	if interest != null:
		var correction := interest.global_position - global_position
		var dv := correction * correction_factor * delta
		global_position += correction if dv.length() > correction.length() else dv


func get_interest(player: Player) -> Node2D:
	var interest: Node2D = null
	for orb: Orb in get_tree().get_nodes_in_group("orbs"):
		if orb in get_tree().get_nodes_in_group("player") or not orb.active:
			continue

		var distance := (orb.global_position - player.global_position).length()
		if distance > focus_radius:
			continue
		if interest == null or distance < (interest.global_position - player.global_position).length():
			interest = orb

	if interest == null:
		return player
	else:
		return interest



var trauma := 0.0
func _process(delta: float) -> void:
	if trauma <= 0.0 and offset.is_zero_approx():
		return

	trauma = maxf(trauma - shake_decay * delta, 0.0)

	var target := Vector2(0.0, 0.0)
	if trauma > 0.0:
		var amount := trauma ** shake_falloff
		target = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_max_offset * amount

	if shake_smoothing <= 0.0:
		offset = target
	else:
		offset = offset.lerp(target, clampf(delta / shake_smoothing, 0.0, 1.0))

	if trauma <= 0.0 and offset.length() < 0.05:
		offset = Vector2.ZERO


func add_shake(amount: float) -> void:
	trauma = clampf(maxf(trauma, amount), 0.0, 1.0)
