extends CharacterBody3D

@export var PlayerNo = 0

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var jump_impulse := 12.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0

@export_group("Camera")
@export var _camera_pivot: Node3D
@export var _camera: Camera3D 
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

var ground_height := 0.0

var _gravity := -30.0
var _was_on_floor_last_frame := true
var _camera_input_direction := Vector2.ZERO

@onready var _last_input_direction := global_basis.z
@onready var _start_position := global_position

@export var _skin: SophiaSkin
@onready var _landing_sound: AudioStreamPlayer3D = %LandingSound
@onready var _jump_sound: AudioStreamPlayer3D = %JumpSound
@onready var _dust_particles: GPUParticles3D = %DustParticles



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("action" + str(PlayerNo)):
		pass

func _unhandled_input(event: InputEvent) -> void:
	var player_is_using_mouse := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if player_is_using_mouse:
		_camera_input_direction.x = event.relative.x * mouse_sensitivity
		_camera_input_direction.y = event.relative.y * mouse_sensitivity

func _physics_process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotation.x += _camera_input_direction.y * delta
		_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
		_camera_pivot.rotation.y += _camera_input_direction.x * delta

		_camera_input_direction = Vector2.ZERO
	else:
	# Gamepad/Keyboard Camera Input
		var raw_camera_input := Input.get_vector(
			"camera_left" + str(PlayerNo), "camera_right" + str(PlayerNo),
			"camera_up" + str(PlayerNo), "camera_down" + str(PlayerNo),
			0.4
		)
		_camera_pivot.rotation.x += raw_camera_input.y * delta
		_camera_pivot.rotation.y += -raw_camera_input.x * delta
		raw_camera_input=Vector2.ZERO

	# Movement input
	var raw_input := Input.get_vector(
		"move_left" + str(PlayerNo), "move_right" + str(PlayerNo),
		"move_up" + str(PlayerNo), "move_down" + str(PlayerNo),
		0.4
	)
	var forward := _camera_pivot.global_basis.z
	var right := _camera_pivot.global_basis.x
	var move_direction := forward * -raw_input.y + right * -raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	# Smooth rotation towards movement direction
	if move_direction.length() > 0.2:
		_last_input_direction = move_direction.normalized()
	var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

	# Apply movement and physics
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	if is_equal_approx(move_direction.length_squared(), 0.0) and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO
	velocity.y = y_velocity + _gravity * delta

	# Jump and animation handling
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var is_just_jumping := Input.is_action_just_pressed("jump" + str(PlayerNo)) and is_on_floor()
	if is_just_jumping:
		velocity.y += jump_impulse
		_skin.jump()
		_jump_sound.play()
	elif not is_on_floor() and velocity.y < 0:
		_skin.fall()
	elif is_on_floor():
		if ground_speed > 0.0:
			_skin.move()
		else:
			_skin.idle()

	_dust_particles.emitting = is_on_floor() and ground_speed > 0.0

	if is_on_floor() and not _was_on_floor_last_frame:
		_landing_sound.play()

	_was_on_floor_last_frame = is_on_floor()
	move_and_slide()
