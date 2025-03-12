extends CharacterBody3D
@onready var camera_mount: Node3D = $cameraMount
@onready var animation_player: AnimationPlayer = $character/hero/AnimationPlayer

# Speed variables
var currentSpeed = 3.0
const walkSpeed = 5.0
const sprintSpeed = 10.0
const crouchSpeed = 2.5


const JUMP_VELOCITY = 8
@export var sens = .2

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_player.play("run")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-deg_to_rad(event.relative.x)*sens)
		camera_mount.rotate_x(-deg_to_rad(event.relative.y)*sens)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
