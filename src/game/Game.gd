extends Node

export(String, FILE, "Level_*.tscn") var starting_level = ""

func _ready():
	VisualServer.set_default_clear_color(Color('cea3ad'))
	global.change_scene(starting_level)

func _process(_delta: float) -> void:
	
		
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

	if Input.is_action_just_pressed("reset"):
		global.reset_scene()
