extends Control

@onready var sound: AudioStreamPlayer2D = $Sound


func _on_resume_button_pressed() -> void:
	sound.play()
	Global.resume()

func _on_restart_button_pressed() -> void:
	sound.play()
	Global.restart_level()

func _on_menu_button_pressed() -> void:
	sound.play()
	Global.go_to_menu()
