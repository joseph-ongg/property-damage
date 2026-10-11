extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const JUMPS = 2
var jumps_left = JUMPS

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle drop-down through one-way platforms or jump.
	if is_on_floor():
		jumps_left = JUMPS
	if is_on_floor() and (Input.is_action_just_pressed("ui_down") or (Input.is_action_pressed("ui_down") and Input.is_action_just_pressed("ui_up"))):
		position.y += 2

	elif Input.is_action_just_pressed("ui_up") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
