extends KinematicBody2D

enum {
	LEFT = -1,
	NEUTRAL = 0,
	RIGHT = 1
}

onready var camera = $Camera
onready var label = $Label

# timers
onready var coyote_jump_timer = $CoyoteJumpTimer
onready var variable_jump_timer = $VariableJumpTimer
onready var jump_buffer_timer = $JumpBufferTimer
onready var force_move_x_timer = $ForceMoveXTimer
onready var climb_hop_force_timer = $ClimbHopForceTimer

onready var pickup_area = $PickupArea
onready var carry_position = $PickupArea/CarryPosition
onready var grab_timer = $GrabTimer
onready var throw_position_right = $ThrowPositionRight
onready var throw_position_left = $ThrowPositionLeft

# player
onready var sprite = $Sprite
onready var jump_audio = $JumpAudio
onready var land_audio = $LandAudio
onready var animation_player = $AnimationPlayer
onready var stamina_animation_player = $StaminaAnimationPlayer
onready var collider = $Collider

export(float) var AIR_MULTIPLIER = 0.65
export(int) var GRAVITY = 900
export(int) var HALF_GRAVITY_THRESHOLD = 40
export(int) var RUN_ACCELERATION = 1000
export(int) var RUN_FRICTION = 400
export(int) var RUN_MAX_SPEED = 90
export(int) var DUCK_FRICTION = 500
export(int) var JUMP_FORCE = -105
export(int) var JUMP_HORIZONTAL_BOOST = 40
export(int) var WALL_JUMP_HORIZONTAL_BOOST = RUN_MAX_SPEED + JUMP_HORIZONTAL_BOOST
export(int) var WALL_SLIDE_START_MAX = 20
export(int) var WALL_CHECK_DISTANCE = 3
export(int) var FALL_MAX_SPEED = 160
export(int) var FALL_MAX_ACCELERATION = 300
export(float) var AUTO_JUMP_TIMER = 0.1
export(int) var UPWARD_CORNER_CORRECTION = 4
export(float) var CEILING_VARIABLE_JUMP = 0.05
export(int) var FAST_FALL_MAX_SPEED = 240
export(int) var FAST_FALL_MAX_ACCELERATION = 300
export(int) var THROW_RECOIL = 100
export(int) var GRAB_STAMINA = 110

export(int) var CLIMB_CHECK_DISTANCE = 2
export(int) var CLIMB_UP_CHECK_DISTANCE = 2
export(int) var CLIMB_UP_SPEED = -45
export(int) var CLIMB_DOWN_SPEED = 80
export(int) var CLIMB_ACCEL = 800
export(int) var CLIMB_UP_COST = 100 / 2.2
export(int) var CLIMB_STILL_COST = 100 / 10
export(int) var CLIMB_JUMP_COST = 110 / 4
export(int) var CLIMB_HOP_X = 80
export(int) var CLIMB_HOP_Y = -80


var WALL_SLIDE_TIME = 1.2

var facing = RIGHT
var force_move_x_direction = NEUTRAL
var motion = Vector2.ZERO
var max_fall = FALL_MAX_SPEED
var variable_jump_speed = 0
var was_on_floor = false
var wall_slide_dir = NEUTRAL
var wall_slide_timer = WALL_SLIDE_TIME
var last_speed_y = 0
var holding_box = null
var prev_holder = null
var holding_candidate = null

var grab_stamina = GRAB_STAMINA
var climb_dir = 0
var is_climbing = false
var is_sweating = false

func _physics_process(delta: float):
	last_speed_y = motion.y
	
	if is_on_floor():
		State.last_save_position = global_position
		grab_stamina = GRAB_STAMINA
		is_sweating = false
		stamina_animation_player.play("RESET")
	
	var input_vector = get_input_vector()
	
	# if we did a walljump this timer is set
	# if the timer is still running we take away control
	# from the player and force them into that direction
	if force_move_x_timer.time_left > 0:
		input_vector.x = force_move_x_direction
	
	update_facing(input_vector)
	apply_horizontal_force(input_vector, delta)
	apply_vertical_force(input_vector, delta)
	update_animations(input_vector)
	move(input_vector)
	update_sprite(input_vector, delta)
	
	motion = motion.limit_length(90 + 140)
	
	position.x = clamp(position.x, 4, 320 - 4)
	position.y = clamp(position.y, 8, 240)

