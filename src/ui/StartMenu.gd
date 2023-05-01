extends Control

export(String, FILE, "Level_*.tscn") var starting_level = ""

onready var play_button = $PlayButton

var music_bus = AudioServer.get_bus_index("Music")
var sfx_bus = AudioServer.get_bus_index("SFX")

func _ready():
	change_audio_volume(music_bus, -10)
	change_audio_volume(sfx_bus, -10)
	
	AudioPlayer.music_audio.play()
		
func _process(delta):
	if Input.is_action_just_pressed("reset") and global.in_menu:
		global.change_scene(starting_level)
		global.in_menu = false
	
func _on_PlayButton_pressed():
	global.in_menu = false
	global.change_scene(starting_level)

func change_audio_volume(bus, volume):
	AudioServer.set_bus_volume_db(bus, volume)
	
	if volume == -30:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
	
func _on_MusicSlider_value_changed(volume):
	change_audio_volume(music_bus, volume)

func _on_SFXSlider_value_changed(volume):
	change_audio_volume(sfx_bus, volume)
