extends KinematicBody2D

var inputVector

var acceleration = 1200
var speed = 240
var friction = 1200

var terminalSpeed = 720
var gravity = 1500
var jumpSpeed = 750

var velocity = Vector2.ZERO

var isGrounded
var isJumping

onready var playerCharacterSprite = $PlayerCharacterSprite
onready var playerCharacterAnimator = $PlayerCharacterAnimationTree.get("parameters/playback")
onready var playerCharacterAnimationController = $PlayerCharacterAnimator

onready var playerCharacterGroundedRayCast = $PlayerCharacterGroundedRayCast

func _physics_process(delta):
	if (Input.is_action_pressed("reset")):
		get_tree().reload_current_scene()
	
	movement_WalkAndRun(delta)
	movement_GravityAndJump(delta)
	
	playerCharacterAnimations()

func movement_WalkAndRun(var deltaTime):
	inputVector = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	
	if Input.is_action_pressed("run"):
		speed = 480
	else:
		speed = 240
	
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

func playerCharacterAnimations():
	if velocity.x < 0:
		playerCharacterSprite.flip_h = true
	elif velocity.x > 0:
		playerCharacterSprite.flip_h = false
	
	if !isJumping:
		if velocity.x == 0:
			playerCharacterAnimator.travel("Idle")
		else:
			if Input.is_action_pressed("run"):
				playerCharacterAnimator.travel("Run")
			else:
				playerCharacterAnimator.travel("Walk")
		
		if velocity.y > 0 && !isGrounded:
			playerCharacterAnimator.travel("Fall")


	if Input.is_action_just_pressed("jump"):
		playerCharacterAnimator.travel("Jump")
