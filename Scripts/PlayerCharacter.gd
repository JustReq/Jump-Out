extends KinematicBody2D

var inputVector

const WALKSPEED = 320
const WALKACCELERATION = 1000
const RUNSPEED = 720
const RUNACCELERATION = 850

const DECCELERATIONFACTOR = 2

var speed
var acceleration
var friction = 2000

var terminalSpeed = 720
var gravity = 1500
var jumpSpeed = 800

var velocity = Vector2.ZERO

var isGrounded
var isJumping

const CAMERAZOOMTHRESHOLD = 600

onready var playerCharacterInfoLabel = $PlayerCharacterInfoLabel
onready var playerCharacterCamera = $PlayerCharacterCamera
onready var playerCharacterSprite = $PlayerCharacterSprite
onready var playerCharacterCollider = $PlayerCharacterCollider
onready var playerCharacterAnimator = $PlayerCharacterAnimationTree.get("parameters/playback")
onready var playerCharacterAnimationController = $PlayerCharacterAnimator
onready var playerCharacterGroundedRayCast = $PlayerCharacterGroundedRayCast

func _physics_process(delta):
	if (Input.is_action_pressed("reset")):
		get_tree().reload_current_scene()
	
	playerCharacterInfoLabel.text = "speed: {speed}\ngrounded?: {grounded}\nacceleration: {acceleration}".format({
		"speed":Vector2(floor(velocity.x), floor(velocity.y)),
		"grounded":isGrounded,
		"acceleration": acceleration
		})
	
	movement_WalkAndRun(delta)
	movement_GravityAndJump(delta)
	
	cameraController(delta)
	playerCharacterAnimations()

func movement_WalkAndRun(var deltaTime):
	inputVector = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	
	if Input.is_action_pressed("run"):
		speed = RUNSPEED
	else:
		speed = WALKSPEED
	
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
	
	velocity = move_and_slide(velocity)

func movement_GravityAndJump(var deltaTime):
	isGrounded = playerCharacterGroundedRayCast.is_colliding()
	isJumping = Input.is_action_pressed("jump") && velocity.y < 0
	
	velocity = velocity.move_toward(Vector2(velocity.x, terminalSpeed), gravity * deltaTime)
	
	if Input.is_action_just_pressed("jump") && isGrounded:
		velocity.y = -jumpSpeed
	if Input.is_action_just_released("jump"):
		if velocity.y < -100:
			velocity.y = -200

func cameraController(var deltaTime):
	if (abs(velocity.x) > CAMERAZOOMTHRESHOLD):
		playerCharacterCamera.zoom = playerCharacterCamera.zoom.move_toward(Vector2(1.6, 1.6), (abs(velocity.x) - CAMERAZOOMTHRESHOLD) / (RUNSPEED - CAMERAZOOMTHRESHOLD) * deltaTime / 10)
	else:
		playerCharacterCamera.zoom = playerCharacterCamera.zoom.move_toward(Vector2(0.8, 0.8), -(abs(velocity.x) - CAMERAZOOMTHRESHOLD) / (RUNSPEED - CAMERAZOOMTHRESHOLD) * deltaTime / 10)

func playerCharacterAnimations():
	if velocity.x < 0:
		playerCharacterSprite.flip_h = true
	elif velocity.x > 0:
		playerCharacterSprite.flip_h = false
	
	if isGrounded:
		if velocity.x == 0:
			if Input.is_action_pressed("crouch"):
				playerCharacterAnimator.travel("Crouch")
			else:
				playerCharacterAnimator.travel("Idle")
		else:
			if Input.is_action_pressed("run"):
				playerCharacterAnimator.travel("Run")
			else:
				if (inputVector > 0 && velocity.x < 0) || (inputVector < 0 && velocity.x > 0):
					playerCharacterAnimator.travel("Turn_Walk")
				else:
					playerCharacterAnimator.travel("Walk")
		
		if Input.is_action_pressed("jump") && velocity.y < 0:
			playerCharacterAnimator.travel("Jump")
	else:
		if velocity.y > 0:
			playerCharacterAnimator.travel("Fall")
