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
const walkSpeed = 5.0
const sprintSpeed = 10.0
const crouchSpeed = 2.5
var speedReader = 0.0

# States
var walk = false
var sprint = false
var crouch = false
var freeLook = false
var slide = false

# Slide variables
var slideTimer = 0.0
const slideTimerMax = 1.0
var slideVector = Vector2.ZERO
const slideSpeed = 8.0

# Headbobbing variables
var headBobSprintSpeed = 30.0
var headBobWalkSpeed = 15.0
var headBobCrouchSpeed = 10.0

var headBobSprintIntensity = 0.2 #m
var headBobWalkIntensity = 0.1 #m
var headBobCrouchIntensity = 0.05 #m

var headBobVector = Vector2.ZERO
var headBobIndex = 0.0
var headBobCurrentIntensity = 0.0

# Movement variables
const jumpVelocity = 8
var crouchDepth = -0.5
var freeLookTilt = 10
var lerpSpeed = 10.0
var airLerpSpeed = lerpSpeed/2

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
		
		currentSpeed = lerp(currentSpeed, crouchSpeed, delta * 5.0)
				
		neck.position.y = lerp(neck.position.y, 1.7+crouchDepth , delta*lerpSpeed)
		
		standCollision.disabled  = true
		crouchCollision.disabled  = false
		
		# Slide begin logic		
		if sprint && input_dir != Vector2.ZERO && is_on_floor():
			slide = true
			slideTimer = slideTimerMax
			slideVector = input_dir
		
		# Slide tilt
		if slide:
			neck.rotation.z = lerp(neck.rotation.z, -deg_to_rad(10.0) , delta*lerpSpeed)
		
		walk = false
		sprint = false
		crouch = true
		
	elif !rayCast3d.is_colliding():
		
		# Stand
		neck.position.y = lerp(neck.position.y, 1.7 , delta*lerpSpeed)
		
		standCollision.disabled  = false
		crouchCollision.disabled  = true
		
		walk = false
		sprint = false
		crouch = false
		
		if Input.is_action_pressed("sprint"):
			# Sprint
			currentSpeed = lerp(currentSpeed, sprintSpeed, delta * 5.0)
			
			walk = false
			sprint = true
			crouch = false
		elif is_on_floor():
			# Walk
			currentSpeed = lerp(currentSpeed, walkSpeed, delta * 5.0)
			
			walk = true
			sprint = false
			crouch = false
	
			
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		crouch = false
		slide = false
		velocity.y = jumpVelocity

	# Handle slide end
	if slide:
		slideTimer -= delta
		if slideTimer <= 0:
			slide = false
		
	# Handel head bob
	if sprint:
		headBobCurrentIntensity = headBobSprintIntensity
		headBobIndex += headBobSprintSpeed * delta
	elif walk:
		headBobCurrentIntensity = headBobWalkIntensity
		headBobIndex += headBobWalkSpeed * delta
	elif crouch:
		headBobCurrentIntensity = headBobCrouchIntensity
		headBobIndex += headBobCrouchSpeed * delta
	
	if is_on_floor() && !slide && input_dir != Vector2.ZERO:
		headBobVector.y = sin(headBobIndex)
		headBobVector.x = sin(headBobIndex/2)+0.5
		
		head.position.y = lerp(head.position.y, headBobVector.y * (headBobCurrentIntensity/2), delta*lerpSpeed)
		head.position.x = lerp(head.position.x, headBobVector.x * (headBobCurrentIntensity), delta*lerpSpeed)
	else:
		head.position.y = lerp(head.position.y, 0.0, delta*lerpSpeed)
		head.position.x = lerp(head.position.x, 0.0, delta*lerpSpeed)
	
	# Handle free look
	if Input.is_action_pressed("freeLook"):
		freeLook = true
		head.rotation.z = -deg_to_rad(neck.rotation.y * freeLookTilt)
	else:
		freeLook = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*20)
		head.rotation.z = lerp(head.rotation.z,0.0,delta*20)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerpSpeed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*airLerpSpeed)
	
	if slide:
		direction = transform.basis * Vector3(slideVector.x , 0 , slideVector.y)
		currentSpeed = (slideTimer * slideSpeed + sprintSpeed)
		
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	
		if Input.is_action_pressed("right"):
			neck.rotation.z = lerp(neck.rotation.z, -deg_to_rad(3.0) , delta*lerpSpeed)
		elif Input.is_action_pressed("left"):
			neck.rotation.z = lerp(neck.rotation.z, deg_to_rad(3.0) , delta*lerpSpeed)
		else:
			neck.rotation.z = lerp(neck.rotation.z, 0.0 , delta*lerpSpeed)
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)
	
	speedReader = Vector3(velocity.x,velocity.y,velocity.z).length()
	# print (speedReader)
	
	move_and_slide()
