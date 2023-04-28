extends Node

onready var player = $Player
onready var label = $UI/Label

var last_update = 0

func _process(delta):
	if last_update > 2:
		label.text = str(player.motion.x)
		last_update += 0
	else:
		last_update += delta