func _input(event):
	if Input.is_action_just_pressed("throw") and grab_timer.time_left == 0:
		grab_timer.start()
		handle_box()
		
	if Input.is_action_pressed("up"):
		climb_dir = -1
	elif Input.is_action_just_released("up"):
		if Input.is_action_pressed("down"):
			climb_dir = 1
		else:
			climb_dir = 0
	
	if Input.is_action_pressed("down"):
		climb_dir = 1
	elif Input.is_action_just_released("down"):
		if Input.is_action_pressed("up"):
			climb_dir = -1
		else:
			climb_dir = 0
		
func update_facing(input_vector: Vector2) -> void:
	var direction = sign(input_vector.x)
	facing = direction if direction != 0 else facing
	sprite.flip_h = true if facing == LEFT else false
	
	pickup_area.scale.x = facing
	
func update_animations(input_vector):
	if is_climbing:
		if input_vector.y != 0:
			animation_player.play("climbing")
		else:
			animation_player.play("climbing_idle")
	else:
		if input_vector.x != 0:
			animation_player.play("run")
		else:
			animation_player.play("idle")
		
		# jumping
		if sign(motion.y) == -1:
			animation_player.play("default")

func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	return input_vector

func apply_horizontal_force(input_vector: Vector2, delta: float) -> void:
	var run_multiplier = 1.0 if is_on_floor() else AIR_MULTIPLIER
	
	if abs(motion.x) > RUN_MAX_SPEED and sign(motion.x) == input_vector.x:
		motion.x = move_toward(motion.x, input_vector.x * RUN_MAX_SPEED, RUN_FRICTION * run_multiplier * delta)
	else:
		motion.x = move_toward(motion.x, input_vector.x * RUN_MAX_SPEED, RUN_ACCELERATION * run_multiplier * delta)
	
func apply_vertical_force(input_vector: Vector2, delta: float) -> void:
	var fm = FALL_MAX_SPEED
	var ffm = FAST_FALL_MAX_SPEED
	
	# if we're pressing down, fall faster
	if input_vector.y == 1 and motion.y >= fm:
		max_fall = move_toward(max_fall, ffm, FAST_FALL_MAX_ACCELERATION * delta)
		var half = fm + (ffm - fm) * 0.5
		
		if motion.y >= half:
			var sprite_lerp = min(1, (motion.y - half) / (ffm - half))
			sprite.scale.x = lerp(1, 0.5, sprite_lerp)
			sprite.scale.y = lerp(1, 1.5, sprite_lerp)
	else:
		max_fall = move_toward(max_fall, fm, FAST_FALL_MAX_ACCELERATION * delta)
	
	if not is_on_floor():
		var maximum = max_fall
		
		if sign(motion.x) == facing and sign(input_vector.y) != 1:
			if motion.y >= 0 and wall_slide_timer > 0 and collide_check(facing):
				wall_slide_dir = facing
		
			# if we are wall sliding we want to fall a bit slower
			if wall_slide_dir != NEUTRAL:
				maximum = lerp(max_fall, WALL_SLIDE_START_MAX, wall_slide_timer / WALL_SLIDE_TIME)
	
		if (
			Input.is_action_pressed("grab") and
			can_climb_wall(facing) and
			grab_stamina > 0
		):
			if not is_grabbing_wall(facing):
				climb_hop()
				is_climbing = false
			else:
				is_climbing = true
				var target = 0
				if climb_dir == -1:
					target = CLIMB_UP_SPEED
					grab_stamina -= CLIMB_UP_COST * delta
				elif climb_dir == 1:
					target = CLIMB_DOWN_SPEED
				else:
					grab_stamina -= CLIMB_STILL_COST * delta
				
				if grab_stamina <= 20:
					Controls.rumble_gamepad(Controls.RumbleStrength.Light, Controls.RumbleLength.Short)
					stamina_animation_player.play("stamina_warning_quick")
				elif grab_stamina <= 40:
					Controls.rumble_gamepad(Controls.RumbleStrength.Light, Controls.RumbleLength.Short)
					stamina_animation_player.play("stamina_warning")
				else:
					stamina_animation_player.play("RESET")
				
				motion.y = move_toward(motion.y, target, CLIMB_ACCEL * delta)
		else:
			var fall_multiplier = 0.5 if abs(motion.y) < HALF_GRAVITY_THRESHOLD and Input.is_action_pressed("jump") else 1.0
			motion.y = move_toward(motion.y, maximum, GRAVITY * fall_multiplier * delta)
			stamina_animation_player.play("RESET")
			is_climbing = false
	
	if wall_slide_dir != NEUTRAL:
		wall_slide_timer = max(wall_slide_timer - delta, 0)
		wall_slide_dir = NEUTRAL
	
	if variable_jump_timer.time_left > 0:
		if Input.is_action_pressed("jump"):
			motion.y = min(motion.y, variable_jump_speed)
		else:
			variable_jump_timer.stop()
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_jump_timer.time_left > 0:
			jump(input_vector)
		else:
			jump_buffer_timer.start()
			
			if can_wall_jump(RIGHT):
				if facing == RIGHT and Input.is_action_pressed("grab") and grab_stamina > 0 and can_climb_wall(facing):
					climb_jump(input_vector)
				else:
					wall_jump(LEFT)
			elif can_wall_jump(LEFT):
				if facing == LEFT and Input.is_action_pressed("grab") and grab_stamina > 0 and can_climb_wall(facing):
					climb_jump(input_vector)
				else:	
					wall_jump(RIGHT)

