class_name LevelPreview
extends Path2D

# Flies a preview camera along this path before the player spawns. The tree keeps
# running normally — the level just holds its spawn back until `finished` fires.
# The gameplay camera is left alone, so handing back to it is a cut, not a lerp.

signal finished

@export var gameplay_camera_path: NodePath = ^"../PlayerSpawn/Camera"
@export var copy_camera_limits: bool = true
@export var warmup: float = 0.15
@export var duration: float = 3.0
@export var hold: float = 0.4
@export var skippable: bool = true

@onready var gameplay_camera: Camera2D = get_node_or_null(gameplay_camera_path)
@onready var follow: PathFollow2D = $PathFollow2D
@onready var preview_camera: Camera2D = $PathFollow2D/PreviewCamera

var elapsed := 0.0
var running := false
var warming := false
var done := false


func _ready() -> void:
	# The node ships with every level, but a level only gets a flythrough if
	# someone actually drew a path for it. An empty curve spawns straight away.
	if curve == null or curve.point_count < 2:
		set_process(false)
		finish.call_deferred()
		return

	if gameplay_camera == null:
		push_error("LevelPreview: no camera at %s" % gameplay_camera_path)
		set_process(false)
		# Deferred, so the level has connected to `finished` before it fires —
		# otherwise a broken preview means the player never spawns at all.
		finish.call_deferred()
		return

	follow.progress_ratio = 0.0
	# One source of truth for bounds: whatever the level set on the gameplay
	# camera also bounds the flythrough.
	if copy_camera_limits:
		preview_camera.limit_left = gameplay_camera.limit_left
		preview_camera.limit_top = gameplay_camera.limit_top
		preview_camera.limit_right = gameplay_camera.limit_right
		preview_camera.limit_bottom = gameplay_camera.limit_bottom
		preview_camera.limit_smoothed = gameplay_camera.limit_smoothed
	preview_camera.make_current()

	running = true
	warming = warmup > 0.0


func _process(delta: float) -> void:
	if not running:
		return

	if skippable and Input.is_action_just_pressed("latch"):
		finish()
		return

	elapsed += delta

	# A beat on the first point of the path before the camera starts moving.
	if warming:
		if elapsed >= warmup:
			warming = false
			elapsed = 0.0
		return

	follow.progress_ratio = clampf(elapsed / duration, 0.0, 1.0)

	if elapsed >= duration + hold:
		finish()


func finish() -> void:
	if done:
		return
	done = true
	running = false
	warming = false
	set_process(false)
	if gameplay_camera != null:
		gameplay_camera.make_current()
	finished.emit()
