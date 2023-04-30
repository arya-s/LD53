extends Node

onready var player = $Player
onready var box = $Box
onready var goal_audio = $GoalAudio

func _process(delta):
	if player.position.y > 200 or box.position.y > 200:
		global.reset_scene()
