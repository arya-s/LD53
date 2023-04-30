extends Node

onready var player = $Player
onready var box = $Box
onready var goal_audio = $GoalAudio
onready var goal = $Goal

func _process(delta):
	if player.position.y > 200 or box.position.y > 200:
		AudioPlayer.death_audio.play()
		Controls.rumble_gamepad(Controls.RumbleStrength.Strong, Controls.RumbleLength.Short)
		global.reset_scene()
		
	if OS.is_debug_build() and Input.is_action_just_pressed("ui_skip"):
		global.change_scene(goal.next_level)
		
