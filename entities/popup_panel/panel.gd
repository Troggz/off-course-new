extends Control

@export var video: VideoStream
@export var hold_time: float = 1.0

@onready var video_stream_player: VideoStreamPlayer = $CanvasLayer/VideoStreamPlayer
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var played := false
var hold_timer := 0.0
var needs_release := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if video:
		video_stream_player.stream = video
	canvas_layer.hide()
	set_process(false)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if played or not (body is Player):
		return
	played = true
	hold_timer = 0.0
	needs_release = true
	canvas_layer.show()
	video_stream_player.play()
	set_process(true)

	Global.call_deferred("set_state", Global.State.CUTSCENE)
	
	
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
	canvas_layer.hide()
	Global.call_deferred("set_state", Global.State.PLAYING)
