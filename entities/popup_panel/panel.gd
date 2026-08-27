@tool
extends Control

@export var clips: Dictionary[String, VideoStream] = {}
@export var clip: String = ""
@export var hold_time: float = 1.0

@onready var video_stream_player: VideoStreamPlayer = $CanvasLayer/VideoStreamPlayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var played := false
var hold_timer := 0.0
var needs_release := false


func _validate_property(property: Dictionary) -> void:
	if property.name == "clip" and not clips.is_empty():
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(PackedStringArray(clips.keys()))


func _ready() -> void:
	set_process(false)
	if Engine.is_editor_hint():
		return

	if clip == "":
		push_warning("PopUpPanel (%s): no clip chosen, falling back to the scene's default stream." % name)
	elif not clips.has(clip):
		push_error("PopUpPanel (%s): no clip named \"%s\". Registered: %s" % [
			name, clip, ", ".join(PackedStringArray(clips.keys()))
		])
	else:
		video_stream_player.stream = clips[clip]

	canvas_layer.hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if played or not (body is Player):
		return
	played = true
	hold_timer = 0.0
	needs_release = true
	canvas_layer.show()

	video_stream_player.play()
	_play_animation()
	set_process(true)

	Global.call_deferred("set_state", Global.State.CUTSCENE)


func _play_animation() -> void:
	if clip == "" or not animation_player.has_animation(clip):
		if clip != "":
			push_warning("PopUpPanel (%s): clip \"%s\" has no animation of that name." % [name, clip])
		return
	animation_player.play(clip)


func _process(delta: float) -> void:
	if not Input.is_action_pressed("latch"):
		hold_timer = 0.0
		needs_release = false
		return
	if needs_release:
		return

	hold_timer += delta
	if hold_timer >= hold_time:
		_close()


func _close() -> void:
	set_process(false)
	video_stream_player.stop()
	animation_player.stop()
	canvas_layer.hide()
	Global.call_deferred("set_state", Global.State.PLAYING)
