extends Node

const PAUSE_MENU_SCENE := preload("res://ui/pause/pause_menu.tscn")

enum State { PLAYING, PAUSED, CUTSCENE }

var state: State = State.PLAYING
var _pause_menu: Control
static var lupin := 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	layer.add_child(_pause_menu)
	_pause_menu.hide()


func set_state(next: State) -> void:
	state = next
	get_tree().paused = next != State.PLAYING
	

func can_pause() -> bool:
	return state == State.PLAYING
	

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if can_pause():
		pause()
	elif state == State.PAUSED:
		resume()


func pause() -> void:
	set_state(State.PAUSED)
	_pause_menu.show()


func resume() -> void:
	_pause_menu.hide()
	set_state(State.PLAYING)
