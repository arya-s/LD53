extends KinematicBody2D

export(int) var GRAVITY = 900
export(int) var DAMPING = 0.7
export(int) var RUN_ACCELERATION = 100
export(int) var RUN_FRICTION = 400
export(int) var RUN_MAX_SPEED = 90
export(int) var JUMP_FORCE = -65
export(int) var MAX_SPEED = 400


onready var landing_audio = $LandingAudio

var held = false
var motion = Vector2.ZERO
var facing = 0
var was_on_floor = false

func _physics_process(delta):
	if held:
		return
		
	was_on_floor = _is_on_floor()
		
	if test_move(get_transform(), Vector2.DOWN):
		set_collision_mask_bit(0, true)
		set_collision_mask_bit(1, true)
		set_collision_layer_bit(2, true)


	facing = sign(motion.x)
	
	apply_horizontal_force(delta)
	apply_vertical_force(delta)

	var collision = move_and_collide(motion * delta)
	if collision:
		var velocity = collision.remainder.bounce(collision.normal)
		motion = motion.bounce(collision.normal) * DAMPING
		
		if collision.collider is StaticBody2D:
			velocity += collision.collider.constant_linear_velocity
		
		var rest_collision = move_and_collide(velocity * delta)
		if rest_collision and rest_collision.collider is StaticBody2D:
			velocity += collision.collider.constant_linear_velocity
	
	if hit_wall(-1) or hit_wall(1) or (not was_on_floor and _is_on_floor()):
		landing_audio.play()
					
func _is_on_floor():
	return test_move(get_transform(), Vector2.DOWN)
	
func hit_wall(direction: int):
	var collision = move_and_collide(Vector2(direction, 0), true, true, true)
	return collision and not collision.collider.is_in_group("player") and not collision.collider is StaticBody2D

func apply_horizontal_force(delta: float) -> void:
	motion.x = lerp(motion.x, 0, (RUN_MAX_SPEED / RUN_FRICTION))
	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

func apply_vertical_force(delta: float) -> void:
	if not is_on_floor():
		motion.y = move_toward(motion.y, 160, GRAVITY * delta)

func pickup():
	if held:
		return
	
	held = true
	set_collision_mask_bit(0, false)
	set_collision_mask_bit(1, false)
	set_collision_mask_bit(2, false)
	
	set_collision_layer_bit(2, false)
	
func throw(impulse = Vector2.ZERO):
	if not held:
		return
		
	held = false
	motion.x += sign(impulse.x) * 240
	motion.y += JUMP_FORCE
	set_collision_mask_bit(1, true)
