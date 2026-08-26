extends Area2D
#commented because i realized i can just put it in the panel.gd...


#@onready var video_stream_player: VideoStreamPlayer = $"../CanvasLayer/VideoStreamPlayer"
#@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
#var played := false
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#canvas_layer.hide()
	#video_stream_player.finished.connect(_on_video_finished)
#
#func _on_body_entered(body: Node2D) -> void:
	#if played or not (body is Player):
		#return	
	#played = true
	#canvas_layer.show()
	#video_stream_player.play()
	#print("video on")
	#
	#Global.call_deferred("set_state", Global.State.CUTSCENE)
#
#func _on_video_finished() -> void:
	#canvas_layer.hide()
	#Global.call_deferred("set_state", Global.State.PLAYING)
