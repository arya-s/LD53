extends Node

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