func jump(input_vector: Vector2) -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	motion.x += input_vector.x * JUMP_HORIZONTAL_BOOST
	motion.y = JUMP_FORCE
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)
	jump_audio.play()
	
func climb_hop() -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
	
	force_move_x_direction = facing
	force_move_x_timer.start()

	motion.x = facing * CLIMB_HOP_X
	motion.y = CLIMB_HOP_Y
	
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)
	jump_audio.play()

func climb_jump(input_vector: Vector2) -> void:
	if not is_on_floor():
		grab_stamina -= CLIMB_JUMP_COST
	
	jump(input_vector)
	
	if facing == RIGHT:
		# render jump right animation
		pass
	else:
		# render jump left animation
		pass
	
func wall_jump(direction: int) -> void:
	coyote_jump_timer.stop()
	variable_jump_timer.start()
	wall_slide_timer = WALL_SLIDE_TIME
		
	if sign(motion.x) != 0:
		force_move_x_direction = direction
		force_move_x_timer.start()

	motion.x = direction * WALL_JUMP_HORIZONTAL_BOOST
	motion.y = JUMP_FORCE
	variable_jump_speed = motion.y
	
	sprite.scale = Vector2(0.6, 1.4)
	jump_audio.play()
	
func move(input_vector: Vector2) -> void:
	was_on_floor = is_on_floor()
	
	motion = move_and_slide(motion, Vector2.UP, false, 4, PI/4, false)

	# we use 1 here because landing on another kinematic body
	# and walking around has a small amount of last_speed_y left
	# thus retriggering the landing
	if not was_on_floor and is_on_floor() and last_speed_y > 1:
		var squish_amount = min(last_speed_y / FAST_FALL_MAX_SPEED, 1)
		sprite.scale.x = lerp(1, 1.5, squish_amount)
		sprite.scale.y = lerp(1, 0.4, squish_amount)
		land_audio.play()
		
		if last_speed_y > 200:
			# hard squish landing
			Controls.rumble_gamepad(Controls.RumbleStrength.Strong, Controls.RumbleLength.VeryShort)
		else:
			Controls.rumble_gamepad(Controls.RumbleStrength.Light, Controls.RumbleLength.VeryShort)
	
	if is_on_floor():
		wall_slide_timer = WALL_SLIDE_TIME
		coyote_jump_timer.start()
		
		if jump_buffer_timer.time_left > 0:
			jump_buffer_timer.stop()
			jump(input_vector)

	if is_on_ceiling():
		if motion.x <= 0:
			for i in range(1, UPWARD_CORNER_CORRECTION + 1):
				var candidate_position = Vector2(-i, -1)
				if not corner_check(candidate_position.x):
					position += candidate_position
					return
		if motion.x >= 0:
			for i in range(1, UPWARD_CORNER_CORRECTION + 1):
				var candidate_position = Vector2(i, -1)
				if not corner_check(candidate_position.x):
					position += candidate_position
					return

		if variable_jump_timer.time_left < variable_jump_timer.wait_time - CEILING_VARIABLE_JUMP:
			variable_jump_timer.stop()

