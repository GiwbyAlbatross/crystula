extends CharacterBody2D

# settings
@export var SPEED := 500.0
@export var JUMP_VELOCITY := -2000.0
@export var JUMP_LENGTH := 1.0 # seconds
@export var GRAVITY := 9800.0
@export var maxhp: float = 5.0
@export var preserved_animations := PackedStringArray([])

# onreadies
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var flipper: Node2D = $flipper # just flips other nodes using scale.x

var hp: float = 5.0
var flags: Dictionary[StringName, float] = {
	#
} # to avoid having a million goddamn booleans
var cooldowns: Dictionary[StringName, float] = { # see _tick_cooldowns
	&'no_input':0.0 # bloody *&^%ing no_input time that pmo so much but is kinda important (DON'T OVERDO IT)
} # to avoid having a million goddamn floats for evey cooldown

# important movement stuff
var direction := 0.0
var facing := -1 # negative is left, positive is right, should never be zero

func _ready() -> void:
	anim.animation_looped.connect(_pick_next_anim)
	anim.animation_finished.connect(_pick_next_anim)

func _pick_next_anim():
	var last: StringName = anim.animation
	if !direction:
		setanim(&'idle')
	else:
		setanim(&'walk')
	print("setting next animation, last: '", last, "', new: '", anim.animation, "'")

func setanim(a: StringName) -> void:
	# preserves certain important animations
	if !(preserved_animations.has(anim.animation)) and anim.is_playing():
		anim.play(a)

func _move(delta: float) -> void:
	# DO MOVEMENT
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if cooldowns[&'no_input'] > 0.0:
		# we are in no-input time
		return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		facing = direction
		setanim(&'walk')
		velocity.x = direction * SPEED
	else:
		if Input.is_action_just_released("move"):
			setanim(&'idle')
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Handle jump after movement so the animations don't overwrite each other
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim.play(&"jump_raw")

func _tick_cooldowns(delta: float) -> void:
	# very simple timer logic that doesn't use the timer node, to set a cooldown, set cooldowns[&'your_cooldown_name'] to however long that cooldown is and when it's over it will be <= 0.0
	for key in cooldowns:
		cooldowns[key] -= delta

func _physics_process(delta: float) -> void: # runs exactly 60 times a second, regardless of fps
	_move(delta)
	
	flipper.scale.x = -facing
	
	move_and_slide()

func _process(delta: float) -> void: # runs every frame, affected by FPS
	# TODO: VFX and stuff here
	anim.flip_h = facing > 0
