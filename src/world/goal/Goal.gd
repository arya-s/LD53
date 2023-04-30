extends Area2D

export(String, FILE, "Level_*.tscn") var next_level = ""

onready var animated_sparks = $AnimaedSparks

var done = false

func change_level(body):
	if body.is_in_group("player"):
		if body.holding_box == null:
			return
			
	if not done:
		done = true
		get_parent().goal_audio.play()
		get_parent().box.set_physics_process(false)
		get_parent().player.set_physics_process(false)
		animated_sparks.play("default")
		
		yield(get_tree().create_timer(1.0), 'timeout')

		global.change_scene(next_level)
		

func _on_Goal_body_entered(body):
	change_level(body)

func _on_Goal_area_entered(area):
	var body = area.get_parent()
	change_level(body)
