extends Node

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

	if Input.is_action_just_pressed("reset"):
		global.reset_scene()

func instance_scene_on_main(scene, position):
	var main = get_tree().current_scene
	var instance = scene.instance()
	main.add_child(instance)
	instance.global_position = position
	return instance

func add_on_main(entity, position):
	var main = get_tree().current_scene
	main.add_child(entity)
	entity.global_position = position

func reset_scene():
	get_tree().call_group("instanced", "queue_free")
	get_tree().reload_current_scene()
		
func change_scene(scene: String):
	get_tree().call_group("instanced", "queue_free")
	get_tree().change_scene(scene)
