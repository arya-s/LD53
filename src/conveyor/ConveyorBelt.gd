extends StaticBody2D


onready var sprites = $Sprites

func _ready():
	for sprite in sprites.get_children():
		sprite.play("default", true)
