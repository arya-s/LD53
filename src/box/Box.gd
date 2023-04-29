extends KinematicBody2D

export(int) var GRAVITY = 900
export(int) var DAMPING = 0.7
export(int) var RUN_ACCELERATION = 1000
export(int) var RUN_FRICTION = 400
export(int) var RUN_MAX_SPEED = 90
export(int) var JUMP_FORCE = -105
export(int) var MAX_SPEED = 400

var held := false
var motion = Vector2.ZERO
var facing = 0

func _physics_process(delta):
	if held:
		return
		
	facing = sign(motion.x)
	
	apply_horizontal_force(delta)
	apply_vertical_force(delta)

	var collision = move_and_collide(motion * delta)
	if collision:
		var velocity = collision.remainder.bounce(collision.normal)
		motion = motion.bounce(collision.normal) * DAMPING
		move_and_collide(velocity * delta)

		
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
	set_collision_layer_bit(1, false)
	set_collision_mask_bit(1, false)
	
func throw(impulse = Vector2.ZERO):
	if not held:
		return
		
	held = false

#	motion += impulse
	motion.x += sign(impulse.x) * 300
	motion.y += JUMP_FORCE
	set_collision_layer_bit(1, true)
	set_collision_mask_bit(1, true)
	
