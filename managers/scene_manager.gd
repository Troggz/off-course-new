extends Node


const LEVELS: Array[String] = [
	"res://levels/level_tutorial1.tscn",
	"res://levels/level_tutorial2.tscn",
	"res://levels/level_0.tscn",
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
	"res://levels/level_4.tscn",
	"res://levels/level_5.tscn",
	"res://levels/level_6.tscn",
	"res://levels/level_7.tscn",
]

const MENU := "res://entities/menu/menu.tscn"
const OPENING_COMIC := "res://entities/opening_comic/opening_comic.tscn"
const CLOSING_COMIC := "res://entities/opening_comic/closing_comic.tscn"
const THANK_YOU := "res://entities/thank_you.tscn"
const SAVE_PATH := "user://progress.cfg"

var current_lvl := -1
var max_lvl: int = 0 

func switch_scene(level: String) -> void:
	Global.set_state(Global.State.PLAYING)
	get_tree().change_scene_to_file.call_deferred(level)


func start_game() -> void:
	current_lvl = -1
	switch_scene(OPENING_COMIC)


func load_level(index: int) -> void:
	if index >= LEVELS.size():
		switch_scene(CLOSING_COMIC)
		return
	current_lvl = index
	unlock_level(index)
	switch_scene(LEVELS[index])


func next_level() -> void:
	load_level(current_lvl + 1)

func restart() -> void:
	Global.set_state(Global.State.PLAYING)
	get_tree().reload_current_scene.call_deferred()


func to_menu() -> void:
	current_lvl = -1
	switch_scene(MENU)


func to_thank_you() -> void:
	switch_scene(THANK_YOU)


func _ready() -> void:
	load_progress()


func level_total() -> int:
	return LEVELS.size()
	

func is_level_available(index: int) -> bool:
	return index <= max_lvl


func unlock_level(index: int) -> void:
	if index > max_lvl:
		max_lvl = min(index, LEVELS.size() - 1)
		save_progress()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "max_lvl", max_lvl)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		max_lvl = cfg.get_value("progress", "max_lvl", 0)
