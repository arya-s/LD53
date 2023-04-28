extends Node

func _process(_delta: float) -> void:
	VisualServer.set_default_clear_color(Color('0e151c'))
		
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

	if Input.is_action_just_pressed("reset"):
		print("resetting")
		get_tree().reload_current_scene()
