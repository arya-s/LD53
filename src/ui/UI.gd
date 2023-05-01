extends CanvasLayer

onready var score = $Score

func _process(delta):
	score.text = str(stats.score)