func update_sprite(_input_vector: Vector2, delta: float) -> void:
	# Tween sprite scale back to 1
	sprite.scale.x = move_toward(sprite.scale.x, 1.0, 1.75 * delta)
	sprite.scale.y = move_toward(sprite.scale.y, 1.0, 1.75 * delta)

func can_wall_jump(direction: int) -> bool:
	return test_move(get_transform(), Vector2(WALL_CHECK_DISTANCE * direction, 0))
	
func can_climb_wall(direction: int) -> bool:
	return holding_box == null and test_move(get_transform(), Vector2(CLIMB_CHECK_DISTANCE * direction, 0))

func is_grabbing_wall(direction: int) -> bool:
	return can_climb_wall(direction) and test_move(get_transform().translated(Vector2(0, -collider.shape.extents.y)), Vector2(CLIMB_CHECK_DISTANCE * direction, 0))

func collide_check(x: int = 0, y: int = 0) -> bool:
	return test_move(get_transform(), Vector2(x, y))

func corner_check(x: int) -> bool:
	return test_move(get_transform().translated(Vector2(x, 0)), Vector2.UP)
	
func is_next_to_wall(direction: int, distance: int) -> bool:
	return collide_check(direction * distance, 0)

func update_camera(room):
	var collider = room.get_node("Collider")
	var size = collider.shape.extents * 2
	
	camera.limit_left = collider.global_position.x - size.x / 2
	camera.limit_top = collider.global_position.y - size.y / 2
	camera.limit_right = camera.limit_left + size.x
	camera.limit_bottom = camera.limit_top + size.y

func _on_RoomDetector_area_entered(room: Area2D):
	update_camera(room)

func handle_box():
	# pickup
	if holding_box == null:
		if holding_candidate == null:
			return
		
		holding_box = holding_candidate
		
		holding_box.pickup()
		holding_box.position = Vector2.ZERO
		prev_holder = holding_box.get_parent()
		prev_holder.remove_child(holding_box)
		carry_position.add_child(holding_box)
	else:
	# throw
		carry_position.remove_child(holding_box)
		prev_holder.add_child(holding_box)
		
		if is_next_to_wall(LEFT, 10):
			holding_box.throw(Vector2.RIGHT)
			holding_box.position = throw_position_right.global_position
		elif is_next_to_wall(RIGHT, 10):
			holding_box.throw(Vector2.LEFT)
			holding_box.position = throw_position_left.global_position
		else:
			if facing == LEFT:
				holding_box.throw(Vector2.LEFT)
				holding_box.position = throw_position_left.global_position
			elif facing == RIGHT:
				holding_box.throw(Vector2.RIGHT)
				holding_box.position = throw_position_right.global_position
			
		holding_box = null
		
		motion.x += THROW_RECOIL * (-facing)
		Controls.rumble_gamepad(Controls.RumbleStrength.Light, Controls.RumbleLength.VeryShort)

func _on_PickupArea_area_entered(area):
	var body = area.get_parent()
	if body.is_in_group("carryable"):
		holding_candidate = body


func _on_PickupArea_area_exited(area):
	holding_candidate = null
