extends Area2D

export(String, FILE, "Level_*.tscn") var next_level = ""

func change_level(body):
	if body.is_in_group("player"):
		if body.holding_box == null:
			return
			
	global.change_scene(next_level)

func _on_Goal_body_entered(body):
	change_level(body)

func _on_Goal_area_entered(area):
	var body = area.get_parent()
	change_level(body)
