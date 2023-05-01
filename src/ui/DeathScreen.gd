extends Control

onready var highscore = $Highscore
onready var score = $Score

func _process(delta):
	if Input.is_action_just_pressed("ui_select") or Input.is_action_pressed("reset"):
		global.is_playing = true
		stats.reset()
		get_tree().change_scene("res://src/world/levels/Level.tscn")
		
	highscore.text = str(stats.highscore)
	score.text = str(stats.prev_score)

func _on_PlayButton_pressed():
	global.is_playing = true
	get_tree().change_scene("res://src/world/levels/Level.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
