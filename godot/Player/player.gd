extends CharacterBody3D

# Player Config
@export var PlayerNo := 0

# Movement Settings
@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var jump_impulse := 12.0
@export var rotation_speed := 12.0
@export var stopping_speed := 1.0
@export var max_jumps:=2

# Camera Settings
@export_group("Camera")
@export var _camera_pivot: Node3D
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

# Scene References
@export var _skin: SophiaSkin
@onready var _landing_sound: AudioStreamPlayer3D = %LandingSound
@onready var _jump_sound: AudioStreamPlayer3D = %JumpSound
@onready var _dust_particles: GPUParticles3D = %DustParticles

# Constants
const MOVEMENT_DEADZONE := 0.2
const CAMERA_DEADZONE := 0.4
const GRAVITY := -30.0

# Internal State
var _camera_input_direction := Vector2.ZERO
var _was_on_floor_last_frame := true
var _last_input_direction := Vector3.FORWARD
var _current_jump=max_jumps


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	var using_mouse := event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if using_mouse:
		_camera_input_direction.x = event.relative.x * mouse_sensitivity
		_camera_input_direction.y = event.relative.y * mouse_sensitivity

func _physics_process(delta: float) -> void:
	update_camera(delta)

	var move_direction := get_movement_input()
	update_rotation(move_direction, delta)
	update_velocity(move_direction, delta)

	handle_jumping()
	handle_animation()
	handle_particles_and_sounds()

	move_and_slide()
	_was_on_floor_last_frame = is_on_floor()

func update_camera(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotation.x = clamp(
			_camera_pivot.rotation.x + _camera_input_direction.y * delta,
			tilt_lower_limit,
			tilt_upper_limit
		)
		_camera_pivot.rotation.y -= _camera_input_direction.x * delta
		_camera_input_direction = Vector2.ZERO
	else:
		var raw_input := Input.get_vector(
			"camera_left" + str(PlayerNo), "camera_right" + str(PlayerNo),
			"camera_up" + str(PlayerNo), "camera_down" + str(PlayerNo),
			CAMERA_DEADZONE
		)
		_camera_pivot.rotation.x = clamp(
			_camera_pivot.rotation.x + raw_input.y * delta,
			tilt_lower_limit,
			tilt_upper_limit
		)
		_camera_pivot.rotation.y -= raw_input.x * delta

func get_movement_input() -> Vector3:
	var input_vec := Input.get_vector(
		"move_left" + str(PlayerNo), "move_right" + str(PlayerNo),
		"move_up" + str(PlayerNo), "move_down" + str(PlayerNo),
		MOVEMENT_DEADZONE
	)
	var forward := _camera_pivot.global_basis.z
	var right := _camera_pivot.global_basis.x
	var direction := (-input_vec.y * forward + -input_vec.x * right).normalized()
	direction.y = 0.0
	return direction

func update_rotation(move_direction: Vector3, delta: float) -> void:
	if move_direction.length() > MOVEMENT_DEADZONE:
		_last_input_direction = move_direction.normalized()

	var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
	_skin.global_rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

func update_velocity(move_direction: Vector3, delta: float) -> void:
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)

	if move_direction.length_squared() == 0.0 and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO

	velocity.y = y_velocity + GRAVITY * delta

func handle_jumping() -> void:
	var jump_action := "jump" + str(PlayerNo)
	if Input.is_action_just_pressed(jump_action) and _current_jump>0:
		velocity.y = jump_impulse
		_current_jump-=1
		_skin.jump()
		_jump_sound.play()
	elif not is_on_floor() and velocity.y < 0:
		_skin.fall()
	elif is_on_floor():
		_current_jump=max_jumps

func handle_animation() -> void:
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		if ground_speed > 0.0:
			_skin.move()
		else:
			_skin.idle()

func handle_particles_and_sounds() -> void:
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	_dust_particles.emitting = is_on_floor() and ground_speed > 0.0

	if is_on_floor() and not _was_on_floor_last_frame:
		_landing_sound.play()
