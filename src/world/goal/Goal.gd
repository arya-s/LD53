extends Area2D

export(String, FILE, "Level_*.tscn") var next_level = ""


func _on_Goal_body_entered(body):
	if body.is_in_group("player"):
		if body.holding_box == null:
			return
			
	global.change_scene(next_level)
