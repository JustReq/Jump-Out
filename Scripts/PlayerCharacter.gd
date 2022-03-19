extends KinematicBody2D

const CAMERAZOOMTHRESHOLD = 600
const WADDLESPEED = 120
const WALKSPEED = 320
const WALKACCELERATION = 1000
const RUNSPEED = 720
const RUNACCELERATION = 850
const DECCELERATIONFACTOR = 2

var inputVector
var acceleration
var friction = 2000
var terminalSpeed = 720
var gravity = 1500
var jumpSpeed = 800
var snapLength
var wallGrabTimer = 60
var directionFacing
var wallDirection

var isGrounded
var isJumping
var isCrouching
var isRunning
var isInGrabRange
var isGrabbingWall

var speed
var velocity = Vector2.ZERO

onready var infoLabel = $InfoLabel
onready var camera = $Camera
onready var sprite = $Sprite
onready var animationTree = $AnimationTree.get("parameters/playback")
onready var groundedRayCast = $GroundedRayCast
onready var grabRayCast = $GrabRayCast

func _physics_process(delta):
	miscControls()
	playerStates()
	playerCharacterAnimations()
	cameraController(delta)
	movement_WalkAndRun(delta)
	movement_GravityAndJump(delta)
	movement_WallSlideAndWallJump()

func miscControls():
	if (Input.is_action_pressed("reset")):
		get_tree().reload_current_scene()
	
	infoLabel.text = "speed: {speed}\nacceleration: {acceleration}\ngrounded?: {grounded}\njumping?: {jumping}\ngrabbable?: {grabbable}\ngrabbing wall?: {grabbingWall}".format({
	"speed": Vector2(floor(velocity.x), floor(velocity.y)),
	"acceleration": acceleration,
	"grounded": isGrounded,
	"jumping": isJumping,
	"grabbable": isInGrabRange,
	"grabbingWall": isGrabbingWall
	})

func playerStates():
	if isJumping:
		snapLength = 0
	else:
		snapLength = 32
	
	if isGrabbingWall:
		wallDirection = round(cos(get_angle_to(grabRayCast.get_collision_point())))
	
	isGrounded = groundedRayCast.is_colliding()
	isJumping = Input.is_action_pressed("jump") && velocity.y < 0
	isCrouching = Input.is_action_pressed("crouch")
	isRunning = Input.is_action_pressed("run")
	isInGrabRange = grabRayCast.is_colliding()
	isGrabbingWall = isInGrabRange && !isGrounded && grabRayCast.get_collider() is TileMap
	directionFacing = inputVector

func playerCharacterAnimations():
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	if isGrounded:
		if velocity.x == 0:
			if Input.is_action_pressed("crouch"):
				animationTree.travel("Crouch")
			else:
				animationTree.travel("Idle")
		else:
			if isRunning:
				animationTree.travel("Run")
			else:
				if (inputVector > 0 && velocity.x < 0) || (inputVector < 0 && velocity.x > 0):
					animationTree.travel("Turn_Walk")
				else:
					animationTree.travel("Walk")
		
		if Input.is_action_pressed("jump") && velocity.y < 0:
			animationTree.travel("Jump")
	else:
		if velocity.y > 0:
			animationTree.travel("Fall")

func cameraController(var deltaTime):
	if !isGrabbingWall:
		if abs(velocity.x) > CAMERAZOOMTHRESHOLD:
			camera.zoom = camera.zoom.linear_interpolate(Vector2(1.2, 1.2), 0.007)
		else:
			camera.zoom = camera.zoom.linear_interpolate(Vector2(1, 1), 0.007)

func movement_WalkAndRun(var deltaTime):
	inputVector = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	
	if isRunning:
		speed = RUNSPEED
	elif !isCrouching:
		speed = WALKSPEED
	else:
		speed = WADDLESPEED
	
	if abs(velocity.x) > WALKSPEED:
		acceleration = RUNACCELERATION
	else:
		acceleration = WALKACCELERATION
	
	if (inputVector >= 0 && velocity.x < 0) || (inputVector <= 0 && velocity.x > 0):
		acceleration *= DECCELERATIONFACTOR
	
	if inputVector != 0:
		velocity = velocity.move_toward(Vector2(inputVector * speed, velocity.y), acceleration * deltaTime)
	else:
		velocity = velocity.move_toward(Vector2(0, velocity.y), friction * deltaTime)
	
	velocity.y = move_and_slide_with_snap(velocity, Vector2.DOWN * snapLength, Vector2.UP, true).y

func movement_GravityAndJump(var deltaTime):
	velocity = velocity.move_toward(Vector2(velocity.x, terminalSpeed), gravity * deltaTime)
	
	if Input.is_action_just_pressed("jump") && (isGrounded || isGrabbingWall):
		velocity.y = -jumpSpeed
		
		if isGrabbingWall:
			velocity.x = 30 * inputVector
	
	if Input.is_action_just_released("jump"):
		if velocity.y < -100:
			velocity.y = -200

func movement_WallSlideAndWallJump():
	if isGrounded:
		wallGrabTimer = 60
	
	if isGrabbingWall && !Input.is_action_pressed("jump") && directionFacing == wallDirection:
		velocity.y = 0
		wallGrabTimer -= 1
	
	if (wallGrabTimer <= 0 && isGrabbingWall) || Input.is_action_pressed("crouch"):
		velocity.y = 200
