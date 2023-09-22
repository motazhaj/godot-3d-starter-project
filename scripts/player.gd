extends CharacterBody3D

# Player nodes
@onready var head = $head
@onready var standCollision = $standCollision
@onready var crouchCollision = $crouchCollision
@onready var rayCast3d = $RayCast3D

# Speed variables
var currentSpeed = 5.0
const walkingSpeed = 5
const sprintingSpeed = 8.0
const crouchSpeed = 2.5

# Movement variables
const jumpVelocity = 4.5
var lerpSpeed = 10.0
var crouchDepth = -0.5

# Input variables
var direction = Vector3.ZERO
@export var mouseSens = 0.2


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Mouse look logic
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouseSens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89),deg_to_rad(89))

func _physics_process(delta):
	
	# Handel movement state
	
	# Crouch
	if Input.is_action_pressed("crouch"):
		currentSpeed = crouchSpeed
		head.position.y = lerp(head.position.y, 1.7 + crouchDepth , delta*lerpSpeed)
		
		standCollision.disabled  = true
		crouchCollision.disabled  = false
		
	elif !rayCast3d.is_colliding():
		
		# Stand
		head.position.y = lerp(head.position.y, 1.7 , delta*lerpSpeed)
		
		standCollision.disabled  = false
		crouchCollision.disabled  = true
		
		if Input.is_action_pressed("sprint"):
			# Sprint
			currentSpeed = sprintingSpeed
		else:
			# Walk
			currentSpeed = walkingSpeed
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jumpVelocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerpSpeed)
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
