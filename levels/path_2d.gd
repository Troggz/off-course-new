class_name LevelPreview
extends Path2D

# Flies a preview camera along this path before the level starts. Runs while the
# tree is paused (Global.State.CUTSCENE), so this node needs Process Mode = Always.
# The gameplay camera is left alone, so handing back to it is a cut, not a lerp.

@export var gameplay_camera_path: NodePath = ^"../PlayerSpawn/Camera"
@export var copy_camera_limits: bool = true
@export var warmup: float = 0.15
@export var duration: float = 3.0
@export var hold: float = 0.4
@export var skippable: bool = true

@onready var gameplay_camera: Camera2D = get_node_or_null(gameplay_camera_path)
@onready var follow: PathFollow2D = $PathFollow2D
@onready var preview_camera: Camera2D = $PathFollow2D/PreviewCamera

# The screen wipe sits on a CanvasLayer, so it draws over the preview no matter
# which camera is current. Paused it would stay frozen on its first, fully black
# frame for the whole flythrough.
@onready var transition: AnimatedSprite2D = get_node_or_null("../CanvasLayer/Transition")

var elapsed := 0.0
var running := false
var warming := false


func _ready() -> void:
	if gameplay_camera == null:
		push_error("LevelPreview: no camera at %s" % gameplay_camera_path)
		set_process(false)
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
	if transition != null:
		transition.process_mode = Node.PROCESS_MODE_ALWAYS

	running = true
	# Let the level tick unpaused for a moment first, so everything that paints
	# itself in _process (orb colours, particles, parallax) is on screen before
	# the freeze. Without this the orbs sit there uncoloured for the whole tour.
	warming = warmup > 0.0
	if not warming:
		freeze_level()


func _process(delta: float) -> void:
	if not running:
		return

	if skippable and Input.is_action_just_pressed("latch"):
		finish()
		return

	elapsed += delta

	if warming:
		if elapsed >= warmup:
			warming = false
			elapsed = 0.0
			freeze_level()
		return

	follow.progress_ratio = ease(clampf(elapsed / duration, 0.0, 1.0), -1.8)

	if elapsed >= duration + hold:
		finish()


func freeze_level() -> void:
	Global.call_deferred("set_state", Global.State.CUTSCENE)


func finish() -> void:
	running = false
	warming = false
	set_process(false)
	if transition != null:
		transition.process_mode = Node.PROCESS_MODE_INHERIT
	gameplay_camera.make_current()
	Global.call_deferred("set_state", Global.State.PLAYING)
