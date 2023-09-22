extends CharacterBody3D

# Player nodes
@onready var head = $neck/head
@onready var standCollision = $standCollision
@onready var crouchCollision = $crouchCollision
@onready var rayCast3d = $RayCast3D
@onready var neck = $neck
@onready var camera = $neck/head/Camera3D

# Speed variables
var currentSpeed = 5.0
const walkSpeed = 5
const sprintSpeed = 8.0
const crouchSpeed = 2.5

# States
var walk = false
var sprint = false
var crouch = false
var freeLook = false
var slide = false

# Slide variables
var slideTimer = 0.0
var slideTimerMax = 1.0
var slideVector = Vector2.ZERO
var slideSpeed = 15.0

# Movement variables
const jumpVelocity = 10
var lerpSpeed = 10.0
var crouchDepth = -0.5
var freeLookTilt = 10

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
		if freeLook:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouseSens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120),deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouseSens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89),deg_to_rad(89))

func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Handel movement state
	
	# Crouch
	if (Input.is_action_pressed("crouch") && is_on_floor()) || slide:
		
		currentSpeed = crouchSpeed
				
		head.position.y = lerp(head.position.y, crouchDepth , delta*lerpSpeed)
		
		standCollision.disabled  = true
		crouchCollision.disabled  = false
		
		# Slide begin logic		
		if sprint && input_dir != Vector2.ZERO && is_on_floor():
			slide = true
			slideTimer = slideTimerMax
			slideVector = input_dir
			print("slide start")
		
		walk = false
		sprint = false
		crouch = true
		
	elif !rayCast3d.is_colliding():
		
		# Stand
		head.position.y = lerp(head.position.y, 0.0 , delta*lerpSpeed)
		
		standCollision.disabled  = false
		crouchCollision.disabled  = true
		
		walk = false
		sprint = false
		crouch = false
		
		if Input.is_action_pressed("sprint"):
			# Sprint
			currentSpeed = sprintSpeed
			
			walk = false
			sprint = true
			crouch = false
		else:
			# Walk
			currentSpeed = walkSpeed
			
			walk = true
			sprint = false
			crouch = false
	
	# Handle slide end
	if slide:
		slideTimer -= delta
		if slideTimer <= 0:
			slide = false
			print("slide end")
	
	# Handle free look
	if Input.is_action_pressed("freeLook"):
		freeLook = true
		camera.rotation.z = -deg_to_rad(neck.rotation.y * freeLookTilt)
	else:
		freeLook = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*20)
		camera.rotation.z = lerp(camera.rotation.z,0.0,delta*20)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		crouch = false
		slide = false
		velocity.y = jumpVelocity

	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerpSpeed)
	if slide:
		direction = transform.basis * Vector3(slideVector.x , 0 , slideVector.y)
		
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
		
		if slide:
			velocity.x = direction.x * slideTimer * (slideSpeed + walkSpeed)
			velocity.z = direction.z * slideTimer * (slideSpeed + walkSpeed)
		
		if Input.is_action_pressed("right"):
			neck.rotation.z = lerp(neck.rotation.z, -deg_to_rad(3.0) , delta*lerpSpeed)
		elif Input.is_action_pressed("left"):
			neck.rotation.z = lerp(neck.rotation.z, deg_to_rad(3.0) , delta*lerpSpeed)
		else:
			neck.rotation.z = lerp(neck.rotation.z, 0.0 , delta*lerpSpeed)
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()
